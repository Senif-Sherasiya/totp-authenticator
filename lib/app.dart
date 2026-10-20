import 'package:flutter/material.dart';

import 'package:st_authenticator/features/apps/state/app_controller.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/screens/home_screen.dart';
import 'package:st_authenticator/core/time/second_clock.dart';

class StAuthenticatorApp extends StatelessWidget {
  const StAuthenticatorApp({
    super.key,
    required this.controller,
    required this.clock,
  });

  final AppController controller;
  final SecondClock clock;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3949AB),
        brightness: b,
      ),
    );
    return AppScope(
      controller: controller,
      clock: clock,
      child: MaterialApp(
        title: 'Authenticator',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
