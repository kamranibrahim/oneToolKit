# OneToolkit Mobile

Privacy-first utility toolkit — dozens of offline productivity tools in one Flutter app.

**One app. Dozens of offline tools. Zero complexity.**

## Stack

- Flutter 3.x
- GetX (state management, routing, DI)
- GetStorage (favorites, history, settings)
- Material 3 (light / dark / system)

## Phase 1–2 (shipped)

- App shell: Home · Tools · Favorites · History · Settings
- Searchable catalog across PDF, Images, Documents, QR, Text, Developer, Files, AI
- Favorites, pins, recent tools, action history
- Full PDF suite, image tools, QR/barcode, OCR/translate/summarize, widgets

## Phase 3 utilities (shipped)

- Password · Unit · Calculator · Tip · Percentage · Stopwatch/Timer · Age
- Random Generator · Number Base · IP Calculator · Cron Explainer
- Loan Calculator · BMI · Discount · Query String
- Line Tools · ASCII · Morse · Roman · HTML Entities
- Barcode Generate · Scan Code
- Image ↔ Base64 · Batch Rename
- HTML/XML/CSS/SQL Formatter · Notepad
- Home-screen widget deep links · Settings clear-data

## Run

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
  app/           # theme, routes, bindings
  core/          # constants, utils
  data/          # models, catalog, services
  modules/       # screens (shell, home, tools…)
  widgets/       # shared UI
```

## Privacy

No account required. Tools run locally on-device whenever possible. User files stay on the device.

## Roadmap

Phase 4: optional cloud sync, desktop targets, deeper AI/automation — always optional and privacy-preserving.
