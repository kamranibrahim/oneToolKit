# iOS Share Extension

Share PDFs and images into OneToolkit from other apps.

## Requirements

- Paid Apple Developer account (App Groups)
- App Group id: `group.com.kamranibrahim.onetoolkit`
- Enable that App Group on **Runner** and **ShareExtension** in Xcode → Signing & Capabilities

## Setup

Sources live in `ios/ShareExtension/`. The Xcode target was added via:

```bash
cd ios && ruby scripts/add_share_extension.rb
```

After enabling App Groups and signing, build/run from Xcode or `flutter run`.

Share a PDF or photo from Files/Photos → OneToolkit. The host app opens via `onetoolkit://share` and preloads the file into Merge PDF, Compress Image, or Images to PDF.
