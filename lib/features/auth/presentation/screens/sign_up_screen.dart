import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/routing/routes.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // IMMERSIVE BACKGROUND (same as login)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary, colorScheme.tertiary]),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(opacity: 0.05, child: Image.asset('assets/logos/urbancafelogo.png', repeat: ImageRepeat.repeat, scale: 4)),
          ),

          // GLASS CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: AppRadius.xxlAll,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color?.withValues(alpha: 0.85) ?? Colors.white.withValues(alpha: 0.85),
                        borderRadius: AppRadius.xxlAll,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset('assets/logos/urbancafelogo.png', height: 80, fit: BoxFit.contain, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'create_account'.tr(),
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'sign_up_subtitle'.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Error banner
                            if (auth.error != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: colorScheme.errorContainer.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
                                child: Text(
                                  auth.error!,
                                  style: TextStyle(color: colorScheme.onErrorContainer),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: _inputDecoration(theme: theme, label: 'email'.tr(), icon: Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.email,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              decoration: _inputDecoration(
                                theme: theme,
                                label: 'password'.tr(),
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              obscureText: _obscurePass,
                              validator: AppValidators.password,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPassCtrl,
                              decoration: _inputDecoration(
                                theme: theme,
                                label: 'confirm_password'.tr(),
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              obscureText: _obscureConfirm,
                              validator: AppValidators.confirmPassword(() => _passCtrl.text),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSignUp(auth),
                            ),
                            const SizedBox(height: 32),

                            // Sign Up button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: auth.loading ? null : () => _handleSignUp(auth),
                                child: auth.loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('sign_up'.tr()),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Switch to login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('already_have_account'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                                TextButton(onPressed: () => context.go(AppRoutes.login), child: Text('sign_in'.tr())),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required ThemeData theme, required String label, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: AppRadius.lgAll, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _handleSignUp(AuthProvider auth) async {
    if (_formKey.currentState!.validate()) {
      final success = await auth.signUp(_emailCtrl.text.trim(), _passCtrl.text);

      if (!mounted) return;

      if (success) {
        // User signed in immediately (email confirmation disabled)
        context.go(AppRoutes.home);
      } else if (auth.error?.contains('email_confirmation_required') == true || auth.error?.contains('check your email') == true) {
        // Email confirmation required - show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.mark_email_read, size: 64, color: Theme.of(context).colorScheme.primary),
            title: Text('verify_email_title'.tr()),
            content: Text('verify_email_message'.tr()),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.login);
                },
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
      }
      // For other errors, the error banner will show automatically
    }
  }
}
