# iOS Favorites Widget

WidgetKit extension that shows starred OneToolkit tools.

## Requirements

- Paid Apple Developer account (App Groups)
- App Group id: `group.com.onetoolkit.oneToolkit`
- Enable that App Group on **Runner** and **FavoritesWidget** in Xcode → Signing & Capabilities

## Setup

Sources live in `ios/FavoritesWidget/`. The Xcode target was added via:

```bash
cd ios && ruby scripts/add_favorites_widget.rb
```

After enabling App Groups and signing, build/run from Xcode or `flutter run`.

Add the widget: long-press Home Screen → Widgets → **OneToolkit Favorites**.
Sync data from the app: Settings → Home screen widget (also auto-syncs when starring tools).
