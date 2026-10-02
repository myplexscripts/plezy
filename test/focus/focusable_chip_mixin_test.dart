import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_chip_mixin.dart';

class _ProbeChip extends StatefulWidget {
  final FocusNode focusNode;

  const _ProbeChip({super.key, required this.focusNode});

  @override
  State<_ProbeChip> createState() => _ProbeChipState();
}

class _ProbeChipState extends State<_ProbeChip> with FocusableChipStateMixin<_ProbeChip> {
  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  String get debugLabel => 'probe';

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: focusNode, child: Text(isFocused ? 'focused' : 'idle'));
  }
}

void main() {
  testWidgets('a chip rebuilt around an already focused node reports focus', (tester) async {
    final node = FocusNode(debugLabel: 'shared');
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _ProbeChip(key: const ValueKey('a'), focusNode: node),
      ),
    );
    node.requestFocus();
    await tester.pump();
    expect(find.text('focused'), findsOneWidget);

    // A new State (e.g. its header was rebuilt) adopts the focused node
    // without any focus-change event; it must not render as unfocused.
    await tester.pumpWidget(
      MaterialApp(
        home: _ProbeChip(key: const ValueKey('b'), focusNode: node),
      ),
    );
    expect(node.hasFocus, isTrue);
    expect(find.text('focused'), findsOneWidget);
  });
}
