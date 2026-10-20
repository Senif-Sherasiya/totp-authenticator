import 'package:flutter/widgets.dart';

import 'package:st_authenticator/features/apps/state/app_controller.dart';
import 'package:st_authenticator/core/time/second_clock.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.controller,
    required this.clock,
    required super.child,
  });

  final AppController controller;
  final SecondClock clock;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => false;
}
