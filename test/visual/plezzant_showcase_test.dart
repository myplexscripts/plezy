// Visual QA renders of the Plezzant design system at TV resolution.
//
// Off by default. Render with:
//   PLEZZANT_SHOWCASE=/path/to/artwork/dir flutter test test/visual/plezzant_showcase_test.dart
// The directory must contain backdrop.jpg and poster0.jpg … poster6.jpg; PNGs
// are written to <dir>/out/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/plezzant/artwork_color_extractor.dart';
import 'package:plezy/theme/plezzant/plezzant_ambience.dart';
import 'package:plezy/theme/plezzant/plezzant_ambient_glow.dart';
import 'package:plezy/theme/plezzant/plezzant_glass.dart';
import 'package:plezy/theme/plezzant/plezzant_palette.dart';
import 'package:plezy/theme/plezzant/plezzant_tokens.dart';
import 'package:plezy/theme/plezzant/plezzant_typography.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/media_progress_bar.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

final String? _artDir = Platform.environment['PLEZZANT_SHOWCASE'];

Future<void> _loadFonts() async {
  Future<ByteData> file(String path) async => ByteData.sublistView(await File(path).readAsBytes());
  final manrope = FontLoader('Inter');
  for (final w in [300, 400, 500, 600, 700, 800]) {
    manrope.addFont(file('assets/fonts/Inter-$w.ttf'));
  }
  await manrope.load();
  final pubCache = Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache';
  final lucideDir = Directory(
    '$pubCache/hosted/pub.dev',
  ).listSync().whereType<Directory>().firstWhere((d) => d.path.contains('lucide_icons_flutter-'));
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(file('${lucideDir.path}/assets/lucide.ttf'));
  await lucide.load();
}

final Map<String, ui.Image> _images = {};

Future<void> _preloadImages() async {
  for (final name in ['backdrop', for (var i = 0; i < 7; i++) 'poster$i']) {
    final codec = await ui.instantiateImageCodec(await File('$_artDir/$name.jpg').readAsBytes());
    _images[name] = (await codec.getNextFrame()).image;
  }
}

Widget _art(String name, {BoxFit fit = BoxFit.cover}) => RawImage(image: _images[name], fit: fit);

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = Directory('$_artDir/out')..createSync(recursive: true);
    File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _frame(GlobalKey key, Widget child) => RepaintBoundary(
  key: key,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: monoTheme(dark: true, oled: true),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(1920, 1080)),
      child: Scaffold(body: child),
    ),
  ),
);

class _RailItem {
  final IconData icon;
  final String label;
  final bool selected;
  const _RailItem(this.icon, this.label, {this.selected = false});
}

Widget _rail() {
  const items = [
    _RailItem(LucideIcons.search, 'Search'),
    _RailItem(LucideIcons.house, 'Home', selected: true),
    _RailItem(LucideIcons.libraryBig, 'Libraries'),
    _RailItem(LucideIcons.radioTower, 'Live TV'),
    _RailItem(LucideIcons.music, 'Music'),
    _RailItem(LucideIcons.settings, 'Settings'),
  ];
  return SizedBox(
    width: PlezzantTv.sidebarWidth,
    child: PlezzantGlass(
      style: PlezzantGlassStyle.panel,
      borderRadius: BorderRadius.circular(PlezzantTv.navPanelRadius),
      padding: const EdgeInsets.all(PlezzantTv.sidebarHorizontalPadding),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8DED4)),
                  alignment: Alignment.center,
                  child: const AppIcon(LucideIcons.user, size: 19, color: Color(0xFF332A28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'David',
                    style: PlezzantTvType.navigationSecondary.copyWith(
                      color: PlezzantNeutrals.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '11:01',
                  style: PlezzantTvType.navigationSecondary.copyWith(
                    color: PlezzantNeutrals.textSecondary,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (final item in items)
              Container(
                height: PlezzantTv.navRowHeight,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: item.selected ? Colors.white : null,
                  borderRadius: BorderRadius.circular(PlezzantRadius.pill),
                ),
                child: Row(
                  children: [
                    AppIcon(item.icon, size: 22, color: item.selected ? Colors.black : PlezzantNeutrals.textSecondary),
                    const SizedBox(width: 14),
                    Text(
                      item.label,
                      style: (item.selected ? PlezzantTvType.navigationSelected : PlezzantTvType.navigation).copyWith(
                        color: item.selected ? Colors.black : PlezzantNeutrals.text,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            Text(
              'LIBRARIES',
              style: PlezzantTvType.navigationSecondary.copyWith(
                color: PlezzantNeutrals.textSecondary.withValues(alpha: 0.72),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 12),
            for (final label in const ['Movies', 'TV Shows', 'Music'])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(
                  label,
                  style: PlezzantTvType.navigationSecondary.copyWith(color: PlezzantNeutrals.textSecondary),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Mirrors TvSpotlightBackground's layering (artwork, horizontal scrim,
/// ambient glow, vertical fade, info block) with pre-decoded artwork.
Widget _hero(String title, String summary) => Builder(
  builder: (context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        _art('backdrop'),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bg.withValues(alpha: 0.62), bg.withValues(alpha: 0.12), Colors.transparent],
              stops: const [0.0, 0.46, 1.0],
            ),
          ),
        ),
        const PlezzantAmbientGlow(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.20), Colors.transparent, bg.withValues(alpha: 0.72)],
              stops: const [0.0, 0.46, 1.0],
            ),
          ),
        ),
        Positioned(
          left: PlezzantTv.sidebarInset + PlezzantTv.sidebarWidth + PlezzantSpace.lg,
          width: PlezzantTv.heroTextWidth,
          bottom: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PlezzantTvType.hero.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              Text(
                'Movie  ·  8.1  ·  PG-13  ·  2h 8m  ·  2025',
                style: PlezzantTvType.metadata.copyWith(color: Colors.white.withValues(alpha: 0.88)),
              ),
              const SizedBox(height: 16),
              Text(
                summary,
                maxLines: 3,
                style: PlezzantTvType.body.copyWith(color: Colors.white.withValues(alpha: 0.82)),
              ),
              const SizedBox(height: 22),
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(29)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(LucideIcons.play, size: 22, color: Colors.black),
                    const SizedBox(width: 10),
                    Text('Play', style: PlezzantTvType.navigationSelected.copyWith(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  },
);

Widget _poster(int i, {bool focused = false, double? progress}) {
  return Builder(
    builder: (context) {
      final card = ClipRRect(
        borderRadius: PlezzantRadius.cardAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _art('poster$i', fit: BoxFit.cover),
            if (progress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MediaProgressBar(viewOffset: (progress * 1000).round(), duration: 1000),
              ),
          ],
        ),
      );
      final glow = FocusTheme.getFocusGlowColor(context);
      final content = Container(
        width: 308,
        height: 173,
        decoration: focused
            ? BoxDecoration(
                borderRadius: PlezzantRadius.cardAll,
                border: Border.all(color: FocusTheme.getFocusBorderColor(context), width: FocusTheme.focusBorderWidth),
                boxShadow: FocusTheme.focusGlowShadows(glow),
              )
            : null,
        child: card,
      );
      return Transform.translate(
        offset: focused ? const Offset(0, -6) : Offset.zero,
        child: Transform.scale(scale: focused ? PlezzantFocus.cardScale : 1, child: content),
      );
    },
  );
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });

  testWidgets('home spotlight with palette ambience, glass rail and focus', skip: _artDir == null, (tester) async {
    await tester.runAsync(_loadFonts);
    await tester.runAsync(_preloadImages);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final match = await tester.runAsync(
      () => ArtworkColorExtractor.instance.extract('showcase', FileImage(File('$_artDir/backdrop.jpg'))),
    );
    PlezzantAmbience.instance.setMatch('showcase', match);
    // ignore: avoid_print
    print('Backdrop ambience: $match');

    final item = testMediaItem(
      id: 'showcase',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'The Long Horizon',
      summary:
          'When the last ferry leaves the archipelago, a lighthouse keeper and a stranded cartographer chart '
          'the coast by memory before the winter storms erase it for good.',
      year: 2025,
      contentRating: 'PG-13',
      durationMs: 128 * 60 * 1000,
      artPath: '/library/metadata/1/art',
      backdropPaths: const ['/library/metadata/1/art'],
      thumbPath: '/library/metadata/1/thumb',
    );

    final key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key,
        Stack(
          fit: StackFit.expand,
          children: [
            _hero(item.title!, item.summary!),
            Positioned(
              left: PlezzantTv.sidebarInset,
              top: PlezzantTv.sidebarInset,
              bottom: PlezzantTv.sidebarInset,
              child: _rail(),
            ),
            Positioned(
              left: PlezzantTv.sidebarInset + PlezzantTv.sidebarWidth + PlezzantSpace.lg,
              right: PlezzantTv.safeX,
              bottom: PlezzantTv.safeY,
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue Watching', style: PlezzantTvType.shelfTitle.copyWith(color: Colors.white)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 205,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < 5; i++) ...[
                            _poster(i, focused: i == 1, progress: i < 4 ? 0.2 + i * 0.18 : null),
                            const SizedBox(width: PlezzantTv.homeCardGap),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // ignore: avoid_print
    print('pumped');
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    // ignore: avoid_print
    print('settled');
    await _capture(tester, key, 'home');
  });

  testWidgets('player chrome on glass with playback method overlay', skip: _artDir == null, (tester) async {
    await tester.runAsync(_loadFonts);
    await tester.runAsync(_preloadImages);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final match = await tester.runAsync(
      () => ArtworkColorExtractor.instance.extract('showcase', FileImage(File('$_artDir/backdrop.jpg'))),
    );
    PlezzantAmbience.instance.setMatch('showcase', match);

    final key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key,
        Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            final accent = PlezzantAmbience.instance.accent(PlezzantShade.lighter);
            Widget button(IconData icon, {bool focused = false, double size = 26}) => Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: focused ? Colors.white.withValues(alpha: 0.2) : null,
              ),
              child: Center(
                child: AppIcon(icon, size: size, color: Colors.white),
              ),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                _art('backdrop'),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Colors.transparent, Colors.transparent, Color(0xB3000000)],
                      stops: [0, 0.22, 0.6, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 48,
                  top: 40,
                  child: Row(
                    children: [
                      const AppIcon(LucideIcons.arrowLeft, color: Colors.white, size: 26),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('The Long Horizon', style: text.headlineSmall),
                          Text('2025 · 2h 8m', style: text.bodyMedium?.copyWith(color: PlezzantNeutrals.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 48,
                  top: 150,
                  child: PlezzantGlass(
                    style: PlezzantGlassStyle.overlay,
                    borderRadius: PlezzantRadius.controlAll,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIcon(LucideIcons.radio, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Playback', style: text.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Method: Direct Play', style: text.bodySmall?.copyWith(color: Colors.white)),
                        Text('Codec: HEVC Main 10 · 3840×2160', style: text.bodySmall?.copyWith(color: Colors.white)),
                        Text('Decoder: Hardware', style: text.bodySmall?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: 28,
                  child: PlezzantGlass(
                    style: PlezzantGlassStyle.overlay,
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('47:12', style: text.labelLarge),
                            const SizedBox(width: 18),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: [
                                    Container(height: 8, color: Colors.white.withValues(alpha: 0.18)),
                                    FractionallySizedBox(widthFactor: 0.37, child: Container(height: 8, color: accent)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Text('-1:20:48', style: text.labelLarge?.copyWith(color: PlezzantNeutrals.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            button(LucideIcons.skipBack),
                            button(LucideIcons.rotateCcw),
                            button(LucideIcons.pause, focused: true, size: 30),
                            button(LucideIcons.rotateCw),
                            button(LucideIcons.skipForward),
                            const Spacer(),
                            button(LucideIcons.listVideo),
                            button(LucideIcons.captions),
                            button(LucideIcons.audioLines),
                            button(LucideIcons.slidersHorizontal),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const PlezzantAmbientGlow(strength: 0.6),
              ],
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await _capture(tester, key, 'player');
  });

  testWidgets('palette and type specimen', skip: _artDir == null, (tester) async {
    await tester.runAsync(_loadFonts);
    await tester.runAsync(_preloadImages);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key,
        Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plezzant', style: text.displayLarge),
                  Text('Headline · Inter 700', style: text.headlineMedium),
                  Text('Title large · shelf headers', style: text.titleLarge),
                  Text(
                    'Body large: a lighthouse keeper and a stranded cartographer chart the coast by memory.',
                    style: text.bodyLarge,
                  ),
                  Text('Body small · metadata · 14 px floor', style: text.bodySmall),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final hue in PlezzantPalette.all)
                        Column(
                          children: [
                            for (final shade in PlezzantShade.values)
                              Container(width: 56, height: 36, color: hue.shade(shade)),
                            SizedBox(
                              width: 56,
                              child: Text(hue.name, style: text.labelSmall, maxLines: 2, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await _capture(tester, key, 'specimen');
  });
}
