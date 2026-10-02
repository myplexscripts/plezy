import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/music/music_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Instant Mix renders a distinct icon and runs its callback when the server supports it', (tester) async {
    var mixes = 0;

    await tester.pumpWidget(_wrap(buildMusicActions(onPlay: () {}, onShuffle: () {}, onInstantMix: () => mixes++)));

    final instantMix = find.byIcon(LucideIcons.wandSparkles);
    expect(instantMix, findsOneWidget);
    expect(
      find.ancestor(of: instantMix, matching: find.byTooltip(t.music.instantMix)),
      findsOneWidget,
      reason: 'the icon is the only affordance on TV, so it must carry the Instant Mix tooltip',
    );

    // #1629: the fader glyph reads as an equalizer in a music context, and is
    // the vertical twin of the video player's settings icon.
    expect(find.byIcon(LucideIcons.disc), findsNothing);
    expect(find.byIcon(LucideIcons.slidersHorizontal), findsNothing);
    // It must also stay distinguishable from the shuffle button beside it.
    expect(find.byIcon(LucideIcons.shuffle), findsOneWidget);

    await tester.tap(instantMix);
    await tester.pump();

    expect(mixes, 1);
  });

  testWidgets('Instant Mix is absent when the server lacks the capability', (tester) async {
    await tester.pumpWidget(_wrap(buildMusicActions(onPlay: () {}, onShuffle: () {})));

    expect(find.byIcon(LucideIcons.wandSparkles), findsNothing);
    expect(find.byTooltip(t.music.instantMix), findsNothing);
    expect(find.byIcon(LucideIcons.shuffle), findsOneWidget);
    expect(find.text(t.common.play), findsOneWidget);
  });
}

Widget _wrap(List<FocusableAction> actions) {
  return TranslationProvider(
    child: MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(
        body: Center(child: FocusableActionBar(actions: actions)),
      ),
    ),
  );
}
