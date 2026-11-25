import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Placeholder. Chat list and messaging arrive in Phase 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('SPACE')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Signed in as $email\n\nMessaging is not built yet. It arrives in Phase 4.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
