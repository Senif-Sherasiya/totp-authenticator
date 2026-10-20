import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'state/app_controller.dart';
import 'ui/second_clock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(StoredAppRepository(SecureKeyValueStore()));
  final clock = SecondClock()..start();
  controller.load();
  runApp(StAuthenticatorApp(controller: controller, clock: clock));
}
