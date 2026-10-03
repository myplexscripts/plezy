// Visual regression tests for the TV layout, rendered at the canvas a Google TV
// really uses: a 1080p panel laid out at 960x540 logical pixels (dpr 2).
//
// They catch spacing, clipping, type-size and hierarchy regressions in the
// tvOS-style layout. After an intentional visual change, regenerate with:
//   flutter test --update-goldens test/tv_layout
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/profile/profile_switch_screen.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/plezzant/plezzant_tokens.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/settings_page.dart';
import 'package:plezy/widgets/settings_section.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:plezy/widgets/system_clock.dart';
import 'package:plezy/widgets/tv_reference_scale.dart';
import 'package:plezy/widgets/tv_spotlight_background.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

final _goldenKey = GlobalKey();

/// TV logical canvas (960x540) at the TV's 2x density.
const _physical = Size(1920, 1080);
const _dpr = 2.0;

/// The sidebar header shows the time; pin it so the image is stable.
final _fixedNow = DateTime(2026, 10, 3, 20, 30);

Future<void> _loadFonts() async {
  Future<ByteData> file(String path) async => ByteData.sublistView(await File(path).readAsBytes());
  final manrope = FontLoader('Manrope');
  for (final w in [300, 400, 500, 600, 700, 800]) {
    manrope.addFont(file('assets/fonts/Manrope-$w.ttf'));
  }
  await manrope.load();

  // Resolve the icon font through the package config, wherever pub put it.
  final config = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map<String, dynamic>;
  final lucide = (config['packages'] as List).cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'lucide_icons_flutter',
  );
  final root = Uri.parse(lucide['rootUri'] as String);
  final rootDir = root.isAbsolute ? root.toFilePath() : File('.dart_tool/${root.path}').absolute.path;
  await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(file('$rootDir/assets/lucide.ttf'))).load();

  // Some metadata uses the platform default family, as Android TV does.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold']) {
      roboto.addFont(file('$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-$w.ttf'));
    }
    await roboto.load();
  }
}

/// Text antialiasing can differ by a hair between machines; a layout
/// regression moves far more than 0.5% of the pixels.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= 0.005) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

Future<void> _useTvCanvas(WidgetTester tester) async {
  await SettingsService.getInstance();
  tester.view.physicalSize = _physical;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
}

/// A calm artwork stand-in so glass and scrims have something to sit on.
Widget _backdrop() => const DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B2A5C), Color(0xFF3A4FA0), Color(0xFF0B0F1E)],
    ),
  ),
  child: SizedBox.expand(),
);

Future<void> _pumpGolden(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: monoTheme(dark: true),
        // Inside a Scaffold like every app route, so text gets Material defaults.
        home: RepaintBoundary(
          key: _goldenKey,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  // Fixed time, not pumpAndSettle: ambience and cycling artwork keep
  // animating, so the tree never settles.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    await initializeDateFormatting('en');
    goldenFileComparator = _TolerantComparator(Uri.parse('test/tv_layout/tv_layout_golden_test.dart'));
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(true);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('open sidebar floats over full-bleed content on the safe frame', (tester) async {
    await _useTvCanvas(tester);
    final libraries = LibrariesProvider();
    addTearDown(libraries.dispose);
    final hidden = HiddenLibrariesProvider();
    await hidden.ensureInitialized();
    addTearDown(hidden.dispose);
    final multiServer = testMultiServerProvider(MultiServerManager());
    addTearDown(multiServer.dispose);

    SystemClock.debugNowOverride = () => _fixedNow;
    addTearDown(() => SystemClock.debugNowOverride = null);
    await _pumpGolden(
      tester,
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LibrariesProvider>.value(value: libraries),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hidden),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
        ],
        child: Builder(
          builder: (context) {
            final scale = PlezzantTv.scaleOf(context);
            return Stack(
              children: [
                _backdrop(),
                Positioned(
                  top: PlezzantTv.sidebarInset * scale,
                  bottom: PlezzantTv.sidebarInset * scale,
                  left: PlezzantTv.sidebarInset * scale,
                  child: TvReferenceScale(
                    child: SideNavigationRail(
                      selectedTab: NavigationTabId.discover,
                      isSidebarFocused: true,
                      alwaysExpanded: true,
                      onDestinationSelected: (_) {},
                      onLibrarySelected: (_) {},
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    // 336 reference units on a 540-tall canvas.
    final rail = find.descendant(of: find.byType(SideNavigationRail), matching: find.byType(AnimatedContainer)).first;
    expect(tester.getRect(rail).width, closeTo(PlezzantTv.sidebarWidth / 2, 0.5));
    await expectLater(find.byKey(_goldenKey), matchesGoldenFile('goldens/tv_sidebar_open.png'));
  });

  testWidgets('home hero copy sits on the safe frame with the white action pill', (tester) async {
    await _useTvCanvas(tester);
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Harbor Lights',
      summary: 'A small fishing town keeps its secrets until a container ship runs aground in the harbour.',
      year: 2024,
      contentRating: 'TV-14',
    );

    await _pumpGolden(
      tester,
      Builder(
        builder: (context) {
          final scale = PlezzantTv.scaleOf(context);
          return Stack(
            children: [
              _backdrop(),
              Positioned.fill(
                child: TvSpotlightBackground(
                  item: item,
                  client: null,
                  allowNetwork: false,
                  contentTop: PlezzantTv.safeY * scale,
                  contentLeft: PlezzantTv.safeX * scale,
                  contentBottom: 270,
                  actionLabel: t.common.play,
                  actionIcon: LucideIcons.play,
                ),
              ),
            ],
          );
        },
      ),
    );

    expect(tester.getTopLeft(find.text(t.common.play)).dx, greaterThan(PlezzantTv.safeX / 2));
    await expectLater(find.byKey(_goldenKey), matchesGoldenFile('goldens/tv_home_hero.png'));
  });

  testWidgets('profile picker fills the screen with centred avatars', (tester) async {
    await _useTvCanvas(tester);
    final profiles = [
      Profile.local(id: 'a', displayName: 'David', createdAt: DateTime(2026)),
      Profile.local(id: 'b', displayName: 'Guest', createdAt: DateTime(2026)),
    ];

    await _pumpGolden(
      tester,
      TvWhoIsWatching(
        profiles: profiles,
        avatarUrlFor: (_) => null,
        focusNodeFor: (_) => FocusNode(),
        onSelect: (_) async {},
        onAdd: () async {},
      ),
    );

    expect(tester.getSize(find.byType(TvWhoIsWatching)).width, 960);
    await expectLater(find.byKey(_goldenKey), matchesGoldenFile('goldens/tv_profile_picker.png'));
  });

  testWidgets('settings pages use a centred tvOS column under a large title', (tester) async {
    await _useTvCanvas(tester);
    await _pumpGolden(
      tester,
      SettingsPage(
        title: const Text('General'),
        children: [
          const SettingsSectionHeader('Language & Region'),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.languages),
                title: const Text('Language'),
                subtitle: const Text('English'),
                onTap: () {},
              ),
            ],
          ),
          const SettingsSectionHeader('Startup'),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.play),
                title: const Text('Startup Section'),
                subtitle: const Text('Home'),
                onTap: () {},
              ),
              SwitchListTile(
                secondary: const Icon(LucideIcons.tv),
                title: const Text('Force TV mode'),
                subtitle: const Text('Force TV layout. For devices that don’t auto-detect.'),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ],
      ),
    );

    // The column stays inside the 80-unit safe frame (40 logical px here).
    expect(tester.getTopLeft(find.text('Language')).dx, greaterThan(PlezzantTv.safeX / 2));
    await expectLater(find.byKey(_goldenKey), matchesGoldenFile('goldens/tv_settings_page.png'));
  });
}
