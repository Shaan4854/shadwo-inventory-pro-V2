import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_text_styles.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.status == AuthStatus.uninitialized) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Shadow Inventory', style: ShadowTextStyles.h2),
                const SizedBox(height: 24),
                const Text('Ready',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }
}
