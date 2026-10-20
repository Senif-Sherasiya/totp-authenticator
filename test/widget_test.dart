import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_authenticator/app.dart';
import 'package:st_authenticator/features/apps/data/app_repository.dart';
import 'package:st_authenticator/features/apps/state/app_controller.dart';
import 'package:st_authenticator/core/time/second_clock.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('empty state, add flow shows test code and card', (tester) async {
    final controller = AppController(StoredAppRepository(FakeStore()));
    final clock = SecondClock(); // not started: no timers in tests
    await controller.load();
    await tester.pumpWidget(
      StAuthenticatorApp(controller: controller, clock: clock),
    );

    expect(find.text('Add your first app'), findsOneWidget);
    expect(find.textContaining('Device time:'), findsOneWidget);

    await tester.tap(find.text('Add app').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'SHORT');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.textContaining('at least 16'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'gezd gnbv gy3t qojq',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Demo added'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Demo'), findsOneWidget);
    expect(controller.apps.single.secretBase32, 'GEZDGNBVGY3TQOJQ');
  });
}
