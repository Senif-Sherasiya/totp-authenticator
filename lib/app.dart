import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';
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
    return AppScope(
      controller: controller,
      clock: clock,
      child: MaterialApp(
        title: 'Authenticator',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
