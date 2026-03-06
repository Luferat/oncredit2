// lib/main.dart

import 'package:flutter/material.dart';
import 'package:oncredit/pages/client_list.dart';
import 'package:oncredit/pages/home.dart';
import 'package:oncredit/pages/settings.dart';
import 'package:oncredit/theme/theme_controller.dart';
import 'package:oncredit/theme/theme_extensions.dart';
import 'config/app_config.dart';

late ThemeController themeController;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  themeController = ThemeController();
  await themeController.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/settings': (context) => const SettingsPage(),
          '/clients': (context) => const ClientListPage(),
        },
      ),
    );
  }
}
