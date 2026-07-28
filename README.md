# OneToolkit Mobile

Privacy-first utility toolkit — hundreds of offline productivity tools in one Flutter app.

**One app. Hundreds of tools. Zero complexity.**

## Stack

- Flutter 3.x
- GetX (state management, routing, DI)
- GetStorage (favorites, history, settings)
- Material 3 (light / dark / system)

## Phase 1 (shipped)

- App shell with bottom nav: Home · Categories · Favorites · History · Settings
- Searchable tool catalog (PDF, Images, Documents, QR, Text, Developer, Files, AI)
- Favorites, pins, recent tools, action history
- Working tools:
  - **Text:** Word Counter, Case Converter, Lorem Ipsum, JSON Formatter, Base64, Hash, URL Encoder, Diff Checker, Markdown Preview, Regex Tester
  - **QR:** Generate, Scan, WiFi, Contact (vCard), Email
  - **Images:** Compress, Resize, Rotate, Images → PDF
  - **PDF:** True on-device merge (`pdf_combiner`), PDF → Images
  - **Documents:** CSV ↔ JSON
  - **Files:** ZIP create/extract, File Checksum
  - **Developer:** JWT Decoder, UUID, Color Converter, Timestamp, HTTP Status, MIME Types

## Phase 2 (shipped)

- **PDF:** Split, Compress, Rotate, Protect, Unlock, Scan, Watermark, Extract, Delete, Organize
- **Images:** HEIC, WebP, Crop, Color Picker, Metadata, Background Removal
- **Documents:** YAML ↔ JSON
- **Files:** Duplicate Finder
- **AI:** OCR, on-device Translate, offline Summarize
- **Widgets:** Android + iOS (WidgetKit) favorites home-screen widgets

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

See the founder vision document — Phase 2 adds OCR, scanner, ZIP, widgets; Phase 3 cloud sync & desktop; Phase 4 AI & automation.
