# OneToolkit Mobile

Privacy-first utility toolkit — **85 offline tools** in one Flutter app.

**One app. Offline tools that stay private.**

## Stack

- Flutter 3.x · GetX · GetStorage · Material 3
- No ads · no account required · files stay on-device

## What’s shipped

| Category | Tools |
|---|---:|
| PDF | 13 |
| Images | 10 |
| Documents | 8 |
| QR & barcode | 6 |
| Text | 16 |
| Developer / utilities | 25 |
| Files | 4 |
| AI (on-device) | 3 |
| **Total** | **85** |

### Pillars

- **PDF** — merge, split, compress, rotate, protect/unlock, watermark, extract/delete/organize pages, images↔PDF, document scanner
- **Images** — compress, resize, rotate, crop, HEIC/WebP, background removal, EXIF, color picker, Base64
- **QR** — generate/scan, WiFi/contact/email QR, barcodes
- **AI** — OCR, translate, offline summarize
- **Files** — ZIP, checksum, duplicates, batch rename
- **Everyday** — passwords, units, calculator, tip/%, timer, loan/BMI/fuel/discount, notepad, formatters

### App shell

Home · Tools · Favorites · History · Settings · search · home-screen widgets + `onetoolkit://tool/<id>` deep links

## Run

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
  app/           # theme, routes, bindings
  core/          # constants, utils (incl. iOS-safe share)
  data/          # models, catalog, services
  modules/       # screens (shell, home, tools…)
  widgets/       # shared UI
```

## Privacy

No account required. Tools run locally on-device whenever possible. User files stay on the device.

## Next (planned)

1. Device smoke tests — Merge/Share, Scan→PDF, OCR, QR, widgets  
2. ~~Polish — onboarding, store listing~~ **done**  
3. ~~Deepen — PDF page previews + OCR editor~~ **done**  
4. Optional later — cloud sync / desktop, always opt-in

## Store listing (draft)

**Subtitle:** 85+ offline PDF, image, QR & utility tools — private by default

Copy the full App Store / Play text from **Settings → Store listing** in the app.
