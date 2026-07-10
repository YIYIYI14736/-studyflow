import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/main.dart';

void main() {
  testWidgets('App renders edge-to-edge with a theme-colored bottom inset',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('StudyFlow'), findsOneWidget);

    final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(
      regions.any(
        (region) =>
            region.value.systemNavigationBarColor == Colors.transparent &&
            region.value.systemNavigationBarContrastEnforced == false,
      ),
      isTrue,
    );

    final navigationBar = find.byType(BottomNavigationBar);
    final surfaceColor =
        Theme.of(tester.element(navigationBar)).colorScheme.surface;
    final background = find.ancestor(
      of: navigationBar,
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == surfaceColor,
      ),
    );
    expect(background, findsOneWidget);

    final safeArea = find.descendant(
      of: background,
      matching: find.byType(SafeArea),
    );
    expect(safeArea, findsOneWidget);
    expect(tester.widget<SafeArea>(safeArea).top, isFalse);
  });
}
