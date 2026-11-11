import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toast/liquid_glass_toast.dart';

Widget _app(Widget Function(BuildContext) onTap,
    {LiquidGlassToastTheme? theme}) {
  final home = MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('go'),
        ),
      ),
    ),
  );
  return theme == null
      ? home
      : LiquidGlassToastScope(theme: theme, child: home);
}

void main() {
  testWidgets('shows a message and dismisses itself', (tester) async {
    await tester.pumpWidget(
      _app((c) {
        LiquidGlassToast.show(
          c,
          message: 'Hello',
          duration: const Duration(seconds: 2),
        );
        return const SizedBox();
      }),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Hello'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('scope theme supplies icon and per-type duration',
      (tester) async {
    await tester.pumpWidget(
      _app(
        (c) {
          LiquidGlassToast.show(
            c,
            message: 'Done',
            type: ToastType.success,
          );
          return const SizedBox();
        },
        theme: const LiquidGlassToastTheme(
          success: ToastTypeTheme(
            icon: Icons.thumb_up_rounded,
            duration: Duration(seconds: 6),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);

    // Still visible after the default ~2.5s because the theme says 6s.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Done'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    await tester.pumpWidget(
      _app((c) {
        LiquidGlassToast.show(c, message: 'first');
        LiquidGlassToast.show(c, message: 'second');
        return const SizedBox();
      }),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
  });
}
