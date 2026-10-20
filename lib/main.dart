import 'package:flutter/material.dart';

import 'package:st_authenticator/app.dart';
import 'package:st_authenticator/features/apps/data/app_repository.dart';
import 'package:st_authenticator/features/apps/state/app_controller.dart';
import 'package:st_authenticator/core/time/second_clock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(StoredAppRepository(SecureKeyValueStore()));
  final clock = SecondClock()..start();
  controller.load();
  runApp(StAuthenticatorApp(controller: controller, clock: clock));
}
