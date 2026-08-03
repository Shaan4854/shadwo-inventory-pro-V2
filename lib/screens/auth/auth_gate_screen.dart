import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ui_kit/ui_kit.dart';

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
          return _SignInPage();
        },
      ),
    );
  }
}

class _SignInPage extends StatefulWidget {
  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            const Icon(
              Icons.inventory_2_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text('Shadow Inventory', style: ShadowTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Manage your inventory smartly',
              style: ShadowTextStyles.bodyMuted,
            ),
            const SizedBox(height: 40),

            // Google Sign-In
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ShadowButton(
                label: 'Sign in with Google',
                expand: true,
                onPressed: auth.isLoading ? null : _signInWithGoogle,
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: ShadowTextStyles.bodyMuted),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 20),

            // Email field
            ShadowInput(
              label: 'Email',
              controller: _emailCtrl,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password field
            ShadowInput(
              label: 'Password',
              controller: _passwordCtrl,
              hint: '••••••••',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 24),

            // Sign in / Sign up button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ShadowButton(
                label: _isSignUp ? 'Create Account' : 'Sign In',
                expand: true,
                onPressed: auth.isLoading ? null : _submitEmailAuth,
              ),
            ),
            const SizedBox(height: 12),

            // Toggle sign in / sign up
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : "Don't have an account? Sign up",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // Guest
            TextButton(
              onPressed: auth.isLoading ? null : _continueAsGuest,
              child: const Text(
                'Continue as Guest',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),

            // Error
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Loading
            if (auth.isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
  }

  Future<void> _submitEmailAuth() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }
    if (_isSignUp) {
      await auth.signUpWithEmail(email, password);
    } else {
      await auth.signInWithEmail(email, password);
    }
  }

  Future<void> _continueAsGuest() async {
    final auth = context.read<AuthProvider>();
    await auth.continueAsGuest();
  }
}
