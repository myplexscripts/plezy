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
| Theme music on details | 🆕 | Show, season and movie pages play the title's theme quietly (fade in, fade out on leave or play). Settings → Playback → *Play Theme Music* |
| Photo libraries | 🆕 | Albums and loose photos as landscape cards; album pages with Slideshow / Shuffle; full-screen viewer (LEFT/RIGHT, SELECT pauses or plays a video, UP/DOWN info). Jellyfin "Home Videos & Photos" libraries list photos under All. No Unwatched filter on photos |
| Voice search | 🆕 | Google Assistant "search for … on Plezzant" and the remote's search key open Search with the query |
| Related media | ✅ | |
| Watched / unwatched toggles | ✅ | Optimistic `watch_state_store` |
| Ratings and favourites | ✅ 🎨 | Colours moved onto the palette |
| Explore / Discover catalogue (TMDB etc.) | ✅ | |
| Watchlist | ✅ | Explore; needs plex.tv |
| Plex free streaming (Movies & TV on Plex, free Live TV channels) | 🚫 | Needs Plex's ad-supported playback and licensing endpoints, which third-party clients can't use. Catalogue rows and the Watchlist do appear in Explore |

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
| Cinema trailers before movies | 🆕 🖥 | Settings → Playback → *Cinema Trailers* (0–3). Plex servers with Cinema Trailers set up; plays from the start only, not on resume, Watch Together or offline |
| BIF / trickplay scrub thumbnails | ✅ 🖥 | Needs server-generated video preview thumbnails |
| Frame-rate / dynamic-range matching | ✅ | `FrameRateMatcher`, display mode services |
| ExoPlayer ↔ mpv fallback | ✅ | Automatic native fallback |
| Dolby Vision conversion paths | ✅ | |
| Performance / diagnostics overlay | ✅ 🆕 | Playback method row added |
| Player chrome | 🎨 | TV control bar floats on glass. Timeline accent follows the playing title's palette colour. Chapter/queue strip uses the same card focus as the rest of the app and lines up with the bar; player sheets share one header, focus fill and check-mark selection |
| Cast from the Plex app (Plex Companion target) | ⛔ | Plezzant can be driven from another Plezzant device (Companion remote), but does not yet advertise itself as a Plex player to the official Plex apps |

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
| Glass surfaces | 🆕 | `PlezzantGlass`: backdrop blur with vibrancy, white lift, top sheen and a specular edge; without blur (low-end tier, high contrast) the same pane on a denser base. Floating TV navigation, section chip, hero pills, overlay sheets, context menus and the TV player control bar |
| Ambience and glass intensity settings | 🆕 | Settings → Appearance (phones, tablets, desktop; TVs use the defaults) |
| Focus system (scale, luminance, tinted halo) | 🎨 | Thinner neutral edge, palette-tinted glow |
| Reduced-performance tier (weak TVs) | ✅ | Animations and blur drop out |
| Consistent TV scale on every box | 🆕 | Android TV renders through a 540-tall canvas whatever density the device reports |
| Effects tiers and accessibility | 🆕 | Full, balanced (blur capped on 3 GB boxes) and reduced tiers. High contrast gives solid glass and a thicker focus outline. "Solid (reduce transparency)" glass setting |
| Frame timing graph | 🆕 | Settings → Advanced; checks UI speed on the TV itself |
| TV visual regression tests | 🆕 | Golden images at 960×540 (sidebar, hero, profile picker, settings) run in CI |
| tvOS layout system | 🆕 | 1920×1080 reference canvas scaled to the device: 80 × 60 safe frame, couch-distance type roles and focus depth (scale, lift, glow, shadow). Reduce Motion is honoured separately from the effects tier |
| Ambient blur backgrounds | 🆕 | Home hero and movie/show pages sit on a soft blurred field built from the backdrop's left side, bottom-left corner and bottom edge (sampled per title, cross-fading, with grain). The backdrop always occupies the top-right corner and dissolves into it |
| Everyday feature set on TV | 🆕 | TVs show the settings a viewer reaches for; shaders, ambient lighting, decoder/backend, mpv config, buffers, overlays, debug, admin menu actions and new downloads stay at their defaults (phones, tablets and desktop keep everything) |
| Apple TV style navigation | 🆕 | Section pill (‹ Home) in the top-left corner; a floating glass sidebar with profile and clock that opens on LEFT; the focused item is a white pill |
| Apple TV style home | 🆕 | Full-bleed hero showing genre, rating badge and synopsis, with a white action pill (Play / Resume / Go to Show); landscape Up Next rows |
| Apple TV style details | 🆕 | Logo-led hero with a white "Play S1E1" pill and glass secondary actions |
| Apple TV style profile picker | 🆕 | "Who's watching?": round avatars on a soft gradient |
| TV search | 🆕 | Poster grid with kind chips (All / Movies / TV Shows / Episodes) |
| TV settings | 🆕 | tvOS-style large centred titles over a centred list |
| Consistent list pages | 🆕 | Collections, playlists, photo albums, person pages and "View all" share one header (artwork, title, metadata, actions) and back chip; their grids sit on the safe frame |
| One-press navigation | 🆕 | BACK opens the menu from any library or Downloads tab; the menu opens on the current section; libraries are always listed (no fold); hidden libraries are managed and opened from Settings → Manage Libraries only |
| Card Style | 🆕 | Settings → Appearance → *Card Style*: Landscape 16:9 (default) or Posters 2:3 across Home, library grids, collection/playlist pages, View all and Search |
| Trailer previews | 🆕 🖥 | Dwell on a movie or show on Home and its trailer plays silently behind the hero; Play/Pause watches it with sound. Needs a trailer on the server (Plex extras, Jellyfin local trailers). Settings → Appearance → *Trailer Previews* |
| Spoiler-safe labels | 🆕 | With *Hide Spoilers*, unwatched episode stills are veiled and labelled "S1 E3", so blurred rows stay navigable |
| Consistent grids and menus | 🆕 | Library grids, app-bar actions and the folder view sit on the safe frame; playlists are square everywhere; cast portraits are round; popup menus open at their button on every TV density; single-choice lists use a trailing check |
| Screensaver | 🆕 | Android TV screen saver "Plezzant": library backdrops cross-fading with their titles (Settings → System → Screen saver on the TV) |

## Diagnostics & settings

| Capability | Status | Notes |
|---|---|---|
| Logs viewer, copy logs | ✅ | Upload disabled by default (`ENABLE_LOG_UPLOAD`); logs stay on the device |
| Startup failure diagnostics | ✅ | |
| Playback settings (quality, audio, subtitles, autoplay, refresh rate) | ✅ | |
| Cache management | ✅ | |
| Settings export / import | ✅ | |

## External services inherited from the upstream project

Every endpoint and client ID below can be replaced at build time (see
[RELEASE.md](RELEASE.md)). Without overrides, the built-in defaults are used:

| Service | State in Plezzant | Build override |
|---|---|---|
| Crash reporting (Sentry) | Off. Needs your own DSN | `PLEZZANT_SENTRY_DSN` (CI also turns on `ENABLE_SENTRY`) |
| Update checker | Off unless built with `ENABLE_UPDATE_CHECK` | |
| Log upload relay | Off unless built with `ENABLE_LOG_UPLOAD`; uses the relay host | `PLEZZANT_RELAY_URL` |
| Watch Together relay | Default relay. Users can also set their own in Settings → Advanced | `PLEZZANT_RELAY_URL` |
| Discord Rich Presence poster host | Desktop only; uses the relay host | `PLEZZANT_RELAY_URL` |
| Trakt | Default OAuth app | `PLEZZANT_TRAKT_CLIENT_ID`, `PLEZZANT_TRAKT_CLIENT_SECRET` |
| Simkl | Default OAuth app | `PLEZZANT_SIMKL_CLIENT_ID` |
| MDBList | Default OAuth app | `PLEZZANT_MDBLIST_CLIENT_ID` |
| MyAnimeList | Default OAuth app | `PLEZZANT_MAL_CLIENT_ID` |
| Simkl / MDBList app-name header | Default name | `PLEZZANT_TRACKER_APP_NAME` |
