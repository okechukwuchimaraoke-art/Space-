import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'features/welcome/welcome_screen.dart';
import 'theme/space_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.isConfigured) {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      anonKey: Config.supabaseAnonKey,
    );
  }
  runApp(const SpaceApp());
}

class SpaceApp extends StatelessWidget {
  const SpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPACE',
      debugShowCheckedModeBanner: false,
      theme: SpaceTheme.light(),
      darkTheme: SpaceTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const WelcomeScreen(),
    );
  }
}
