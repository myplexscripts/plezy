import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';

void main() {
  testWidgets('back arrow aligns with regular leading icons', (tester) async {
    var backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BottomSheetHeader(title: 'Back', onBack: () => backPressed = true),
              const BottomSheetHeader(title: 'Icon', icon: LucideIcons.funnel),
            ],
          ),
        ),
      ),
    );

    final backArrow = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft);
    final regularIcon = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == LucideIcons.funnel);

    expect(backArrow, findsOneWidget);
    expect(regularIcon, findsOneWidget);
    expect(tester.getTopLeft(backArrow).dx, tester.getTopLeft(regularIcon).dx);
    expect(tester.getTopLeft(find.text('Back')).dx, tester.getTopLeft(find.text('Icon')).dx);

    await tester.tapAt(tester.getCenter(backArrow) + const Offset(20, 0));
    expect(backPressed, isTrue);
  });

  testWidgets('back button hover highlight is centered on the arrow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomSheetHeader(title: 'Back', onBack: () {}),
        ),
      ),
    );

    final backArrow = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft);
    // The circular hover/press highlight of an InkResponse is centered on its
    // reference box, so the box itself must be centered on the arrow glyph.
    final backTarget = find.byType(InkResponse);

    expect(backTarget, findsOneWidget);
    expect(tester.getCenter(backTarget), tester.getCenter(backArrow));
  });
}
