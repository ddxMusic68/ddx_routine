## Description

## Features

## Dropbox Sync Setup

Dropbox sync requires your own Dropbox app credentials. No API keys are baked into the app.

1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps).
2. Click **Create app** and choose **Scoped access** → **Full Dropbox** (or App folder).
3. Under the **Permissions** tab, enable `files.content.write` and `files.content.read`, then click **Submit**.
4. Copy the **App key** from the app's overview page.
5. In ddxJournal, open **Settings** → **Dropbox Sync** → **Connect**.
6. Enter your App key, then authorize the app in your browser and paste the authorization code back into the app.

Once connected, use **Sync Now** in settings to sync manually. Auto-sync runs on app startup when enabled.

## Architecture

```
lib/

```

## Dependencies

| Package | Purpose |
|---|---|

## Development

```bash
flutter pub get       # Install dependencies
flutter run            # Run the app
flutter analyze        # Lint check (uses flutter_lints)
```

Tests live in the `test/` directory and run with `flutter test`.

## Platform Support

| Platform | Status |
|---|---|
| Android | Supported |
| iOS | Unknown |
| Web | Unsupported |
| Linux | Unknown |
| macOS | Unknown |
| Windows | Supported |

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Run `flutter analyze` before committing.
4. Open a pull request with a description of your changes.

## Todo
- [ ] add sync
- [ ] finish readme




## Changelog
### Version 1.0.0
- [X] make about the app page
- [X] make current day say current day
- [X] make non current day say go to current day?
- [X] make z-index save to the daily menu
- [X] make duration optional
- [X] make windows storage next to executable
- [X] make min and max of time for duration and add optional text to it
- [X] fix month and yearly menuss
- [X] add export/import (select where to export and import)

got base app made
