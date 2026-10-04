# How to test Plezzant

This guide assumes you have never built or installed an Android app before.
Follow it top to bottom and you will have Plezzant running.

There are three ways to try Plezzant:

* **Option A** – on your Windows PC, inside a pretend Android TV (an *emulator*).
* **Option B** – on a real Android TV / Google TV, installed from your PC over the network.
* **Option C** – on a real TV, installed from a USB stick or file manager, with no PC tools.

All three use the same ready-made app file (an **APK**). GitHub builds it
automatically every time new work is pushed to the `plezzant` branch, so you
don't need to build anything yourself unless you want to (Option A, Part 2).

---

## 0. Download the Plezzant APK (needed for every option)

1. Open your web browser and go to
   **https://github.com/myplexscripts/plezy/actions/workflows/plezzant-android.yml**
   (sign in to GitHub if asked).
2. You will see a list of runs. Click the **top one** that has a **green tick ✓**
   next to it. (A yellow dot means it is still building, so wait a few minutes and
   refresh. A red ✗ means the build failed, so tell Claude which run failed.)
3. Scroll to the bottom of that page to the box called **Artifacts**.
4. Click **plezzant-apks**. A file called `plezzant-apks.zip` downloads.
5. Open your **Downloads** folder, right-click `plezzant-apks.zip`, choose
   **Extract All…**, then click **Extract**.
6. Inside the new `plezzant-apks` folder are four files:

   | File | Use it for |
   |---|---|
   | `plezzant-universal.apk` | **Start here.** Installs on any TV, box or emulator |
   | `plezzant-x86_64.apk` | Smaller file for the emulator on your PC (Option A) |
   | `plezzant-arm64-v8a.apk` | Smaller file for most modern TVs and boxes (NVIDIA Shield, newer Google TV TVs, Fire TV Stick 4K Max) |
   | `plezzant-armeabi-v7a.apk` | Smaller file for older or budget TVs, Chromecast with Google TV, most Fire TV sticks |

   If you're unsure, use `plezzant-universal.apk`. It is bigger because it
   contains every CPU type, but it always installs.

   Every build is signed with the same key, so a newer APK installs over the
   older one and keeps your sign-in. **Stick with the same kind of file each
   time.** The smaller per-CPU files carry a higher internal version number
   than the universal one, so Android refuses to swap a per-CPU install for
   the universal file ("App not installed"). If that happens, or if your
   copy came from a much older build, uninstall Plezzant first (Option B,
   step 12) and then install again.

> Plezzant installs **next to** any other Plex app. It doesn't replace the
> official Plex app or anything else.

---

## Option A: Windows PC with an Android TV emulator

### Part 1 – Install Android Studio and create a TV emulator

**1. Download Android Studio.**
Go to **https://developer.android.com/studio** and click the big
**Download Android Studio** button. Tick the box to accept the terms, then click
**Download**. The file is about 1 GB and is named something like
`android-studio-2025.x.x.x-windows.exe`.

**2. Install it.**
Double-click the downloaded file. Click **Yes** if Windows asks for permission.
Click **Next** on every screen, keeping all the default ticks (including
**Android Virtual Device**), then **Install**, then **Finish**.

**3. First start.**
Android Studio opens a *Setup Wizard*.
* Choose **Do not import settings** → **OK** if asked.
* Click **Next**. Choose **Standard**, then **Next**.
* Pick a theme (either is fine), then **Next**.
* On the **License Agreement** screen, click each item on the left and choose
  **Accept** for each one.
* Click **Finish**. Android Studio now downloads the *Android SDK* (about 1–3 GB).
  **Wait until** the button at the bottom says **Finish** again and click it.

**4. Open Device Manager.**
On the Android Studio welcome window, click **More Actions** (or the **⋮** menu)
→ **Virtual Device Manager**. If a project is already open, use the menu bar:
**View → Tool Windows → Device Manager**.

**5. Create a TV device.**
* Click the **+** button (or **Create Virtual Device**).
* In the left column, click **TV**.
* Choose **Television (1080p)** and click **Next**.

**6. Choose the Android version (system image).**
* Click the **Google TV** or **Android TV** tab if there is one, otherwise stay on
  **Recommended**.
* Pick the row that says **API 34**, **Android 14.0 (Google TV)** with ABI
  **x86_64**. If that isn't listed, choose the newest **Android TV x86_64** image.
* Click the **download arrow ⬇** next to its name, accept the licence, and
  **wait until** the download finishes. Click **Finish**, then **Next**.
* Name it `Plezzant TV` and click **Finish**.

**7. Start the emulator.**
In Device Manager, click the **▶ Play** button next to `Plezzant TV`.
**Wait until** a TV home screen appears in a new window. The first boot can take
2–5 minutes. If Google TV asks you to sign in, you can choose **Skip**.

**8. Install Plezzant into the emulator (no building needed).**
Open File Explorer, go to the `plezzant-apks` folder from section 0, and
**drag `plezzant-x86_64.apk` onto the emulator window**. Let go of the mouse.
After a few seconds a message says the app was installed.

**9. Launch it.**
On the emulator's TV home screen go to **Apps** (or the row of apps), find
**Plezzant** (red "P with a play triangle" icon) and press **Enter**.

You can stop here: this is everything you need to try Plezzant. Part 2 is only
for building the app from the source code yourself.

### Part 2 – (Optional) Build and run Plezzant from source in Android Studio

Plezzant is a **Flutter** app, so Android Studio also needs the Flutter tools.

**1. Install Git.** Download from **https://git-scm.com/download/win**, run it, and
click **Next** through every screen, keeping the defaults.

**2. Install the Flutter SDK.**
* Go to **https://docs.flutter.dev/get-started/install/windows/mobile** and
  download the Flutter SDK zip (version **3.47** or newer).
* Create the folder `C:\src` and extract the zip there, so you have `C:\src\flutter`.
* Press the **Windows key**, type `environment`, and click
  **Edit the system environment variables** → **Environment Variables…**.
  Under *User variables*, select **Path** → **Edit** → **New**, and type
  `C:\src\flutter\bin`. Click **OK** three times.

**3. Install the Flutter plugin.** In Android Studio: **File → Settings → Plugins**
(on the welcome screen: **Plugins** on the left). Search **Flutter**, click
**Install**, accept the Dart plugin too, then click **Restart IDE**.

**4. Get the code on the `plezzant` branch.**
* On the welcome screen click **Get from VCS** (or **File → New → Project from
  Version Control**).
* URL: `https://github.com/myplexscripts/plezy.git`. Directory: `C:\src\plezy`.
  Click **Clone**. Click **Trust Project** if asked.
* In the bottom-right corner of the window there is a branch name (probably `main`).
  Click it → **Remote Branches** → **origin/plezzant** → **Checkout**.
  The corner now says **plezzant**. That's how you know you're on the right branch.

**5. Let Android Studio prepare.** A banner may say *"Pub get has not been run"*.
Click **Get dependencies**. Android Studio and Gradle will also download the
Android NDK, CMake and the video-player libraries automatically on the first build.
**This first build can take 15–30 minutes.** Later builds are much faster.

**6. Pick the run target.** Start the `Plezzant TV` emulator (Part 1, step 7).
At the top of Android Studio, in the device drop-down (next to the green ▶ button),
choose **Plezzant TV (mobile emulator)** or the emulator's name.

**7. Press Run.** Click the **green ▶ Run 'main.dart'** button in the toolbar
(or press **Shift+F10**). **Wait until** the **Run** panel at the bottom says
`Syncing files to device…`. Plezzant then opens in the emulator.

* **Restart the app:** click the **circular-arrow ⟳ Hot Restart** button in the
  Run panel, or stop it and press ▶ again.
* **Stop the app:** click the red **■ Stop** button in the toolbar.
* **Where errors appear:** the **Run** panel at the bottom (Flutter errors in red),
  and **View → Tool Windows → Logcat** for Android-level errors.

### What you should see when it works

1. A near-black screen with the **Plezzant** mark, then a **Sign in with Plex**
   screen showing a short code and a QR code.
2. On your phone or computer, open **https://plex.tv/link**, sign in, and type the code.
3. If your Plex account has Plex Home users, a **profile picker** appears.
   Choose a profile (enter its PIN if it has one).
4. The **Home** screen: a large cinematic picture of the highlighted title at the
   top, with its logo, details and description, and rows such as
   **Continue Watching** and **Recently Added** below it. When you move between
   titles, a soft coloured glow in the top-left of the screen gently changes to
   match the artwork.
5. A navigation rail on the left: Home, Libraries, Live TV (only if your server
   has it), Search, Downloads, Settings.

### Emulator keyboard controls (pretend TV remote)

| Remote button | PC keyboard |
|---|---|
| Up / Down / Left / Right | **Arrow keys** |
| Select / OK | **Enter** |
| Back | **Esc** (or the ◀ button on the emulator's side toolbar) |
| Home | **Home** key / ○ on the side toolbar |
| Play / Pause | **Space** inside the player |
| Rewind / Fast-forward | **Left / Right arrows** in the player |

The emulator's side toolbar (click **⋯ Extended controls**) also has a
**Directional pad** under *Virtual sensors → D-pad*.

**Restart Plezzant in the emulator:** press **Home**, then open Plezzant again. To
fully restart it: open emulator **Settings → Apps → Plezzant → Force stop**,
then launch it again.

### Copying errors from the emulator

* In Android Studio: **View → Tool Windows → Logcat**. In the search box at the top
  of Logcat, type `package:app.plezzant.tv`. Click inside the log, press
  **Ctrl+A** then **Ctrl+C**, and paste it into a text file.
* Inside Plezzant: **Settings → Advanced → View Logs → Copy logs** (the copy icon at the top) copies Plezzant's own
  log to the clipboard.

---

## Option B: Real Android TV / Google TV over the network (ADB)

### 1. Open the TV's Settings
Press the **Home** button on the remote, go to the **⚙ Settings** gear (top-right
on Google TV), and press **OK**.

### 2. Reveal Developer Options
* **Google TV:** **Settings → System → About**.
* **Android TV (older):** **Settings → Device Preferences → About**.
* **Fire TV:** **Settings → My Fire TV → About**.

Scroll to **Android TV OS build** (or **Build**) and press **OK seven times**.
A message says **"You are now a developer!"**.
(On Fire TV, press OK on your device name seven times.)

### 3. Enable debugging
Press **Back**. A new menu **Developer options** has appeared (under *System*, or
*Device Preferences*). Open it and turn **ON**:
* **USB debugging** (also called **ADB debugging**), and
* **Network debugging** / **Wireless debugging** if it's offered.

On Fire TV also turn on **Apps from Unknown Sources**.

### 4. Find the TV's IP address
**Settings → Network & Internet →** your Wi-Fi or Ethernet network. Write down
the **IP address**, for example `192.168.1.57`.

### 5. Install Android Platform Tools (ADB) on Windows
* Download **SDK Platform-Tools for Windows** from
  **https://developer.android.com/tools/releases/platform-tools**.
* Right-click the zip → **Extract All…** and extract to `C:\platform-tools`.

### 6. Open PowerShell in that folder
Open File Explorer, go to `C:\platform-tools`, click the address bar, type
`powershell` and press **Enter**. A blue window opens, already in the right folder.

### 7. Connect to the TV
Type this, replacing `192.168.1.57` with your TV's IP address, and press Enter:

```powershell
.\adb.exe connect 192.168.1.57:5555
```

* **Approve on the TV:** a box pops up on the TV, **"Allow USB debugging?"**. Tick
  **Always allow from this computer** and press **OK**.
* If the PowerShell window said `failed to authenticate` or `unauthorized`, run the
  same `connect` command once more after approving.
* If your TV uses **Wireless debugging with a pairing code** (Android 11+ Google TV):
  open **Developer options → Wireless debugging → Pair device with pairing code**.
  The TV shows an IP:port and a 6-digit code. Run:

  ```powershell
  .\adb.exe pair 192.168.1.57:37123
  ```
  (use the IP:port shown on the pairing screen), type the 6-digit code, then
  connect with the IP:port shown on the main **Wireless debugging** screen:

  ```powershell
  .\adb.exe connect 192.168.1.57:41567
  ```

Check that it worked:

```powershell
.\adb.exe devices
```
You should see your TV's address followed by the word `device`.

Ask the TV which APK it needs:

```powershell
.\adb.exe shell getprop ro.product.cpu.abilist
```
* If the answer contains `arm64-v8a`, use `plezzant-arm64-v8a.apk`.
* If it only lists `armeabi-v7a`, use `plezzant-armeabi-v7a.apk`.

### 8. Where the APK is
It's in the `plezzant-apks` folder you extracted in section 0, for example
`C:\Users\David\Downloads\plezzant-apks\plezzant-arm64-v8a.apk`.

### 9. Install
Replace the path with your real path (tip: type `.\adb.exe install -r `, with a space
at the end, then drag the APK file onto the PowerShell window to paste its path):

```powershell
.\adb.exe install -r "C:\Users\David\Downloads\plezzant-apks\plezzant-arm64-v8a.apk"
```
It prints `Success` when done.

### 10. Launch Plezzant
Either find **Plezzant** in the TV's **Apps** row, or type:

```powershell
.\adb.exe shell monkey -p app.plezzant.tv -c android.intent.category.LEANBACK_LAUNCHER 1
```

### 11. Install a newer build over the old one
Download the new APK (section 0) and run the **same** `install -r` command. The `-r`
keeps your sign-in and settings.
If it says `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the new build was signed
differently. Uninstall first (step 12), then install again.

### 12. Uninstall Plezzant

```powershell
.\adb.exe uninstall app.plezzant.tv
```
(Or on the TV: **Settings → Apps → Plezzant → Uninstall**.)

---

## Option C: Simple APK sideload (no PC tools)

1. **The file:** `plezzant-arm64-v8a.apk` (or `plezzant-armeabi-v7a.apk` for older
   TVs), from the `plezzant-apks` folder in section 0.
2. **Put it on a USB stick:** copy the APK onto a USB stick and plug it into the TV.
   (Alternatively, upload it to Google Drive and use a TV file manager with Drive
   support, or use the **Send Files to TV** app on both phone and TV.)
3. **Install a file manager on the TV:** open the **Google Play Store** on the TV
   and install **File Commander** or **X-plore File Manager**. On Fire TV, install
   **Downloader** from the Amazon Appstore instead.
4. **Allow the install permission:** open **Settings → Apps → Security &
   restrictions → Unknown sources** (wording varies: *Install unknown apps*) and
   switch **ON** the file manager you just installed. On Fire TV: **Settings → My
   Fire TV → Developer options → Install unknown apps → Downloader → ON**.
5. **Install:** open the file manager, open the USB stick, select the APK, press
   **OK**, then **Install**. When it finishes, choose **Open**.
6. **Future updates:** repeat steps 2 and 5 with the newer APK. It installs over the
   old one and keeps your settings. If the TV says the app "conflicts with an
   existing package", uninstall Plezzant first (**Settings → Apps → Plezzant →
   Uninstall**) and install again.

---

## Plex test checklist

Tick each item as you check it. Note anything odd, with the time it happened.

- [ ] Plezzant launches and shows the Plezzant mark (not any other app name)
- [ ] Plex sign-in with the code from plex.tv/link works
- [ ] Plex Home profile picker appears (if your account has Home users)
- [ ] Protected profile asks for its PIN
- [ ] Server selection / multiple servers appear (Settings → Server, or the Libraries list)
- [ ] Home loads with the big spotlight picture and rows
- [ ] Continue Watching shows partly watched titles with a red progress line
- [ ] Movies library opens and scrolls smoothly, even if it's large
- [ ] TV Shows library opens
- [ ] A show's seasons open
- [ ] A season's episodes open
- [ ] Search finds a movie and a show (try typing three letters)
- [ ] Movie details page: logo/title, description, cast, play button
- [ ] Show details page
- [ ] Collections open
- [ ] Playlists open
- [ ] Direct Play: an ordinary movie plays and the overlay says **Direct Play** (see below)
- [ ] Direct Stream: set quality to something lower *and* choose an image-based subtitle (PGS); overlay says **Direct Stream** or **Transcode**
- [ ] Transcode: set quality to 720p on a 4K/1080p file; overlay says **Transcode**
- [ ] Playback resume: stop halfway, reopen, choose Resume. It continues from the same spot
- [ ] Watched state: finish an episode, go back. It shows as watched
- [ ] Audio selection: change the audio track in the player
- [ ] Subtitle selection: turn subtitles on, change them, turn them off
- [ ] Intro skip button appears on an episode with an intro (Plex Pass server)
- [ ] Credits skip / next episode appears near the end
- [ ] Quality change during playback works
- [ ] Live TV guide opens (only if your server has a tuner)
- [ ] DVR recordings list opens (only with DVR)
- [ ] **Back** always goes one step back, and never exits the app unexpectedly
- [ ] D-pad focus: you can always see what is selected
- [ ] Settings open, and Settings → Appearance shows **Ambience** and **Glass** options
- [ ] All text uses the same rounded geometric font (Manrope)
- [ ] All icons are thin line icons (Lucide), with no filled "Material" icons
- [ ] The soft background glow changes colour to suit the focused artwork, using only Plezzant colours
- [ ] Glass surfaces (navigation rail, menus, player panels) look translucent but readable
- [ ] Performance: moving around feels quick, with no stutter

### New in 1.8.0

- [ ] Rest on a movie/show for ~4 s: its trailer plays **with sound**; after 3 s all the menus, text and cards fade away; any remote press brings them back (and they fade again when you stop pressing)
- [ ] Settings → Appearance → *Trailer Sound* off: previews play silently
- [ ] All text is Inter
- [ ] The Home chip, hero buttons and detail buttons are flat colour pills in a hue that complements the lower-left of the screen; the focused one is a near-white wash of that hue
- [ ] There is clearly more space between a shelf's title and its cards
- [ ] The sidebar's *Watchlist* section shows only your watchlist: no Trending/Popular/Recommended rows and no search
- [ ] An AVI file (or an old Xvid/WMV file) from Plex starts as a server stream and plays smoothly

### New in 1.7.0

- [ ] Home and detail pages: the blur matches the backdrop's left edge and bottom; the backdrop always sits top-right
- [ ] Rest on a movie/show **and** on a Continue Watching episode for ~4 s: the trailer plays silently (episodes show their series' trailer); Play/Pause opens it with sound
- [ ] With Card Style = Posters, every episode (Continue Watching, playlists, collections, search, season rows) is still a 16:9 still
- [ ] The clock appears once (top right), not also in the menu
- [ ] The menu shows Downloads only when something is downloaded; Settings shows Services only once Trakt/MAL/Seerr is connected
- [ ] The detail page's back button, Play and round buttons share the Home chip's glass look; a cast member without a photo shows a soft frosted tile

### New in 1.6.0

- [ ] Home and every movie/show page sit on a soft UltraBlur in the artwork's colours; the backdrop fills the top-right corner and melts into it, and the colours glide as you move between titles
- [ ] The top-left *Home* chip, the hero's *Play / Go to …* pill and the *Watch Trailer* hint look like frosted glass with a bright top edge
- [ ] Title logos on Home are large and sit right on the details line
- [ ] Settings, its pickers, long-press menus, the player's ⚙ menu and the library tabs use the same text size as Home — nothing reads a size up
- [ ] Settings shows only everyday options: no Player / backend / mpv / buffer group, no shaders, no debug overlays or logs; long-press menus have no Edit, File Info, External Player, Download or Delete
- [ ] Movie and show pages have no Download button
- [ ] On an entry-level Google TV (2 GB), focus still animates smoothly, the sidebar slides, and trailer previews play

### New in 1.5.0

- [ ] From deep inside a library grid, one press of **Back** opens the menu, already on that library
- [ ] The menu lists every library straight away (no "Libraries" fold) and has no "Hidden" section
- [ ] Settings → Manage Libraries → a hidden library's ⋮ menu → *Open Library* opens it
- [ ] Settings → Appearance → *Card Style*: switch between *Landscape 16:9* and *Posters 2:3* — Home rows and library grids follow
- [ ] On Home, rest on a movie that has a trailer for ~4 seconds: the trailer plays silently behind the title and a *Watch Trailer* hint appears; press **Play/Pause** to watch it with sound; move away and the picture comes back
- [ ] Settings → Appearance → *Hide Spoilers* on: unwatched episodes are blurred but each says which episode it is (e.g. "S1 E3")
- [ ] Landscape library grids show four cards across with even gaps

### New in 1.4.0

- [ ] Theme music: open a show or movie with a theme (Plex) — it fades in quietly, and stops when you press Play or go back
- [ ] Cinema trailers: Settings → Playback → *Cinema Trailers* = 1, then play an unwatched movie from the start — a trailer plays first and the movie follows
- [ ] Photos: open a photo library, then an album; *Slideshow* runs full-screen; LEFT/RIGHT step through photos; SELECT pauses; BACK closes
- [ ] Voice: hold the remote's Assistant button and say "search for *a title* on Plezzant" — Search opens with the words filled in
- [ ] Screensaver: TV Settings → System → Ambient mode / Screen saver → *Plezzant*; let the TV idle — your library's backdrops cross-fade with titles
- [ ] Collections, playlists, photo albums, a cast member's page and a row's "View all" all look alike: artwork on the left, big title, a line of details, round action buttons, the small back arrow top-left
- [ ] Every grid lines up with the page title on the left and ends the same distance from the right edge
- [ ] Cast pictures on a movie page are round; playlists are square
- [ ] Filters / Sort / grouping menus open right next to the button you pressed
- [ ] Settings pickers (e.g. Default Quality) mark the current choice with a tick on the right, like the player's Audio & Subtitles menu
- [ ] In the player, press DOWN: the chapter strip's cards get the same white outline as cards elsewhere

## How to check that the app runs smoothly

1. Open **Settings → Advanced** and turn on **Frame timing graph**.
2. Two small graphs appear in the top-right corner. The top one is the
   interface (UI), the bottom one is drawing (raster).
3. Move around Home, open and close the sidebar, and scroll the shelves.
4. Green bars below the line are good. Red bars poking above the line are
   dropped frames, meaning the screen stuttered.
5. If you see lots of red, open **Settings → Appearance** and set
   **Glass surfaces** to **Solid (reduce transparency)**, or set
   **Visual effects** to **Reduced**. Then try again.
6. Tell Claude your TV model and what you saw. A photo of the graphs helps.
7. Turn **Frame timing graph** off again when you're done.

## How to check the playback mode

1. Start playing anything.
2. Press **OK** (or **Down**) on the remote to show the player controls.
3. In the bottom-right control row, select the **sliders icon** (three horizontal lines
   with knobs) and press **OK**. The **Video Settings** panel opens.
4. Scroll to **Performance Overlay** and switch it **ON**. A small card appears in the
   top-left corner of the video.
5. The first section, **Playback**, shows one of:

| Shown | What it means |
|---|---|
| **Direct Play** | The TV plays the original file exactly as stored. Best quality, almost no server work. Plezzant always prefers this. |
| **Direct Stream** | The server re-packages the video into a TV-friendly stream **without re-encoding the picture** (for example, to burn in a subtitle or change the audio). Quality is unchanged and the server's work is light. |
| **Transcode** | The server re-encodes the video, usually because you chose a lower quality or the TV can't decode the original. Uses lots of server CPU and lowers quality. |

The same card also shows the video codec, resolution, decoder (hardware or
software), bitrate and buffer. These are useful when something stutters.

## If it breaks

**Capture the log (Logcat) with ADB** while reproducing the problem:

```powershell
.\adb.exe logcat -c
.\adb.exe logcat -v time > plezzant-log.txt
```
Now reproduce the problem on the TV. Then press **Ctrl+C** in PowerShell to stop.
The file `plezzant-log.txt` is in `C:\platform-tools`.

**Only the crash:**

```powershell
.\adb.exe logcat -b crash -d > plezzant-crash.txt
```

**Plezzant's own log (no PC needed):** **Settings → Advanced → View Logs**. Use
**Copy logs** to copy it, or read the latest lines on screen.

**Screenshot:**

```powershell
.\adb.exe exec-out screencap -p > plezzant-screen.png
```
(Emulator: click the **camera 📷** button on its side toolbar.)

**Screen recording** (up to 3 minutes; press Ctrl+C to stop early):

```powershell
.\adb.exe shell screenrecord /sdcard/plezzant.mp4
.\adb.exe pull /sdcard/plezzant.mp4
```

**What to send back for debugging:**
1. What you did, step by step, and what you expected instead.
2. `plezzant-log.txt` (or the copied in-app log).
3. `plezzant-crash.txt` if the app closed by itself.
4. A screenshot or recording of the problem.
5. The build you used: the date/time of the GitHub Actions run, or the commit shown in
   **Settings → About**.
6. Your TV model, and for playback problems the **Performance Overlay** values
   (Playback, codec, resolution, decoder).

---

## If you only want to see Plezzant running as quickly as possible, do these five things:

1. **Download the app:** open
   https://github.com/myplexscripts/plezy/actions/workflows/plezzant-android.yml, click the
   top run with a green ✓, scroll to **Artifacts**, click **plezzant-apks**, then
   right-click the downloaded zip → **Extract All…** → **Extract**.
2. **Install Android Studio:** download it from https://developer.android.com/studio,
   run the installer clicking **Next** each time, open it, choose **Standard** setup,
   accept all licences, and click **Finish**.
3. **Create the TV:** on the welcome screen click **More Actions → Virtual Device
   Manager → +**, choose **TV → Television (1080p) → Next**, download and select
   **API 34 Google TV x86_64**, click **Next → Finish**, then press **▶** next to it
   and wait for the TV home screen.
4. **Install Plezzant:** drag `plezzant-x86_64.apk` from the extracted folder onto the
   emulator window.
5. **Open it:** in the emulator's Apps row, select **Plezzant** with the arrow keys and
   press **Enter**, then sign in at https://plex.tv/link with the code shown.
