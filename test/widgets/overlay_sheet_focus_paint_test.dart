import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/bottom_sheet_page_scaffold.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

void main() {
  testWidgets('a d-pad opened sheet paints its first row as focused', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    final openNode = FocusNode();
    addTearDown(openNode.dispose);
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: OverlaySheetHost(
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    focusNode: openNode,
                    autofocus: true,
                    onPressed: () => OverlaySheetController.of(context).show<void>(
                      builder: (_) => BottomSheetPageScaffold(
                        title: 'Sheet',
                        icon: Icons.tune,
                        showHeaderBorder: false,
                        showHeaderDivider: true,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (var i = 0; i < 3; i++) FocusableListTile(title: Text('Row $i'), onTap: () {}),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    openNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final row0 = find.text('Row 0');
    expect(Focus.of(tester.element(row0)).hasPrimaryFocus, isTrue);
    final ink = Material.of(tester.element(row0));
    // ignore: invalid_use_of_visible_for_testing_member
    final features = (ink as dynamic).debugInkFeatures as List?;
    expect(features, isNotNull);
    expect(features, isNotEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Row 1'))).hasPrimaryFocus, isTrue);
  });
}
