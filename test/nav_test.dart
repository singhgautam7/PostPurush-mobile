import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postpurush/app/nav_bar.dart';
import 'package:postpurush/core/theme/app_theme.dart';
import 'package:postpurush/core/theme/palette.dart';
import 'package:postpurush/core/theme/tokens.dart';

Widget _host(Widget child, {Size size = const Size(393, 851)}) => MaterialApp(
  theme: AppTheme.of(ThemeFamily.postpurush, Tone.light),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: size.width, child: Center(child: child)),
    ),
  ),
);

void main() {
  group('NavPill', () {
    testWidgets('hugs its content rather than spanning the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(NavPill(index: 0, onSelect: (int _) {})),
      );
      await tester.pumpAndSettle();

      final Size pill = tester.getSize(find.byType(NavPill));
      expect(pill.height, NavSpec.height);
      // The whole point of the change: it is one object sitting in the middle,
      // not four destinations marooned at the screen's corners.
      expect(pill.width, lessThan(393));
      expect(pill.width, greaterThan(NavSpec.item * 4));
    });

    testWidgets('only the selected destination shows its label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(NavPill(index: 1, onSelect: (int _) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Collections'), findsNothing);
      expect(find.text('Search'), findsNothing);
      expect(find.text('More'), findsNothing);
      // Every destination keeps its glyph, labelled or not.
      for (final NavDestination d in kDestinations) {
        expect(find.byIcon(d.icon), findsOneWidget);
      }
    });

    testWidgets('the selected destination is wider than an unselected one', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(NavPill(index: 0, onSelect: (int _) {})));
      await tester.pumpAndSettle();

      // Comparing two items in one pump, rather than two pumps: across pumps
      // the indicator is still animating and the widths are meaningless.
      final double selected = tester
          .getSize(
            find.ancestor(
              of: find.byIcon(kDestinations[0].icon),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .width;
      final double unselected = tester
          .getSize(
            find.ancestor(
              of: find.byIcon(kDestinations[2].icon),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .width;

      expect(unselected, NavSpec.item);
      expect(selected, greaterThan(unselected));
    });

    testWidgets('does not overflow part way through a tab change', (
      WidgetTester tester,
    ) async {
      // The bug this guards: for the 220 ms of a change two labels are laid
      // out at once, and an overshooting curve pushed the incoming one past
      // its resting width, overflowing the pill on a narrow screen.
      await tester.pumpWidget(_host(NavPill(index: 2, onSelect: (int _) {})));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(NavPill(index: 0, onSelect: (int _) {})));

      for (int frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(
          tester.takeException(),
          isNull,
          reason: 'frame $frame of the tab change',
        );
        expect(
          tester.getSize(find.byType(NavPill)).width,
          lessThanOrEqualTo(393),
          reason: 'frame $frame of the tab change',
        );
      }
      await tester.pumpAndSettle();
    });

    testWidgets('reports the tap', (WidgetTester tester) async {
      int? chosen;
      await tester.pumpWidget(
        _host(NavPill(index: 0, onSelect: (int i) => chosen = i)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(kDestinations[3].icon));
      expect(chosen, 3);
    });

    testWidgets('drops the label under a large text scale, keeping the glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(ThemeFamily.postpurush, Tone.light),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(child: NavPill(index: 0, onSelect: (int _) {})),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collections'), findsNothing);
      expect(find.byIcon(kDestinations[0].icon), findsOneWidget);
    });
  });
}
