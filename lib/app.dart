import 'package:flutter/material.dart';

import 'state/app_controller.dart';
import 'ui/app_scope.dart';
import 'ui/home_screen.dart';
import 'ui/second_clock.dart';

class StAuthenticatorApp extends StatelessWidget {
  const StAuthenticatorApp(
      {super.key, required this.controller, required this.clock});

  final AppController controller;
  final SecondClock clock;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3949AB), brightness: b),
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
