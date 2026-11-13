<#
.SYNOPSIS
    Kopiert ein Referenzverzeichnis Count-mal in ein Zielverzeichnis und
    startet in jeder Kopie Claude Code in einem eigenen Konsolenfenster.

.DESCRIPTION
    1. Prüft, ob die Referenz readme.md und requirement.md enthält und ob
       neben dem Skript eine prompt.md liegt.
    2. Legt im Zielverzeichnis Test-001 bis Test-<Count> an (immer dreistellig)
       und kopiert in jede Kopie die prompt.md, die neben dem Skript liegt.
       Eine prompt.md aus der Referenz wird dabei überschrieben.
    3. Ersetzt in der prompt.md jeder Kopie den NUMBER-Platzhalter (siehe
       $Placeholder unten) durch die dreistellige Nummer, falls er vorkommt.
    4. Macht jede Kopie zum Git-Repo auf Branch master mit einem Commit des
       Ausgangsstands und hängt ein lokales bare Repo unter
       <Target>\_origin\Test-<Nummer>.git als origin an. Arbeitsdateien des
       Laufs (lauf-protokoll.md, plan.md, review-notizen.md, pr-*.md) stehen
       in .git/info/exclude.
    5. Öffnet pro Kopie ein neues Konsolenfenster mit der Kopie als
       Arbeitsverzeichnis und startet darin claude mit dem angegebenen Modell
       und dem initialen Prompt (Standard: Verweis auf prompt.md).
       Jedes Fenster erbt CLAUDE_CODE_DISABLE_AUTO_MEMORY=1, damit Auto Memory
       auch ohne settings.local.json aus ist.

    Hinweis: Der Platzhalter darf in diesem Kommentarblock nicht wörtlich
    stehen, weil seine Endung den Block vorzeitig schließen würde.

.PARAMETER Reference
    Name des Referenzverzeichnisses, z. B. Benchmark-001. Es muss im selben
    Verzeichnis liegen wie dieses Skript. Pfadangaben sind nicht erlaubt.

.PARAMETER Target
    Pfad zum Zielverzeichnis. Wird angelegt, falls es nicht existiert.

.PARAMETER Count
    Anzahl der Kopien (1 bis 999).

.PARAMETER Model
    Modell für claude --model. Standard: claude-opus-5-5.

.PARAMETER InitialPrompt
    Erste Nachricht an claude. Standard: Führe prompt.md 1:1 aus!
    Leerer String ("") startet claude ohne initialen Prompt.
    Doppelte Anführungszeichen sind nicht erlaubt, weil der Text über
    mehrere Kommandozeilen-Ebenen weitergereicht wird.

.PARAMETER Force
    Löscht vorhandene Test-<Nummer>-Verzeichnisse und ihre origin-Repos im
    Ziel und legt sie neu an.

.PARAMETER NoLaunch
    Nur kopieren, keine Konsolenfenster öffnen.

.EXAMPLE
    .\bench-setup.ps1 -Reference Benchmark-001 -Target C:\Develop\Bench -Count 5

.EXAMPLE
    .\bench-setup.ps1 Benchmark-001 C:\Develop\Bench 5 -Force
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if ($_ -match '[\\/:]' -or $_ -eq '.' -or $_ -eq '..') {
            throw "Nur den Namen des Benchmark-Verzeichnisses angeben (z. B. Benchmark-001), keinen Pfad: $_"
        }
        $true
    })]
    [string]$Reference,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$Target,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateRange(1, 999)]
    [int]$Count,

    [ValidateNotNullOrEmpty()]
    [string]$Model = 'claude-opus-5-5',

    [ValidateScript({ -not $_.Contains('"') })]
    [string]$InitialPrompt = 'Führe prompt.md 1:1 aus!',

    [switch]$Force,

    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'

$RequiredFiles            = @('readme.md', 'requirement.md')
$PromptFileName           = 'prompt.md'
$SourcePromptPath         = Join-Path $PSScriptRoot $PromptFileName   # gemeinsame prompt.md neben dem Skript
$Placeholder              = '<#-NUMBER-#>'
$CopyPrefix               = 'Test-'
$NumberFormat             = 'D3'
$MemoryEnvVarName         = 'CLAUDE_CODE_DISABLE_AUTO_MEMORY'
$MemoryEnvVarValue        = '1'
$RobocopyFailureThreshold = 8   # robocopy: Exit-Codes ab 8 bedeuten Fehler
$StartBranch              = 'master'   # muss zu STARTBRANCH in prompt.md passen
$OriginFolderName         = '_origin'  # lokale bare Repos als origin, im Zielverzeichnis
$GitAuthorName            = 'bench-setup'
$GitAuthorEmail           = 'bench-setup@localhost'
$InitialCommitMessage     = 'chore: Benchmark-Ausgangsstand'
# Arbeitsdateien des Laufs; nicht committet und nicht im git status.
$RunFilePatterns          = @('lauf-protokoll.md', 'plan.md', 'review-notizen.md', 'pr-*.md', '.worktrees/')

# Benchmark-Verzeichnisse liegen neben diesem Skript.
$ReferencePath = Join-Path $PSScriptRoot $Reference
$TargetPath    = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target).TrimEnd('\', '/')

function Assert-ReferenceValid {
    if (-not (Test-Path $ReferencePath -PathType Container)) {
        throw "Referenzverzeichnis nicht gefunden: $ReferencePath"
    }
    $missing = @($RequiredFiles | Where-Object { -not (Test-Path (Join-Path $ReferencePath $_) -PathType Leaf) })
    if ($missing.Count -gt 0) {
        throw "In der Referenz fehlen: $($missing -join ', ')  ($ReferencePath)"
    }
    if (-not (Test-Path $SourcePromptPath -PathType Leaf)) {
        throw "Neben dem Skript fehlt die $PromptFileName`: $SourcePromptPath"
    }
}

function Assert-PathsSeparate {
    # Ziel innerhalb der Referenz würde sich beim Kopieren selbst mitkopieren.
    $ref = $ReferencePath + [IO.Path]::DirectorySeparatorChar
    $tgt = $TargetPath + [IO.Path]::DirectorySeparatorChar
    if ($tgt.StartsWith($ref, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Das Ziel liegt innerhalb der Referenz: $TargetPath"
    }
}

function Test-ReferencePlaceholder {
    # Nur lesend: weist darauf hin, wenn alle Kopien denselben Prompt bekommen.
    if (-not ([IO.File]::ReadAllText($SourcePromptPath)).Contains($Placeholder)) {
        Write-Host "[bench-setup] Hinweis: $PromptFileName enthält keinen Platzhalter $Placeholder, alle Kopien bekommen denselben Prompt." -ForegroundColor DarkYellow
    }
}

function Get-BenchTargets {
    foreach ($n in 1..$Count) {
        $numberText = $n.ToString($NumberFormat)
        [pscustomobject]@{
            Name       = "$CopyPrefix$numberText"
            NumberText = $numberText
            Path       = Join-Path $TargetPath "$CopyPrefix$numberText"
            OriginPath = Join-Path (Join-Path $TargetPath $OriginFolderName) "$CopyPrefix$numberText.git"
        }
    }
}

function Clear-ExistingTargets {
    param([object[]]$Targets)
    # Seiteneffekt: löscht vorhandene Kopien, aber nur mit -Force.
    $existing = @($Targets | Where-Object { (Test-Path $_.Path) -or (Test-Path $_.OriginPath) })
    if ($existing.Count -eq 0) { return }
    if (-not $Force) {
        throw "Diese Kopien existieren bereits: $(($existing | ForEach-Object Name) -join ', '). Mit -Force werden sie gelöscht und neu angelegt."
    }
    foreach ($item in $existing) {
        foreach ($path in @($item.Path, $item.OriginPath)) {
            if (Test-Path $path) {
                Remove-Item $path -Recurse -Force
                Write-Host "[bench-setup] gelöscht: $path" -ForegroundColor DarkYellow
            }
        }
    }
}

function Copy-Reference {
    param([string]$DestinationPath)
    # robocopy kopiert zuverlässig auch versteckte Ordner wie .git und .claude.
    robocopy $ReferencePath $DestinationPath /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge $RobocopyFailureThreshold) {
        throw "robocopy ist mit Exit-Code $LASTEXITCODE fehlgeschlagen: $ReferencePath -> $DestinationPath"
    }
}

function Copy-Prompt {
    param([string]$DestinationPath)
    # Seiteneffekt: überschreibt eine prompt.md aus der Referenz.
    Copy-Item -LiteralPath $SourcePromptPath -Destination (Join-Path $DestinationPath $PromptFileName) -Force
}

function Set-PromptNumber {
    param([string]$DestinationPath, [string]$NumberText)
    # Seiteneffekt: schreibt die prompt.md der Kopie neu (UTF-8 ohne BOM).
    $promptPath = Join-Path $DestinationPath $PromptFileName
    $content = [IO.File]::ReadAllText($promptPath)
    $count = ([regex]::Matches($content, [regex]::Escape($Placeholder))).Count
    if ($count -gt 0) {
        $updated = $content.Replace($Placeholder, $NumberText)
        [IO.File]::WriteAllText($promptPath, $updated, (New-Object System.Text.UTF8Encoding($false)))
    }
    return $count
}

function Invoke-Git {
    param([string]$WorkingDirectory, [string[]]$Arguments)
    $output = & git -C $WorkingDirectory @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') ist fehlgeschlagen ($WorkingDirectory):`n$($output -join "`n")"
    }
    return $output
}

function Initialize-BenchRepository {
    param([object]$Item)
    # Seiteneffekt: legt ein Git-Repo in der Kopie und ein lokales bare Repo als
    # origin an. Ein vorhandenes origin wird auf das lokale umgebogen, damit
    # kein Lauf etwas nach außen pusht.
    $path = $Item.Path
    if (-not (Test-Path (Join-Path $path '.git'))) {
        Invoke-Git $path @('init', '--quiet', '--initial-branch', $StartBranch) | Out-Null
    }
    $excludePath = Join-Path $path '.git\info\exclude'
    New-Item -ItemType Directory -Path (Split-Path $excludePath) -Force | Out-Null
    Add-Content -LiteralPath $excludePath -Value (@('', '# bench-setup: Arbeitsdateien des Laufs') + $RunFilePatterns)

    Invoke-Git $path @('add', '--all') | Out-Null
    $pending = Invoke-Git $path @('status', '--porcelain')
    if ($pending) {
        Invoke-Git $path @('-c', "user.name=$GitAuthorName", '-c', "user.email=$GitAuthorEmail",
            'commit', '--quiet', '-m', $InitialCommitMessage) | Out-Null
    }
    $branch = (Invoke-Git $path @('branch', '--show-current')) -join ''
    if ($branch -ne $StartBranch) {
        throw "In $path ist '$branch' ausgecheckt, erwartet wird '$StartBranch'."
    }

    New-Item -ItemType Directory -Path $Item.OriginPath -Force | Out-Null
    Invoke-Git $Item.OriginPath @('init', '--quiet', '--bare', '--initial-branch', $StartBranch) | Out-Null
    $remotes = @(Invoke-Git $path @('remote'))
    if ($remotes -contains 'origin') {
        Invoke-Git $path @('remote', 'set-url', 'origin', $Item.OriginPath) | Out-Null
    }
    else {
        Invoke-Git $path @('remote', 'add', 'origin', $Item.OriginPath) | Out-Null
    }
    Invoke-Git $path @('push', '--quiet', '--set-upstream', 'origin', $StartBranch) | Out-Null
}

function Get-ShellExecutable {
    # PowerShell 7 bevorzugt, sonst Windows PowerShell.
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { return 'pwsh' }
    return 'powershell'
}

function Start-ClaudeWindow {
    param([object]$Item, [string]$Shell)
    # Seiteneffekt: öffnet ein neues Konsolenfenster. Es erbt die Umgebungs-
    # variablen dieses Prozesses, also auch die Memory-Sperre.
    $command = "`$Host.UI.RawUI.WindowTitle = '$($Item.Name)'; claude --model $Model"
    if ($InitialPrompt) {
        # In einfachen Anführungszeichen; ein enthaltenes ' wird verdoppelt.
        $command += " '" + $InitialPrompt.Replace("'", "''") + "'"
    }
    Start-Process -FilePath $Shell -WorkingDirectory $Item.Path `
        -ArgumentList '-NoExit', '-NoProfile', '-Command', "`"$command`""
    Write-Host "[bench-setup] Fenster gestartet: $($Item.Name)" -ForegroundColor Cyan
}

Assert-ReferenceValid
Assert-PathsSeparate
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Der Befehl 'git' wurde nicht gefunden."
}
Test-ReferencePlaceholder

if (-not (Test-Path $TargetPath)) {
    New-Item -ItemType Directory -Path $TargetPath | Out-Null
}

$items = @(Get-BenchTargets)
Clear-ExistingTargets -Targets $items

foreach ($item in $items) {
    Copy-Reference -DestinationPath $item.Path
    Copy-Prompt -DestinationPath $item.Path
    $replaced = Set-PromptNumber -DestinationPath $item.Path -NumberText $item.NumberText
    Initialize-BenchRepository -Item $item
    Write-Host "[bench-setup] kopiert: $($item.Path)  ($replaced x Platzhalter -> $($item.NumberText), origin: $($item.OriginPath))" -ForegroundColor Cyan
}

Write-Host "[bench-setup] $($items.Count) Kopien von $ReferencePath in $TargetPath angelegt." -ForegroundColor Green

if ($NoLaunch) { return }

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "Der Befehl 'claude' wurde nicht gefunden. Kopien sind angelegt, es wurden keine Fenster geöffnet."
}

$shell = Get-ShellExecutable
$previousValue = [Environment]::GetEnvironmentVariable($MemoryEnvVarName, 'Process')
try {
    [Environment]::SetEnvironmentVariable($MemoryEnvVarName, $MemoryEnvVarValue, 'Process')
    foreach ($item in $items) {
        Start-ClaudeWindow -Item $item -Shell $shell
    }
}
finally {
    # Die geöffneten Fenster behalten die Variable; nur diese Konsole wird zurückgesetzt.
    [Environment]::SetEnvironmentVariable($MemoryEnvVarName, $previousValue, 'Process')
}