import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jajangangs/views/startup_view.dart';
import 'package:jajangangs/controllers/startup_controller.dart';
import 'package:jajangangs/models/startup_state.dart';

void main() {
  test('initialization failures can be retried successfully', () async {
    var attempts = 0;
    final controller = StartupController(
      initialize: () async {
        if (++attempts == 1) throw StateError('failure');
      },
    );
    await controller.start();
    expect(controller.state.status, StartupStatus.failed);
    await controller.start();
    expect(controller.state.status, StartupStatus.ready);
    controller.dispose();
  });

  test(
    'duplicate starts do not initialize twice and disposal is safe',
    () async {
      final pending = Completer<void>();
      var attempts = 0;
      final controller = StartupController(
        initialize: () {
          attempts++;
          return pending.future;
        },
      );
      final first = controller.start();
      await controller.start();
      expect(attempts, 1);
      controller.dispose();
      pending.complete();
      await first;
    },
  );

  testWidgets('startup displays loading, error, and allows retry', (
    tester,
  ) async {
    var attempts = 0;
    final pending = Completer<void>();
    final controller = StartupController(
      initialize: () async {
        attempts++;
        if (attempts == 1) {
          await pending.future;
          throw const FormatException('Missing configuration');
        }
        await Completer<void>().future;
      },
    );
    await tester.pumpWidget(
      MaterialApp(home: StartupView(controller: controller)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Missing configuration'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
