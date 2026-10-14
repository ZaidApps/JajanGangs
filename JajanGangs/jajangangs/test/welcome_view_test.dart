import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jajangangs/app.dart';
import 'package:jajangangs/views/welcome_view.dart';
import 'package:jajangangs/theme/app_theme.dart';

void main() {
  testWidgets('app opens welcome without a Mapbox token or native services', (
    tester,
  ) async {
    await tester.pumpWidget(const JajanGangsApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text("I'm Hungry!"), findsOneWidget);
    expect(find.textContaining('Provide a public Mapbox'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'welcome supports narrow screens, large text and reduced motion',
    (tester) async {
      var registerTaps = 0;
      var loginTaps = 0;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: WelcomeView(
              onGetStarted: () => registerTaps++,
              onLogin: () => loginTaps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text("I'm Hungry!"));
      await tester.tap(find.text("I'm Hungry!"));
      await tester.pumpAndSettle();
      expect(registerTaps, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(loginTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
