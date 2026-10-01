import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/appearance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsService,
      child: const BrahviKeyboardApp(),
    ),
  );
}

class BrahviKeyboardApp extends StatelessWidget {
  const BrahviKeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brahui Keyboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
      routes: {
        '/': (_) => const HomeScreen(),
        '/appearance': (_) => const AppearanceScreen(),
      },
    );
  }
}
