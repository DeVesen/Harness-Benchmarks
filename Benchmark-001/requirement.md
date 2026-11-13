# Auftrag: Vier gewinnt mit HTML, JavaScript und CSS

## Ziel

Baue ein Vier-gewinnt-Spiel für zwei Personen an einem Gerät, im Browser, nur mit HTML, JavaScript und CSS, ohne Framework.
Das Projekt dient als Benchmark. Arbeite streng nach dem Prozess des Harness: erst `plan-implementation`, nach meiner Freigabe des Plans direkt `implement-work-item`.
Der Auftrag umfasst Planung und Umsetzung.

## Wie du mit Fragen umgehst

- Alle fachlichen und technischen Entscheidungen stehen unten unter „Entscheidungen“. Sie stammen von mir und sind bindend.
- Frag nur, was dort nicht steht und Folgen für die Spieler hat.
- Alles andere entscheidest du nach deiner Empfehlung und hältst es mit Grund im Plan fest.
- Verlangt eine Regel etwas, das es hier nicht gibt, etwa Tracker, Pull Request oder CI: Es gelten die genehmigten Ausnahmen unter „Genehmigte Ausnahmen“. Übernimm sie unverändert in den Plan. Erfinde keine eigenen dazu.
- Passt keine dieser Ausnahmen und fehlt etwas, das es hier nicht gibt: als offenen Punkt im Plan festhalten, nicht nachfragen.
- Halte nur zweimal an: für die Freigabe des Plans und vor dem Merge.

## Rahmen

- Pfade in diesem Auftrag sind relativ zum Wurzelverzeichnis des Projekts.
- Projektname: `vier-gewinnt`.
- Reines HTML, JavaScript und CSS. Kein Framework, keine Bibliothek, kein TypeScript.
- JavaScript als ES-Module, Sprachstand ES2022.
- Kein Build-Schritt, kein Bundler, kein Transpiler. Ausgeliefert werden die Quelldateien unverändert.
- Node in der aktuellen LTS-Version, Paketmanager npm, nur für Entwicklung und Tests.
- Kein Backend, keine Datenbank, keine externen Dienste.
- Keine Laufzeit-Abhängigkeiten.
- Einfache App: eine Seite, kein Routing, keine Konten, keine Einstellungen, keine Mehrsprachigkeit.
- Keine CI, kein Deployment.
- Kein Python. `python` ist auf diesem Rechner nur ein Platzhalter des Stores und hängt beim Aufruf. Hilfsskripte nur mit Node oder der Shell.

## Projektregeln

- Projektsprache: Deutsch für Dokumente und Oberfläche, Englisch für Code und Bezeichner.
- Es gibt keinen Tracker. Das Work Item steht vollständig in diesem Auftrag. Sub-Tasks gibt es nicht.
- Das Work Item ist umsetzungsreif.
- Schutzbedarf der Daten: niedrig. Es gibt keine personenbezogenen Daten.
- Fragekanal: dieser Chat.
- Plan: `docs/plans/WI-1.md`.
- Prüfnotiz zum Plan: `docs/plans/WI-1-pruefnotiz.md`.
- Review-Notiz: `docs/reviews/WI-1.md`.
- ADRs: `docs/adr/`, fortlaufend nummeriert. Die zwei ADRs unten legst du dort ab.
- Kein Push und kein Pull Request. Merge erst nach meinem Ja.
- Commits: Conventional Commits, deutsch, Betreff höchstens 60 Zeichen.

## Teststrategie

- Spiellogik: Unit-Tests ohne DOM-Zugriff, je Regel mindestens ein Positiv- und ein Negativfall.
- Oberfläche: Tests über das gerenderte DOM, nicht über interne Zustände.
- Unit- und Oberflächentests: Vitest, für die Oberfläche mit jsdom.
- Genau ein End-to-End-Test mit Playwright, nur Chromium, für den Hauptpfad: Spiel starten, bis zum Sieg spielen, neu starten.
- Weitere Playwright-Tests werden nicht eingecheckt. Die Prüfung an der laufenden Anwendung regelt „Prozess“.
- Tests laufen ohne Netzwerk und ohne feste Wartezeiten.
- Lint: ESLint mit den empfohlenen Regeln für JavaScript.
- Start, Test, End-to-End und Lint laufen je über einen Befehl aus `package.json`.
- Kein fester Schwellwert für die Abdeckung.
- Keine Mutationsproben: Code wird nicht absichtlich verändert, um Tests fehlschlagen zu sehen, auch nicht im Review. Den Nachweis, dass ein Test ohne die Änderung fehlschlägt, liefert der rote Lauf beim Schreiben des Tests vor dem Code.

## ADRs

**ADR-001: Spiellogik ist reines JavaScript ohne DOM**
- Entscheidung: Die Spielregeln liegen in Modulen mit reinen Funktionen ohne DOM-Zugriff. Die Oberfläche ruft sie nur auf.
- Grund: Regeln bleiben ohne Browser testbar.

**ADR-002: Zustand in einem Store-Modul**
- Entscheidung: Ein Modul hält den Spielzustand und benachrichtigt Abonnenten bei jeder Änderung. Die Oberfläche liest den Zustand und löst Aktionen aus, verändert ihn nie direkt.
- Grund: Eine Quelle für den Zustand, keine Bibliothek.

## Work Item WI-1: Vier gewinnt

Als zwei Spieler an einem Gerät wollen wir mehrere Partien Vier gewinnt spielen, mit Namen, Punktestand und ohne Verlust beim Neuladen.

### Gerüst

- AC-01: Gegeben das Projekt, wenn ich den Start-Befehl ausführe und die Seite im Browser öffne, dann lädt sie ohne Fehler in der Browser-Konsole.
- AC-02: Gegeben das Projekt, wenn ich den Test-Befehl ausführe, dann sind alle Tests grün.
- AC-03: Gegeben das Projekt, wenn ich den Lint-Befehl ausführe, dann endet er ohne Befund.
- AC-04: Gegeben die gestartete Anwendung, wenn ich sie im Browser öffne, dann sehe ich die Überschrift „Vier gewinnt“ auf dunklem Hintergrund.

### Spielfeld und Züge

- AC-05: Gegeben eine neue Partie, wenn ich sie öffne, dann sehe ich ein leeres Feld mit 7 Spalten und 6 Reihen.
- AC-06: Gegeben die allererste Partie, wenn ich sie öffne, dann zeigt die Anzeige „Spieler 1 ist am Zug“.
- AC-07: Gegeben eine Spalte mit freien Plätzen, wenn der Spieler am Zug sie wählt, dann liegt sein Stein auf dem untersten freien Platz dieser Spalte.
- AC-08: Gegeben ein gültiger Zug, wenn er ausgeführt wird, dann fällt der Stein sichtbar von oben auf seinen Platz, in höchstens 800 Millisekunden.
- AC-09: Gegeben ein Gerät, das reduzierte Bewegung verlangt, wenn ein Zug ausgeführt wird, dann erscheint der Stein ohne Animation an seinem Platz.
- AC-10: Gegeben ein fallender Stein, wenn ein Spieler währenddessen eine Spalte wählt, dann wird diese Eingabe ignoriert.
- AC-11: Gegeben ein gültiger Zug, wenn er ausgeführt ist, dann ist der andere Spieler am Zug und die Anzeige nennt ihn.
- AC-12: Gegeben eine volle Spalte, wenn ein Spieler sie wählt, dann ändert sich das Feld nicht, derselbe Spieler bleibt am Zug und die Spalte ist als nicht wählbar erkennbar.
- AC-13: Gegeben das Spielfeld, wenn ich nur die Tastatur nutze, dann kann ich jede Spalte erreichen und einen Zug auslösen.
- AC-14: Gegeben eine wählbare Spalte, wenn Zeiger oder Tastaturfokus auf ihr liegt, dann sehe ich über der Spalte eine Vorschau des Steins des Spielers am Zug.

### Sieg und Unentschieden

- AC-15: Gegeben vier Steine desselben Spielers in einer Linie, waagerecht, senkrecht oder in einer der beiden Diagonalen, wenn der vierte Stein gesetzt wird, dann zeigt die Anzeige „<Name> hat gewonnen“.
- AC-16: Gegeben ein Sieg, wenn er angezeigt wird, dann haben genau die Steine der Siegeslinie einen leuchtenden Rand und alle übrigen Steine sind abgedunkelt.
- AC-17: Gegeben mehr als vier Steine in einer Linie, wenn der letzte gesetzt wird, dann gilt das als Sieg und alle Steine dieser Linie sind hervorgehoben.
- AC-18: Gegeben ein Stein, der zwei Siegeslinien zugleich schließt, wenn er gesetzt wird, dann sind beide Linien hervorgehoben.
- AC-19: Gegeben ein volles Feld ohne Siegeslinie, wenn der letzte Stein gesetzt wird, dann zeigt die Anzeige „Unentschieden“.
- AC-20: Gegeben der letzte freie Platz, wenn der Stein dort eine Siegeslinie schließt, dann gilt das als Sieg, nicht als Unentschieden.
- AC-21: Gegeben eine beendete Partie, wenn ein Spieler eine Spalte wählt, dann ändert sich nichts.
- AC-22: Gegeben eine laufende Partie ohne Sieg und ohne Unentschieden, wenn ein Spieler zieht, dann gelten die Zugregeln aus AC-07 bis AC-12 unverändert.

### Neue Partie und Punktestand

- AC-23: Gegeben eine laufende oder beendete Partie, wenn ich „Neue Partie“ wähle, dann ist das Feld sofort leer, ohne Bestätigung.
- AC-24: Gegeben eine beendete Partie mit Sieger, wenn sie endet, dann erhöht sich der Punktestand des Siegers um 1.
- AC-25: Gegeben ein Unentschieden, wenn die Partie endet, dann ändert sich kein Punktestand.
- AC-26: Gegeben eine laufende Partie, wenn ich „Neue Partie“ wähle, dann ändert sich kein Punktestand.
- AC-27: Gegeben eine neue Partie nach einer vorigen, wenn sie beginnt, dann beginnt der Spieler, der die vorige Partie nicht begonnen hat, auch nach Unentschieden oder Abbruch.
- AC-28: Gegeben ein Punktestand, wenn ich „Stand zurücksetzen“ wähle, dann stehen beide Spieler auf 0.

### Namen

- AC-29: Gegeben zwei eingegebene Namen, wenn die Partie läuft, dann nennen Anzeige und Punktestand die Namen statt „Spieler 1“ und „Spieler 2“.
- AC-30: Gegeben ein Name, der leer ist oder nur aus Leerzeichen besteht, wenn die Partie läuft, dann gilt für diesen Spieler „Spieler 1“ bzw. „Spieler 2“.
- AC-31: Gegeben ein Name mit Leerzeichen am Anfang oder Ende, wenn er übernommen wird, dann sind diese Leerzeichen entfernt.
- AC-32: Gegeben das Namensfeld, wenn ich tippe, dann nimmt es höchstens 20 Zeichen an.
- AC-33: Gegeben eine laufende Partie, wenn ich einen Namen ändere, dann zeigen Anzeige und Punktestand sofort den neuen Namen und die Partie läuft unverändert weiter.
- AC-34: Gegeben zwei gleiche Namen, wenn ich sie eingebe, dann werden beide angenommen.

### Spielstand merken

- AC-35: Gegeben eine laufende Partie, wenn ich die Seite neu lade, dann sehe ich dasselbe Feld und denselben Spieler am Zug.
- AC-36: Gegeben Punktestand, Startspieler und Namen, wenn ich die Seite neu lade, dann sind sie unverändert.
- AC-37: Gegeben eine beendete Partie, wenn ich die Seite neu lade, dann sehe ich Ergebnis und Hervorhebung wie zuvor.
- AC-38: Gegeben ein gemerkter Spielstand, wenn ich den Tab schließe und die App neu öffne, dann beginnt alles neu: leeres Feld, Punktestand 0, keine Namen.
- AC-39: Gegeben ein gemerkter Spielstand, der nicht lesbar ist, wenn ich die Seite öffne, dann beginnt eine neue Partie und ich sehe den Hinweis „Gespeicherter Spielstand war nicht lesbar. Neue Partie gestartet.“

## Entscheidungen

Von mir getroffen, bindend. Sie beantworten alle Fragen, die ich vorhersehen konnte.

### Umfang

- Es gibt kein „Zug zurück“.
- Kein Computergegner, kein Spiel über das Netz, keine Zeitbegrenzung.
- Das Feld ist fest 7 Spalten mal 6 Reihen, nicht einstellbar.
- Kein Ton.
- Keine Statistik außer dem Punktestand.

### Züge und Eingabe

- Je Spalte gibt es genau eine Schaltfläche. Ein Klick auf eine Zelle der Spalte zählt wie die Schaltfläche.
- Tastatur: Tab erreicht die Spalten von links nach rechts, Enter oder Leertaste wirft den Stein.
- Nach einem Zug bleibt der Fokus auf der gewählten Spalte.
- Eine Eingabe, während ein Stein fällt, wird ignoriert und nicht nachgeholt.
- Der Spielzustand ändert sich sofort beim Zug, nicht erst am Ende der Animation.
- Ergebnis und Punktestand erscheinen, sobald der Stein liegt.
- Die Vorschau erscheint nicht bei voller Spalte, nicht bei beendeter Partie und nicht, während ein Stein fällt.
- Auf Geräten ohne Zeiger gibt es die Vorschau nur bei Tastaturfokus.

### Animation

- Die Fallzeit wächst mit der Fallhöhe und beträgt höchstens 800 Millisekunden.
- Die Animation läuft über CSS. Ihr Ende kommt über ein Ereignis, nicht über eine feste Wartezeit.
- „Neue Partie“, während ein Stein fällt, bricht die Animation ab und leert das Feld.
- Nach dem Neuladen liegen vorhandene Steine ohne Animation an ihrem Platz.
- Die Hervorhebung der Siegeslinie braucht keine Animation.

### Partie und Punktestand

- Die allererste Partie beginnt Spieler 1.
- Der Startspieler wechselt mit jeder neuen Partie, gleich wie die vorige endete.
- Eine abgebrochene Partie zählt nicht für den Punktestand.
- Der Punktestand hat keine Obergrenze.
- „Stand zurücksetzen“ setzt nur die Punkte auf 0. Feld, Namen und Startspieler bleiben.
- „Stand zurücksetzen“ fragt nicht nach.
- „Neue Partie“ ist immer wählbar, auch bei leerem Feld. Bei leerem Feld wechselt der Startspieler nicht.

### Namen

- Es gibt zwei Eingabefelder, immer sichtbar, beschriftet mit „Name Spieler 1“ und „Name Spieler 2“.
- Ein Name gilt sofort beim Tippen, ohne Schaltfläche.
- Erlaubt sind alle Zeichen. Namen werden immer als Text ausgegeben, nie als HTML.
- Die Grenze von 20 Zeichen setzt das Eingabefeld durch.
- Leerzeichen am Rand werden beim Verlassen des Feldes entfernt.
- Die Zuganzeige lautet „<Name> ist am Zug“, die Siegesanzeige „<Name> hat gewonnen“.
- Ohne Namen steht dort „Spieler 1“ bzw. „Spieler 2“.

### Spielstand merken

- Der Spielstand liegt im `sessionStorage`, unter genau einem Schlüssel, als JSON mit Versionsnummer.
- Gemerkt werden Feld, Spieler am Zug, Punktestand, Startspieler, Namen und bei beendeter Partie das Ergebnis.
- Nicht gemerkt wird der Hinweis aus AC-39.
- Gespeichert wird nach jeder Änderung des Zustands.
- Nicht lesbar ist: ungültiges JSON, unbekannte Version, falsche Struktur oder ein unmögliches Feld, etwa ein schwebender Stein.
- Ein nicht lesbarer Stand wird ganz verworfen, auch Punktestand und Namen.
- Der Hinweis dazu bleibt im selben Seitenaufruf sichtbar bis zum ersten Zug oder bis „Neue Partie“. Nach erneutem Neuladen ist er nicht mehr zu sehen.
- Ist `sessionStorage` nicht verfügbar, läuft das Spiel ohne Merken weiter, ohne Fehler und ohne Hinweis.
- Jeder Tab hat seinen eigenen Stand. Tabs gleichen sich nicht ab.

### Oberfläche

- Die App hat nur ein dunkles Erscheinungsbild.
- Spieler 1 spielt Neonrot, Richtwert `#ff1744`. Spieler 2 spielt Neongelb, Richtwert `#ffea00`. Hintergrund Richtwert `#0b0c10`.
- Jeder Stein trägt die Ziffer 1 oder 2, damit die Spieler nicht nur über die Farbe unterscheidbar sind.
- Reihenfolge von oben nach unten: Überschrift, Namen mit Punktestand, Anzeige, Spielfeld, Schaltflächen.
- Das Spielfeld ist ab 360 Pixel Breite ohne waagerechtes Scrollen bedienbar.
- Auf breiten Bildschirmen steht das Spielfeld mittig und wird höchstens 560 Pixel breit.
- Systemschrift, keine nachgeladenen Schriften.
- Texte wie in den Akzeptanzkriterien. Übrige Texte entscheidest du.
- Eigenes, schlichtes Erscheinungsbild. Kein Nachbau eines bestehenden Produkts.

### Barrierefreiheit

- Die Seite hat `lang="de"` und den Titel „Vier gewinnt“.
- Die Anzeige ist eine Live-Region, damit Screenreader Zugwechsel und Ergebnis ansagen.
- Jede Spalten-Schaltfläche heißt „Spalte <n>“.
- Jede Zelle nennt ihren Inhalt als Text: leer, Spieler 1 oder Spieler 2.
- Der Tastaturfokus ist immer sichtbar.
- Text erfüllt den Kontrast nach WCAG AA.

### Technik

- `index.html` liegt im Wurzelverzeichnis des Projekts, Quellen unter `src/`.
- Aufbau unter `src/`: `game/` für Spielregeln, `state/` für den Store, `storage/` für das Merken, `ui/` für die Oberfläche, `css/` für Styles.
- Module in `game/` und `state/` greifen nie auf DOM oder `sessionStorage` zu.
- Die Oberfläche rendert aus dem Zustand und aktualisiert das DOM gezielt.
- Nutzereingaben kommen nur über `textContent` ins DOM, nie über `innerHTML`.
- Keine Web Components, keine Vorlagen-Bibliothek.
- Kein Inline-JavaScript und kein Inline-CSS in `index.html`.
- Typen als JSDoc-Kommentare, wo sie beim Lesen helfen. Kein Typprüfer.
- Der Start-Befehl liefert das Projekt über einen statischen Entwicklungsserver aus.
- Öffnen per Doppelklick auf `index.html` muss nicht funktionieren.
- Das Projekt bekommt eine eigene `.gitignore`, mindestens für `node_modules` und Testberichte.
- `package-lock.json` wird eingecheckt.
- Styling mit reinem CSS, ohne Präprozessor.
- Entwicklungs-Abhängigkeiten nur: Vitest, jsdom, Playwright, ESLint und ein statischer Entwicklungsserver.
- Empfehlung für den Entwicklungsserver: Vite ohne Build-Schritt. Ein gleichwertiger ist erlaubt.
- Kein zusätzlicher Formatter.
- Pakete kommen aus der öffentlichen npm-Registry. Nichts wird global installiert.
- Playwright darf Chromium nachladen.
- Der End-to-End-Test startet den Entwicklungsserver selbst.
- Hinweise für Entwickler kommen nach `docs/entwicklung.md`.
- Unterstützte Browser: aktuelle Versionen von Chromium, Firefox und Safari.
- Zuschnitt der Module, Dateinamen und Algorithmus der Sieg-Erkennung entscheidest du.

### Prozess

- Ein Plan für das ganze Work Item. Ein Task-Schnitt im Plan ist erlaubt.
- Ob du Tasks nacheinander oder parallel umsetzt, entscheidest du.
- Die Prüfung an der laufenden Anwendung läuft über Playwright, ohne neue Testdateien im Projekt.
- Hilfsskripte dafür werden nicht Teil des Projekts und nicht committet.
- Nachweis der Prüfung: geprüfte Kriterien und Ergebnis je Kriterium in der Review-Notiz.
- Findings aus dem Review behebst du in höchstens zwei Runden.
- Danach offene Findings MEDIUM und LOW hältst du als „Won't Fix“ mit Grund in der Review-Notiz fest.
- Ist danach ein Finding BLOCKING oder HIGH offen, hältst du an und fragst mich.
- Verlangt das Harness ein Log oder weitere Notizen, liegen sie unter `docs/`.
- Es gibt keine Secrets und keine Lizenzdatei.

## Genehmigte Ausnahmen

Von mir genehmigt, gelten für den ganzen Lauf. Übernimm sie unverändert in den Plan.

```
EXCEPTION(BENCH-TRACKER): Es gibt keinen Tracker; Plan, Fragen, Antworten, Freigabe und Review-Notiz stehen nicht am Work Item, sondern in den Dateien unter „Projektregeln“, Fragen und Freigabe im Chat (AI-SE-3310 und Ablageorte aus plan-implementation und implement-work-item).
Tracking: requirement.md, Abschnitt „Projektregeln“
Revisit: wenn der Benchmark einen Tracker bekommt
Approved: Auftraggeber, 2026-11-12

EXCEPTION(BENCH-PR): Es gibt keinen Pull Request; an seine Stelle tritt die Review-Notiz, Begründung der Tests, Testlauf-Auszüge, Findings und Urteil stehen dort (AI-SE-3202, AI-SE-3215, AI-SE-3311, AI-SE-3319).
Tracking: docs/reviews/WI-1.md
Revisit: wenn der Benchmark Pull Requests bekommt
Approved: Auftraggeber, 2026-11-12

EXCEPTION(BENCH-CI): Es gibt keine CI; Tests, End-to-End und Lint laufen lokal über die Befehle aus package.json, das Log des letzten Laufs auf dem geprüften Stand steht als Nachweis in der Review-Notiz (AI-SE-3213, AI-SE-3214, AI-SE-3217, AI-SE-3221, AI-SE-3308).
Tracking: docs/reviews/WI-1.md
Revisit: wenn der Benchmark eine CI bekommt
Approved: Auftraggeber, 2026-11-12

EXCEPTION(BENCH-COVERAGE): Die Abdeckung wird nicht gemessen und nicht erzwungen, weil die Teststrategie keinen Schwellwert vorgibt; die Tests je Akzeptanzkriterium aus dem Plan ersetzen den Nachweis (AI-SE-3211, AI-SE-3222).
Tracking: requirement.md, Abschnitt „Teststrategie“
Revisit: wenn der Benchmark eine CI mit Abdeckungsbericht bekommt
Approved: Auftraggeber, 2026-11-12

EXCEPTION(BENCH-ORIGIN): Gearbeitet wird auf dem lokalen Stand, ohne Abgleich mit origin, weil nichts von origin geholt wird (AI-SE-4307).
Tracking: requirement.md, Abschnitt „Projektregeln“
Revisit: wenn gegen ein gemeinsames Remote gearbeitet wird
Approved: Auftraggeber, 2026-11-12

EXCEPTION(BENCH-MERGE): Gemergt wird lokal und erst nach meinem Ja; das ist der Ersatz für den Merge des Pull Requests (AI-SE-4105).
Tracking: requirement.md, Abschnitt „Projektregeln“
Revisit: wenn der Benchmark Pull Requests bekommt
Approved: Auftraggeber, 2026-11-12
```

## Ablauf

1. Starte jetzt `plan-implementation` für WI-1.
2. Lege mir Plan und Prüfnotiz zur Freigabe vor. Das ist der erste Halt.
3. Nach meiner Freigabe: `implement-work-item` für WI-1, ohne weitere Rückfrage.
4. Nach Umsetzung und Review: nenne Plan-Datei, Review-Notiz, Stand von Start, Tests und Lint sowie offene Punkte. Das ist der zweite Halt.
5. Nenne dabei auch: Zahl deiner Rückfragen, Zahl der Fix-Runden, Zahl der Tests.
6. Merge erst nach meinem Ja.
