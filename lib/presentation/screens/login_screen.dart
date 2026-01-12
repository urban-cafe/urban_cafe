import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/utils.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Determine title based on context if needed, but generic "Login" is fine.
    // Since this is now the entry point, back button behavior changes.
    // It shouldn't have a back button if it's the initial route.

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo or Branding
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/logos/urbancafelogo.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.local_cafe, size: 80, color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Please sign in to continue', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 32),

                    if (!auth.isConfigured)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.brown),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('Supabase not configured. Auth disabled.', style: TextStyle(color: Colors.brown)),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.email,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                      validator: (v) => AppValidators.required(v, 'Password'),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignIn(auth),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: auth.loading ? null : () => _handleSignIn(auth),
                        child: auth.loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: colorScheme.outline)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth), icon: const Icon(FontAwesomeIcons.google, size: 18), label: const Text('Sign in with Google')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    final success = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (!success) {
      showAppSnackBar(context, auth.error ?? 'Google Sign In Failed', isError: true);
    }
  }

  Future<void> _handleSignIn(AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);

    if (!context.mounted) return;

    if (success) {
      // Navigation is handled by GoRouter redirect in main.dart
      // based on auth state changes.
    } else {
      showAppSnackBar(context, auth.error ?? 'Invalid Email or Password', isError: true);
    }
  }
}
