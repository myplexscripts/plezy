# Releasing Plezzant

Everything needed to build a Plezzant release you control: versioning,
signing, and replacing the built-in service credentials with your own.

## Versioning

`pubspec.yaml` holds `version: MAJOR.MINOR.PATCH+BUILD`.

* `MAJOR.MINOR.PATCH` is the name people see (Settings → About).
  * Bump **minor** for new features or redesigns.
  * Bump **patch** for fixes only.
* `BUILD` becomes the Android `versionCode`. It **must go up on every
  release**, otherwise Android refuses to install the new APK over the old one.

The per-CPU APKs get Flutter's ABI offset added to `versionCode`
(armeabi-v7a +1000, arm64-v8a +2000, x86_64 +4000). The universal APK does
not. Moving a device from a per-CPU APK to the universal APK therefore needs
an uninstall first.

| Version | Build | Highlights |
|---|---|---|
| 1.3.0 | 153 | Same TV layout on every box, balanced effects tier, high-contrast solid glass, frame timing graph, TV golden tests in CI, Manrope in hero metadata |
| 1.2.0 | 152 | tvOS layout system: correct TV scaling (Google TV renders at 960×540 logical), safe frame, TV type roles, larger sidebar, focus depth, full-screen profile picker, Reduce Motion |
| 1.1.0 | 151 | Apple TV style redesign: navigation pill, floating sidebar, hero, details, profile picker, search grid, tvOS settings. Build-time service overrides |
| 1.0.0 | 150 | First Plezzant release: design system, Plex gap fixes, signed universal APK |

## Signing

Android installs an update only when it is signed with the same key as the
installed copy.

* **Without secrets**, the CI build is signed with a debug keystore kept in
  the GitHub Actions cache (`plezzant-debug-keystore-v1`). Every build uses
  the same key until the cache entry expires (7 days unused). After that, a
  new key is generated and testers must uninstall once.
* **For releases**, add your own upload key as repository secrets
  (GitHub → Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `PLEZZANT_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `PLEZZANT_STORE_PASSWORD` | Keystore password |
| `PLEZZANT_KEY_PASSWORD` | Key password |
| `PLEZZANT_KEY_ALIAS` | Key alias, e.g. `upload` |

Create a key once and keep it safe. Losing it means users must uninstall to
get updates.

```sh
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Locally, the same values go in `android/key.properties`:
`storePassword`, `keyPassword`, `keyAlias`, and
`storeFile=upload-keystore.jks`, with the `.jks` file in `android/app/`.
Without `key.properties`, release builds fall back to the debug key, so they
are always installable. The CI step "Verify APK signatures" fails the build
if any APK is unsigned.

## Your own service credentials

The tracker integrations and Watch Together ship with built-in defaults
inherited from the upstream project. Replace them by registering your own
apps and adding the values as repository secrets. CI passes only the
secrets that are set, so anything you leave unset keeps its default.

| Secret | Where to get it |
|---|---|
| `PLEZZANT_TRAKT_CLIENT_ID`, `PLEZZANT_TRAKT_CLIENT_SECRET` | https://trakt.tv/oauth/applications. Redirect URI `urn:ietf:wg:oauth:2.0:oob` (device-code flow) |
| `PLEZZANT_SIMKL_CLIENT_ID` | https://simkl.com/settings/developer. App type "Commandline / Console / Device code" |
| `PLEZZANT_MDBLIST_CLIENT_ID` | https://mdblist.com/developer. App type "Device Code" |
| `PLEZZANT_MAL_CLIENT_ID` | https://myanimelist.net/apiconfig. Note that its authorize step runs through the relay's OAuth proxy |
| `PLEZZANT_TRACKER_APP_NAME` | Name sent to Simkl and MDBList. Set it to match your registrations |
| `PLEZZANT_RELAY_URL` | Base URL of your own Watch Together relay, e.g. `https://relay.example.com`. Log upload and the Discord poster host use the same host |
| `PLEZZANT_SENTRY_DSN` | Your Sentry project's DSN. Setting it also turns on crash reporting |

Users can still point Watch Together at another relay at runtime
(Settings → Advanced → Watch Together relay).

For local builds, pass the same keys with `--dart-define`, or put them in a
JSON file:

```sh
flutter build apk --release --dart-define-from-file=build-defines.json
```

## Release checklist

1. Bump `version:` in `pubspec.yaml`, raising the build number, and add a
   row to the table above.
2. Run `flutter analyze` and `flutter test`. Both must be clean.
3. Push to `plezzant` and wait for the **Plezzant Android** workflow to go
   green.
4. Download the `plezzant-apks` artifact and install the universal APK over
   the previous version on a TV, to confirm the update keeps the sign-in.
5. Work through the Plex checklist in [TESTING.md](TESTING.md).
