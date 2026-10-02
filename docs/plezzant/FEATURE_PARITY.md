# Plezzant — Feature Parity Tracker

This document stops existing functionality from quietly disappearing during
the redesign. Every capability lists where it comes from, its state in
Plezzant, and what is still missing compared with a mature Plex TV client.

**Status legend**

| Mark | Meaning |
|---|---|
| ✅ Inherited | Already implemented in the inherited codebase and untouched in behaviour |
| 🎨 Restyled | Inherited behaviour, now rendered with the Plezzant design system |
| 🆕 Added | New in Plezzant |
| 🟡 Partial | Works, with known gaps |
| ⛔ Not yet | Not implemented |
| 🖥 Server | Depends on the server's version or configuration |
| ⭐ Plex Pass | Requires Plex Pass (on the server owner's account) |
| 🚫 Blocked | Technically blocked |

> "Verified" means covered by automated tests in this repo. None of this has
> been verified on a physical TV from this environment; see `TESTING.md`.

---

## Accounts & servers

| Capability | Status | Notes |
|---|---|---|
| Plex account sign-in (TV PIN, `plex.tv/link`) | ✅ 🎨 | `plex_pin_auth_flow.dart`; QR + code |
| Plex Home users | ✅ | `plex_home_service.dart` |
| Managed users | ✅ | Via Plex Home switch |
| Protected (PIN) users | ✅ | `pin_entry_dialog.dart`; PIN required mid-switch |
| Local profiles (non-Plex) | ✅ | `add_local_profile_screen.dart` |
| Multiple Plex servers | ✅ | `MultiServerManager`, cross-server hubs and search |
| Local / remote / relay connections | ✅ | Classified from `/api/v2/resources`; latency racing and failover |
| Secure connections (`plex.direct` HTTPS) | ✅ | User-installed CAs trusted on Android (`certificate_trust.dart`) |
| Server switching | ✅ 🎨 | Library grouping by server, hidden servers |
| Server capability detection | ✅ | `ServerCapabilities` gates Live TV, admin features and more |
| GDM / LAN broadcast discovery of Plex servers | ⛔ | Discovery goes through plex.tv resources, so a server with no plex.tv account link can't be found. Low priority |
| Sign out | ✅ | Settings → Account |
| Jellyfin / Emby backends | ✅ | Kept working; not a Plezzant focus |

## Browsing

| Capability | Status | Notes |
|---|---|---|
| Home hubs (Continue Watching, On Deck/Next Up, Recently Added) | ✅ 🎨 | Spotlight hero now drives palette ambience |
| Remove from Continue Watching | ✅ | |
| Movie libraries / TV libraries | ✅ 🎨 | Paged fetch with abort for large libraries |
| Seasons / episodes | ✅ 🎨 | |
| Filters, sorts, first-letter jump | ✅ | |
| Collections | ✅ 🎨 | Library → Collections tab (`/library/sections/{id}/collections`, paged), collection detail via `/library/collections/{id}/children`. Hidden on libraries shared from another account |
| Playlists (video + audio) | ✅ 🎨 | |
| Search (cross-server) | ✅ 🎨 | Debounced; TV virtual keyboard |
| Media details: metadata, ratings, cast & crew | ✅ 🎨 | |
| Extras / trailers | ✅ | |
| Related media | ✅ | |
| Watched / unwatched toggles | ✅ | Optimistic `watch_state_store` |
| Ratings and favourites | ✅ 🎨 | Colours moved onto the palette |
| Explore / Discover catalogue (TMDB etc.) | ✅ | |

## Playback

| Capability | Status | Notes |
|---|---|---|
| Direct Play (preferred) | ✅ | Default whenever the quality preset is Original or already covers the source |
| Direct Stream | ✅ 🆕 | The Plex HLS decision allows video copy. Plezzant now **reports** Direct Stream separately from Transcode, using the decision's per-stream `decision` |
| Transcode (HLS fMP4, TS fallback) | ✅ | Container-honoured guard (#1859) |
| Playback method shown to the viewer | 🆕 | Player → Settings → *Performance overlay*, first row "Playback" |
| Quality presets | ✅ | `defaultQualityPreset`, `cellularQualityPreset`, `remoteQualityPreset`, "play smaller videos at original quality" |
| Separate local vs remote quality | 🆕 | Settings → Playback → *Default Quality Away From Home*. Applies while the server is reached over a remote or relay endpoint (classified from the server's published connections; other backends by private-address check). Cellular override still wins |
| Bandwidth cap | 🟡 | Expressed through quality presets (bitrate ceilings) |
| Audio track selection | ✅ | Language and codec scoring; persisted per part (`selectStreams`) |
| Subtitle selection (embedded, sidecar, burn) | ✅ | Burn selects the stream on the part first |
| Forced subtitles | ✅ | Forced-flag scoring in `TrackSelectionService` |
| Online subtitle search | ✅ 🖥 | |
| Media versions | ✅ | Version picker and per-title preference memory |
| Editions | ✅ | Edition titles on versions |
| Chapters | ✅ | Chapter sheet, timeline markers |
| Intro markers / skip intro | ✅ ⭐ 🖥 | Marker detection is a Plex Pass server feature; chapter-title fallback |
| Credits markers / skip credits | ✅ ⭐ 🖥 | |
| Commercial markers (DVR) | 🆕 🖥 | "Skip Commercial" button, with its own Off / Button / Automatic setting (Settings → Playback → *Skip Commercials*). Needs the server's commercial detection (Plex DVR) or Jellyfin "Commercial" media segments. Unknown marker types no longer borrow the Skip Intro prompt |
| Resume position | ✅ | |
| Timeline reporting / sessions | ✅ | `PlaybackReportSession` start→progress→stop |
| Auto-play next episode, countdown | ✅ | |
| BIF / trickplay scrub thumbnails | ✅ 🖥 | Needs server-generated video preview thumbnails |
| Frame-rate / dynamic-range matching | ✅ | `FrameRateMatcher`, display mode services |
| ExoPlayer ↔ mpv fallback | ✅ | Automatic native fallback |
| Dolby Vision conversion paths | ✅ | |
| Performance / diagnostics overlay | ✅ 🆕 | Playback method row added |
| Player chrome | 🟡 🎨 | TV control bar floats on glass. Timeline accent follows the playing title's palette colour; Manrope and Lucide throughout. Post-play screen and chapter strip are restyled only through the shared tokens |

## Live TV & DVR

| Capability | Status | Notes |
|---|---|---|
| Channel guide | ✅ ⭐ 🖥 | Live TV requires a tuner/DVR on a Plex Pass server |
| Favourite channels and reorder | ✅ | |
| Recordings and schedule | ✅ ⭐ 🖥 | |
| Record options | ✅ ⭐ 🖥 | |
| Live timeline / time-shift | ✅ | Live indicators moved to palette Crimson |

## Interface (Plezzant design system)

| Capability | Status | Notes |
|---|---|---|
| Manrope everywhere | 🆕 | Bundled weights 300–800; one type scale (`PlezzantType`) with a 14 px floor |
| Lucide icons | 🆕 | All ~300 Material Symbols migrated; `material_symbols_icons` removed |
| Fixed palette (26 × 3) | 🆕 | `PlezzantPalette`; semantic `PlezzantColors` |
| Perceptual palette matching (CIELAB + CIEDE2000) | 🆕 | `PlezzantColorMatcher`, unit-tested against published reference pairs |
| Artwork ambience | 🆕 | Spotlight focus or the playing title → palette ambience → ambient glow, focus halo, player timeline |
| Glass surfaces | 🆕 🟡 | `PlezzantGlass` with a performance-aware solid fallback. Applied to the floating TV navigation panel, overlay sheets (player menus, pickers) and the TV player control bar. Alert dialogs and context menus still use solid surfaces |
| Ambience and glass intensity settings | 🆕 | Settings → Appearance |
| Focus system (scale, luminance, tinted halo) | 🎨 | Thinner neutral edge, palette-tinted glow |
| Reduced-performance tier (weak TVs) | ✅ | Animations and blur drop out |

## Diagnostics & settings

| Capability | Status | Notes |
|---|---|---|
| Logs viewer, copy logs | ✅ | Upload disabled by default (`ENABLE_LOG_UPLOAD`); logs stay on the device |
| Startup failure diagnostics | ✅ | |
| Playback settings (quality, audio, subtitles, autoplay, refresh rate) | ✅ | |
| Cache management | ✅ | |
| Settings export / import | ✅ | |

## External services inherited from the upstream project

These depend on infrastructure that Plezzant doesn't operate. They are kept
off by default or are desktop-only:

| Service | State in Plezzant |
|---|---|
| Crash reporting (Sentry) | Off unless built with `ENABLE_SENTRY` |
| Update checker | Off unless built with `ENABLE_UPDATE_CHECK` |
| Log upload relay | Off unless built with `ENABLE_LOG_UPLOAD` |
| Watch Together relay | Uses the upstream relay. Needs a Plezzant-owned relay before release |
| Discord Rich Presence poster host | Desktop only; not used on Android TV |
| Trakt / Simkl / MDBList OAuth apps | Registered under the upstream name. Plezzant needs its own client IDs before release |
