import 'package:flutter/widgets.dart';

import '../state/app_controller.dart';
import 'second_clock.dart';

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
