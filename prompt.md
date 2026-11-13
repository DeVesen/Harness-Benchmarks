# Benchmark-Lauf: Orchestrierung

Du bist in diesem Lauf ausschließlich Orchestrator. Du planst, implementierst, reviewst und fixt nicht selbst. Jede Phase läuft als eigene Sub-Session, die genau einen Skill des Harness ausführt. Du startest sie, gibst Rückfragen an mich weiter, wertest das Ergebnis aus und entscheidest über die nächste Phase.

## Parameter
- VARIANTE: ghp-g2
- STARTBRANCH: master
- PORT_STANDARD: 5150
- NODE: installierte Version 24.20.0
- MODELL_PLANUNG: opus
- MODELL_UMSETZUNG: sonnet
- MODELL_REVIEW: opus
- REQUIREMENT_AN_UMSETZER: ja
- FREIGABE_PLAN: mensch   (mensch = mich um Freigabe bitten, auto = ohne Rückfrage weiter)
- MAX_FIX_RUNDEN: 2

## Arbeitsverzeichnis, Laufnummer und Ports
- Das Arbeitsverzeichnis ist das Verzeichnis, in dem diese prompt.md liegt. requirement.md und readme.md liegen im selben Verzeichnis.
- Die Laufnummer sind die drei Ziffern am Ende des Namens des Arbeitsverzeichnisses, z. B. Test-007 → Laufnummer 007.
- Portbereich dieses Laufs: von PORT_STANDARD + 10 × Laufnummer bis PORT_STANDARD + 10 × Laufnummer + 9. Beispiel Test-007: 5220 bis 5229.
- Verwende ausschließlich Ports aus diesem Bereich.
- Lässt sich die Laufnummer nicht eindeutig aus dem Verzeichnisnamen bestimmen, frag mich danach, bevor du irgendetwas startest. Rate nicht.
- Bestimme Laufnummer und Portbereich einmal zu Beginn und gib beides an jede Sub-Session weiter.

## Rahmen für alle Skills
Die Skills sind für Projekte mit Tracker geschrieben. In diesem Lauf gilt für jede Sub-Session:
- Work Item: requirement.md im Arbeitsverzeichnis. Es gibt keinen Tracker. Wo ein Skill eine Work-Item-ID erwartet, gilt der absolute Pfad der requirement.md.
- Fragekanal: der Chat mit mir. Rückfragen einer Sub-Session laufen über dich zu mir, meine Antworten gibst du an dieselbe Sub-Session zurück.
- Ablageort des Plans: plan.md im Arbeitsverzeichnis. Nicht committen.
- Notizen, die ein Skill am Work Item ablegen würde: review-notizen.md im Arbeitsverzeichnis. Nicht committen.
- origin ist ein lokales bare Repository, das das Setup angelegt hat. fetch und push dorthin sind erlaubt und vorgesehen. Kein anderes Remote anlegen oder verwenden.
- Es gibt keinen PR-Dienst. Ein Pull Request ist in diesem Lauf:
  - der Feature-Branch, nach origin gepusht, mit Ziel STARTBRANCH. Die PR-Nummer ist der Branch-Name.
  - die Datei pr-<Branch-Name>.md im Arbeitsverzeichnis (Schrägstriche im Namen durch Bindestriche ersetzen). Nicht committen. Sie enthält Titel, Beschreibung, Kommentare, Antworten, Review-Notizen und das Urteil, jeweils mit Uhrzeit und Absender (Skill bzw. Phase).
  - „Pull Request erstellen“ heißt: Branch pushen und pr-<Branch-Name>.md anlegen.
  - „Kommentar am Pull Request“ und „Kommentar auflösen“ heißt: Eintrag in pr-<Branch-Name>.md anlegen bzw. als erledigt markieren.
  - „Request Changes“, „Approve“ und das Urteil stehen als Eintrag in pr-<Branch-Name>.md.
  - „Prüfungen des Pull Requests abwarten“ heißt: Build, alle Tests und Formatprüfung lokal im Worktree des Branches ausführen und das Ergebnis in pr-<Branch-Name>.md eintragen.
- Branch- und Worktree-Namen enthalten VARIANTE und Laufnummer, z. B. bench-ghp-g2-007-<kurzname>, damit parallele Läufe nicht kollidieren.
- Dienste und Testumgebungen ausschließlich auf Ports aus dem Portbereich.

## Sub-Sessions starten
- Jede Phase ist ein eigener Prozess, gestartet im Arbeitsverzeichnis:
  `claude -p --model <Modell> --output-format json "<Slash-Befehl> <Argument>"`
  gefolgt von den Angaben aus „Rahmen“, Laufnummer, Portbereich und dem phasenspezifischen Zusatz.
- Der Slash-Befehl steht am Anfang des Prompts, genau so wie in der Phase angegeben. Gib keine eigenen Anweisungen, die vom Skill abweichen.
- Merke dir die session_id aus der Ausgabe. Hat eine Sub-Session Rückfragen, legst du sie mir vor und setzt dieselbe Sub-Session fort mit `claude -p --resume <session_id> "<meine Antworten>"`. Starte für Rückfragen keine neue Session.
- Ruf die Skills nie selbst auf und erledige keine Teile davon selbst. Lässt sich ein Skill nicht starten: mich fragen.

## Vor dem Start prüfen
1. Laufnummer und Portbereich bestimmen.
2. Pfad und Version der aktiven Harness-Skills (generic-harness-preview) ins Protokoll schreiben. Das ist nur Dokumentation und kein Grund anzuhalten.
3. `node --version` mit NODE vergleichen. Bei Abweichung: mich fragen.
4. Prüfen, dass der Git-Arbeitsstand sauber ist, STARTBRANCH ausgecheckt ist und `git fetch origin` gelingt. origin ist ein lokaler Pfad, das ist so gewollt.

## Ablauf

### Phase 1: Planung
- Slash-Befehl: /generic-harness-preview:plan-implementation
- Modell: MODELL_PLANUNG
- Zusatz: „Der Auftrag umfasst nur die Planung. Rufe implement-work-item nicht auf.“
- Freigabe bei FREIGABE_PLAN = mensch: Plan und Prüfnotiz mir vorlegen. Änderungswünsche gehen per resume an dieselbe Sub-Session.
- Freigabe bei FREIGABE_PLAN = auto: der Sub-Session die Freigabe mit dem Vermerk „Freigabe durch Orchestrator (Benchmark)“ melden.
- Ende: plan.md mit Freigabevermerk.

### Phase 2: Umsetzung
- Slash-Befehl: /generic-harness-preview:implement-work-item
- Modell: MODELL_UMSETZUNG
- Zusatz: „Der freigegebene Plan liegt in <absoluter Pfad>/plan.md. Rufe plan-implementation nicht erneut auf.“
- Bei REQUIREMENT_AN_UMSETZER = nein: requirement.md nicht übergeben, Work Item sind die Akzeptanzkriterien im Plan.
- Der Skill reviewt intern und erstellt die Pull Requests im Sinne von „Rahmen für alle Skills“.
- Ende: Nummer(n) der Pull Requests, also die Branch-Namen, und die zugehörigen pr-<Branch-Name>.md.

### Phase 3: Unabhängiges Review
- Slash-Befehl: /generic-harness-preview:review-pullrequest <PR-Nummer>
- Modell: MODELL_REVIEW
- Ende: Urteil PASS, FAIL oder BLOCKED, eingetragen in pr-<Branch-Name>.md.
- PASS → Phase 5. FAIL oder BLOCKED → Phase 4.

### Phase 4: Findings beheben
- Slash-Befehl: /generic-harness-preview:fix-pullrequest <PR-Nummer>
- Modell: MODELL_UMSETZUNG
- Danach Phase 3 erneut als Folgerunde. Phase 4 plus Phase 3 zählt als eine Fix-Runde.
- Nach MAX_FIX_RUNDEN ohne PASS: mich fragen.

Bei mehreren Pull Requests laufen Phase 3 und 4 je Pull Request, in der Merge-Reihenfolge des Plans.

### Phase 5: Abschluss
- Nicht mergen und nicht approven. Das macht der Mensch. Die Branches bleiben in origin stehen.
- Protokoll abschließen.
- Zeig mir zum Schluss alle Sessions dieses Laufs als Tabelle, in der Reihenfolge, in der sie gestartet wurden:

  | Session name | Session ID |
  |---|---|
  | 007-orchestrator | `<ID>` |
  | 007-planung | `<ID>` |
  | 007-umsetzung | `<ID>` |
  | 007-review-1 | `<ID>` |
  | 007-fix-1 | `<ID>` |
  | 007-review-2 | `<ID>` |

- Session name = Laufnummer, Phase und bei Review und Fix die Runde, wie im Beispiel.
- Jede Session-ID steht in Backticks, damit ich sie einzeln kopieren kann.
- Nur IDs aus den Ausgaben der Sub-Sessions verwenden. Kennst du eine ID nicht sicher, auch deine eigene, schreib „unbekannt“, statt sie zu raten.
- Dieselbe Tabelle auch ans Ende von lauf-protokoll.md schreiben.

## Protokoll
Führe im Arbeitsverzeichnis eine Datei lauf-protokoll.md. Sie wird nicht committet.
- Pro Sub-Session: Phase, Slash-Befehl, Modell, session_id, Start- und Endzeit, Ergebnis in einem Satz.
- Pro Review: Urteil und Anzahl der Findings nach Schwere.
- Gesamtzahl der Fix-Runden.
- Jede Rückfrage an mich, mit Phase, Grund und Uhrzeit.
- Zum Abschluss: Status der Pull Requests und offene Punkte.

## Regeln
- Arbeite nur im Arbeitsverzeichnis und in den Worktrees, die die Skills anlegen.
- Lies nichts aus anderen Test-Verzeichnissen oder früheren Läufen.
- `--resume` nur für Sub-Sessions dieses Laufs.
- Bei Unklarheiten fragen, nicht raten.