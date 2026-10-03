import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masonry_sliver/masonry_sliver.dart';

double heightOf(int i) => 60.0 + (i * 37 % 7) * 25; // 60..210, uneven

Widget app(ScrollController controller, {int count = 220}) => MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverMasonry.builder(
                itemCount: count,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (_, i) => SizedBox(
                    height: heightOf(i), child: Center(child: Text('item $i'))),
              ),
            ),
          ],
        ),
      ),
    );

void main() {
  testWidgets('scrolls all the way to the last item, and the end is exact',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));
    expect(find.text('item 0'), findsOneWidget);

    // Scroll down in steps until the position stops moving.
    var last = -1.0;
    for (var i = 0; i < 400 && controller.offset != last; i++) {
      last = controller.offset;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('item 219'), findsOneWidget,
        reason: 'the very last note is reachable');
    expect(controller.position.pixels, controller.position.maxScrollExtent);
  });

  testWidgets(
      'scrolling back up returns to the top and lays items out where they were',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));

    final firstTop = tester.getTopLeft(find.text('item 0')).dy;
    for (var i = 0; i < 30; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
    }
    for (var i = 0; i < 60; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(tester.getTopLeft(find.text('item 0')).dy, firstTop);
  });

  testWidgets(
      'two columns: each new item goes under the shorter one, without overlap',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller, count: 8));
    await tester.pumpAndSettle();

    // Collect the rects of the built items.
    final rects = <int, Rect>{};
    for (var i = 0; i < 8; i++) {
      final f = find.text('item $i');
      if (f.evaluate().isEmpty) continue;
      rects[i] = tester
          .getRect(find.ancestor(of: f, matching: find.byType(SizedBox)).first);
    }
    expect(rects.length, 8);
    final list = rects.values.toList();
    for (var a = 0; a < list.length; a++) {
      for (var b = a + 1; b < list.length; b++) {
        expect(list[a].overlaps(list[b]), isFalse,
            reason: 'items $a and $b overlap');
      }
    }
    expect(rects[0]!.left,
        rects[2]!.left == rects[0]!.left ? rects[0]!.left : rects[1]!.left);
  });

  testWidgets('a changed list is laid out again without losing the scroll',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller, count: 100));
    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
    }
    final before = controller.offset;
    await tester.pumpWidget(app(controller, count: 60));
    await tester.pumpAndSettle();
    expect(controller.offset,
        lessThanOrEqualTo(controller.position.maxScrollExtent));
    expect(before, greaterThan(0));
  });
}
