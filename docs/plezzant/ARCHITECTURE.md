# Plezzant — Architecture Map

This is the working map of the codebase Plezzant is built on. It records what
already exists, where it lives, and what must survive the redesign. Read it
before deleting or replacing anything.

> **Key fact:** Plezzant is a **Flutter** application (Dart, ~950 source files,
> ~375k lines), not a Kotlin/Compose app. Android playback runs on **Media3 /
> ExoPlayer with an automatic libmpv fallback**, both owned by native Kotlin
> code behind platform channels. The redesign therefore keeps Flutter and
> restyles and extends the existing widget tree rather than porting to Compose.
> That also means the same Plex/domain code already runs on Windows, macOS and
> Linux, which keeps a future desktop client close to free.

---

## 1. Layering

```
lib/
├── main.dart                     startup, providers, MaterialApp, theme wiring
├── connection/                   persisted "connections" (Plex account, Jellyfin server)
├── profiles/                     Plex Home + local profiles, PIN handling, activation
├── media/                        backend-neutral DOMAIN MODELS + MediaServerClient interface
├── services/
│   ├── plex_client.dart (+parts) Plex Media Server client (≈4.7k lines)
│   ├── plex_auth_service.dart    plex.tv auth, PIN flow, resources, connection racing
│   ├── plex_mappers.dart         Plex JSON → domain models
│   ├── plex_playback_mapper.dart Plex media/stream decision mapping
│   ├── jellyfin_*                Jellyfin/Emby backend (kept, not Plezzant's focus)
│   ├── playback_*                playback init, reporting, progress, sessions
│   ├── track_*                   audio/subtitle selection and matching
│   ├── multi_server_manager.dart concurrent per-server clients, health, failover
│   ├── settings_service.dart     typed preference registry (Bool/Enum/… Pref)
│   └── …                         downloads, trackers, Discord, companion remote, etc.
├── mpv/                          Dart side of the player (Player API, mpv + ExoPlayer)
├── providers/                    ChangeNotifier state (libraries, hubs, playback, theme…)
├── database/                     Drift (SQLite): connections, profiles, downloads, caches
├── focus/                        D-pad focus engine: memory, key repeat, hub navigation
├── navigation/                   tabs, profile session scope, main screen scope
├── screens/                      screens (discover/home, libraries, detail, player, Live TV…)
├── widgets/                      shared UI (cards, hubs, rails, spotlight, video controls)
├── theme/                        mono theme + tokens (+ new plezzant/ design system)
└── i18n/                         slang translations (en + 21 locales)
```

**State management:** `provider` (`ChangeNotifier`s) plus a few singletons
(`SettingsService`, `MultiServerManager`). **DI:** constructor injection plus
`Provider` lookups, with no service locator. **Persistence:** `SharedPreferences`
through the typed `SettingsService` registry, plus Drift/SQLite for structured
data. Secrets go through `credential_vault.dart` and `sensitive_prefs.dart`.

### Backend abstraction

`lib/media/media_server_client.dart` defines `MediaServerClient`, a
backend-neutral interface for hubs, libraries, metadata, search, playback init,
reporting, watch state, Live TV, collections and playlists. `PlexClient` and
`JellyfinClient` implement it. `ServerCapabilities`
(`lib/media/server_capabilities.dart`) is how the UI gates features per
server: hide Live TV when unsupported, hide metadata editing for non-admins,
and so on. **Plezzant keeps this abstraction.** It is the seam that keeps Plex
specifics out of the UI and lets the domain move to desktop unchanged.

---

## 2. Plex integration (must survive)

| Concern | Where | Notes worth preserving |
|---|---|---|
| plex.tv sign-in, **TV PIN** (`/api/v2/pins`) | `services/plex_auth_service.dart`, `screens/auth/plex_pin_auth_flow.dart` | PIN polling, QR link, token validation |
| Client identity headers | `models/plex/plex_config.dart`, `plex_client.dart` | `X-Plex-*` headers; product name now **Plezzant** |
| Server discovery | `plex_auth_service.dart` (`/api/v2/resources`) | Classifies local, remote, relay and plex.direct endpoints; IP redaction in logs |
| Connection racing + latency | `PlexClient.testConnectionWithLatency/AverageLatency` | Picks the fastest working endpoint and re-prioritises on failure (`updateEndpointPreferences`) |
| Multiple servers | `services/multi_server_manager.dart` | Per-server clients, health checks, offline detection |
| Plex Home / managed / protected users | `profiles/plex_home_service.dart`, `plex_home_switch.dart`, `active_profile_binder.dart` | `/home/users`, `/home/users/{uuid}/switch` with PIN; never persisted as local rows |
| Hubs, Continue Watching, On Deck | `PlexClient` hub calls, `providers/discover_provider.dart` | Includes `removeFromOnDeck` |
| Libraries, filters, sorts, paging | `PlexClient` + `media/library_query.dart` | `_fetchPaged` with abort controllers for large libraries |
| Metadata, cast/crew, extras, related | `fetchItem`, `fetchItemWithOnDeck`, `getPlaybackExtras` | |
| Collections, playlists, play queues | `services/plex_client/parts/{collections,playlists,play_queues}.dart` | |
| Search | `PlexClient` + `mixins/debounced_media_search.dart` | Cross-server search |
| Watch state, rating, favourite | `markAsWatched/Unwatched`, `rate`, `setFavorite` | `providers/watch_state_store.dart` for optimistic UI |
| Timeline reporting | `reportPlaybackStarted/Progress/Stopped`, `services/playback_report_session.dart`, `playback_progress_tracker.dart` | Serialised start→progress→stop invariants |
| Playback decision | `PlexClient.getPlaybackInitialization`, `buildTranscodeStartPath`, `_buildTranscodeParams` | **Direct Play first.** Transcodes only when the quality preset is below the source or a subtitle must be burned. HLS fMP4 target with a TS/H.264 fallback profile; container verification (#1859 corruption guard) |
| Client profile | `X-Plex-Client-Profile-Extra` built in `plex_client.dart` | Hand-built codec profile; keep the encoding rules documented in place |
| Subtitle burn selection | `selectSubtitleStreamForBurn` | Must select the stream on the part before a burn transcode |
| Stream selection | `selectStreams(partId, audio, subtitle)` | Persists per-part audio/subtitle choice on the server |
| Markers & chapters | `media/media_source_info.dart` | Intro/credits markers plus a chapter-title fallback for intros/credits |
| Media versions / editions | `media/media_version.dart`, `media_version_preference.dart` | Version picker; edition titles |
| BIF / trickplay thumbnails | `downloadBifFile`, `services/bif_thumbnail_service.dart` | Scrub previews |
| Live TV & DVR | `services/plex_client/parts/live_tv.dart` (≈1.1k lines), `screens/livetv/` | Guide, channels, favourites, recordings, record options |
| Server admin bits | `scanLibrary`, `refreshLibraryMetadata`, activities | Admin-only affordances |
| Caching | `services/plex_api_cache.dart`, `api_cache.dart`, Drift tables | Offline cache of metadata |

---

## 3. Playback architecture (must survive)

```
UI (screens/video_player_screen.dart + screens/video_player/*)
  │  open request, chrome, sheets
  ▼
PlaybackInitializationService ──► MediaServerClient.getPlaybackInitialization
  │                                  (Plex: direct-play URL or transcode start path)
  ▼
Player (lib/mpv/player/*)  ── platform channel ──►  Android: Media3 ExoPlayer
  │                                                  └─ automatic fallback to libmpv
  │                                                  Desktop/iOS: libmpv
  ├─ TrackManager / TrackSelectionService  (audio & subtitle matching, preferences)
  ├─ PlaybackProgressTracker / PlaybackReportSession (timeline + watched state)
  ├─ FrameRateMatcher / DisplayModeService (refresh-rate matching)
  ├─ Markers (intro/credits skip), chapters, BIF scrub previews
  └─ PerformanceStats overlay (codec, decoder, bitrate, buffer, DV path)
```

Settings that drive playback live in `SettingsService`: `defaultQualityPreset`,
`cellularQualityPreset`, `directPlayCoveredQuality`, `useExoPlayer`,
`matchContentFrameRate`, hardware decoding, HDR, subtitle styling, autoplay and
seek steps.

Fragile areas, with comments explaining them in code:
* the open/EOF watchdogs (`open_http_503_watchdog.dart`, `spurious_eof_recovery.dart`, `first_frame_gate.dart`)
* the ExoPlayer→mpv handoff (`playback_open_outcome.dart`, `mpv_sidecar_open_guard.dart`)
* the transcode container guard (#1859)
* Dolby Vision conversion paths

**Do not restructure these while restyling.**

---

## 4. TV interaction layer (reuse)

`lib/focus/` is a complete D-pad engine:
* `FocusMemoryTracker`: returns focus to the last item per row or screen
* `HubVerticalNavigation`, `LockedHubController`: row-to-row movement
* `KeyRepeatHelper`, `TransportKeys`: hold-to-repeat and media keys (play, pause, ff, rw)
* `FocusTheme`: one place for focus scale, glow and duration

`PlatformDetector.isTV()` selects TV layouts. TV-specific widgets already exist:
`tv_spotlight_scaffold.dart`, `tv_spotlight_background.dart` (cinematic hero),
`tv_browse_rail.dart`, `side_navigation_rail.dart`, `tv_virtual_keyboard.dart`,
`tv_number_spinner.dart`. `DevicePerformance.isReduced` drops animations and
blur on weak TVs.

---

## 5. Plezzant design system (new, `lib/theme/plezzant/`)

| File | Purpose |
|---|---|
| `plezzant_palette.dart` | The fixed 26-hue × 3-shade palette, semantic hues and neutrals |
| `plezzant_color_matcher.dart` | sRGB → CIELAB, **CIEDE2000**, nearest-palette matching, neutral detection |
| `artwork_color_extractor.dart` | Tiny-decode dominant-colour extraction, memoised; always routed through the matcher |
| `plezzant_ambience.dart` | App-wide contextual palette colour, debounced to the item focus settles on |
| `plezzant_typography.dart` | The single Manrope type scale; nothing below 14 px |
| `plezzant_tokens.dart` | Spacing, radii, motion, glass materials |
| `plezzant_glass.dart` | Glass surfaces with a performance-aware blur fallback |
| `lib/widgets/app_icon.dart` | Central icon wrapper (Lucide) |

`MonoTokens` / `monoTheme` remain the theme entry point (many widgets read them);
they are now populated from the Plezzant tokens.

---

## 6. Internal identifiers that intentionally remain

Users never see these. Renaming them can't be verified without an Android
toolchain, and platform-channel names must match on both sides:

* Dart package name (`package:plezy/...` imports)
* Kotlin namespace / source package (`com.edde746.plezy` directories)
* Platform channel names (`com.plezy/mpv_player`, …)
* Third-party OAuth app registrations (Trakt, Simkl, MDBList client names).
  These are overridable at build time; see [RELEASE.md](RELEASE.md)

**Rename decision (1.1.0):** the internal identifiers above stay as they are.
Renaming them touches every import, the Kotlin sources and the native channel
names. It changes nothing users see, and a mismatch would only show up as a
runtime failure on a device. Revisit this only if the code is published as
its own repository.

User-visible identity **was** changed: app label, Android `applicationId`
(`app.plezzant.tv`, so it installs side-by-side), provider authorities, the
deep-link scheme, launcher icon, TV banner, in-app strings and the Plex
`X-Plex-Product` header.

---

## 7. Tests

~590 Dart test files under `test/` (unit and widget tests across services,
focus, screens and the player), plus Kotlin unit tests under
`android/app/src/test`. Run all Dart tests with `flutter test`. New Plezzant
tests live in `test/theme/`.
