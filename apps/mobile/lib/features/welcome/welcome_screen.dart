import 'package:flutter/material.dart';
import '../../theme/space_theme.dart';
import '../../widgets/space_logo.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF2A1F5E), SpaceColors.midnight],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const SpaceLogo(size: 120),
                const SizedBox(height: 24),
                Text('SPACE',
                    style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: SpaceColors.ice)),
                const SizedBox(height: 8),
                Text('Beyond Messaging.',
                    style:
                        text.titleMedium?.copyWith(color: SpaceColors.cyan)),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(startAsSignUp: true)),
                  ),
                  child: const Text('Create account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
