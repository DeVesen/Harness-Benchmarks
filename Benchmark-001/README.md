# Benchmark-001: Vier gewinnt mit HTML, JavaScript und CSS

## Zweck

- Misst, wie gut ein Harness ein kleines, vollständig beschriebenes Vorhaben plant und umsetzt.
- Vergleicht Varianten eines Harness am selben Auftrag.
- Schwester-Benchmark: `Benchmark-002`, gleiche Anforderung mit Angular.

## Umfang

- Spiel für zwei Personen an einem Gerät, im Browser.
- Ein Work Item `WI-1` mit 39 Akzeptanzkriterien.
- Themen: Gerüst, Spielfeld und Züge, Sieg und Unentschieden, Punktestand, Namen, Spielstand merken.
- Technik: reines HTML, JavaScript als ES-Module und CSS; kein Framework, kein Build-Schritt.
- Werkzeuge nur für Entwicklung: Vitest mit jsdom, Playwright, ESLint, statischer Entwicklungsserver.
- Kein Backend, keine Datenbank, keine CI, kein Deployment.

## Unterschied zu Benchmark-002

- Fachlich gleich: dieselben Kriterien AC-02 bis AC-39, dieselben Entscheidungen zu Spiel und Oberfläche.
- AC-01 prüft den Start ohne Konsolenfehler statt eines Build-Befehls.
- Kein Gerüst durch ein CLI: Aufbau, Zustand und Rendering entwirft das Harness selbst.
- ADRs: Spiellogik ohne DOM, Zustand in einem Store-Modul.
- Zeigt, wie das Harness ohne Leitplanken eines Frameworks strukturiert.

## Dateien

- `requirement.md`: der Auftrag. Enthält Work Item, Teststrategie, ADRs und alle vorab getroffenen Entscheidungen.
- `README.md`: diese Beschreibung.
- Beide Dateien ändert ein Lauf nicht.

## Was der Benchmark prüft

- Plan: Zuordnung aller 39 Kriterien zu Schritten, Tests je Kriterium, Review-Fokus, Herkunft der Entscheidungen.
- Prüfung des Plans: Prüfnotiz mit Findings und Ausgang.
- Rückfragen: nur Lücken, die der Auftrag wirklich offen lässt.
- Umsetzung: Start, Tests, End-to-End und Lint grün.
- Review: Zahl und Schwere der Findings, Zahl der Fix-Runden.
- Struktur: Trennung von Spiellogik, Zustand, Speicher und Oberfläche.
- Sicherheit: Namen kommen nie als HTML ins DOM.
- Bewusst enthaltene Stolpersteine:
  - Sieg in vier Richtungen in einem Kriterium.
  - „Unverändert“-Kriterium (AC-22).
  - Zwei Siegeslinien zugleich, Sieg auf dem letzten freien Platz.
  - Eingabe während der Animation, reduzierte Bewegung.
  - Nicht lesbarer oder nicht verfügbarer Speicher.

## Was er nicht prüft

- Fähigkeit, Lücken selbst zu finden: fast alle Fragen sind vorab beantwortet.
- Schnittstellen, Datenhaltung, Infrastruktur, Betrieb.
- Arbeit mit Tracker und Pull Request.
- Zusammenarbeit mehrerer Teams.

## Lauf durchführen

1. Neuen Branch ab `main` anlegen: `lauf/b001-<variante>-<nn>`, z. B. `lauf/b001-basis-01`.
2. Harness-Variante aktivieren, andere Varianten deaktivieren.
3. Frische Sitzung in diesem Verzeichnis starten.
4. `plan-implementation` des Harness aufrufen und den Inhalt von `requirement.md` übergeben.
5. Erster Halt: Plan und Prüfnotiz lesen, freigeben.
6. Zweiter Halt: Ergebnis prüfen, Merge in den Lauf-Branch freigeben.
7. Messwerte festhalten.

## Regeln für faire Läufe

- Gleiches Modell und gleiche Effort-Stufe je Vergleich.
- `requirement.md` zwischen den Läufen nicht ändern.
- Auf Rückfragen in allen Läufen gleich antworten: „Entscheide nach deiner Empfehlung und halte es im Plan fest.“
- Je Variante mindestens zwei Läufe, weil Ergebnisse streuen.
- `main` enthält nur Auftrag und Beschreibung, nie ein Ergebnis.

## Messwerte je Lauf

- Zahl der Rückfragen und der Fragerunden.
- Länge des Plans in Zeilen.
- Kriterien ohne zugeordneten Schritt oder ohne Test.
- Findings im Review nach Schweregrad.
- Zahl der Fix-Runden.
- Zahl der Tests, Stand von Start, Tests, End-to-End und Lint.
- Laufzeit und Tokens.
- Nach eigener Prüfung: Kriterien, die an der laufenden App nicht erfüllt sind.

## Ergebnisse eines Laufs

- Liegen auf dem Lauf-Branch, nicht auf `main`.
- Plan: `docs/plans/WI-1.md`.
- Prüfnotiz: `docs/plans/WI-1-pruefnotiz.md`.
- Review-Notiz: `docs/reviews/WI-1.md`.
- ADRs: `docs/adr/`.
