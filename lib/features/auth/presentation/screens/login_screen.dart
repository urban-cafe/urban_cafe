import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. IMMERSIVE BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary, colorScheme.tertiary]),
              ),
            ),
          ),
          // Pattern Overlay (Optional)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/logos/urbancafelogo.png', // Reusing logo as pattern if possible, or just skip
                repeat: ImageRepeat.repeat,
                scale: 4,
              ),
            ),
          ),

          // 2. GLASS CARD
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
                              child: Image.asset(
                                'assets/logos/urbancafelogo.png',
                                height: 100,
                                fit: BoxFit.contain,
                                color: colorScheme.primary, // Tint to match theme
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'welcome_back'.tr(),
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'sign_in_subtitle'.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

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

                            if (!Env.isConfigured)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smAll,
                                  border: Border.all(color: colorScheme.errorContainer),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: colorScheme.error),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text('supabase_not_configured'.tr(), style: TextStyle(color: colorScheme.onErrorContainer)),
                                    ),
                                  ],
                                ),
                              ),

                            TextFormField(
                              controller: _emailCtrl,
                              decoration: InputDecoration(
                                labelText: 'email'.tr(),
                                prefixIcon: const Icon(Icons.email_outlined),
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
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.email,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText: 'password'.tr(),
                                prefixIcon: const Icon(Icons.lock_outline),
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
                              ),
                              obscureText: true,
                              validator: (v) => AppValidators.required(v, 'password'.tr()),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSignIn(auth),
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: auth.loading ? null : () => _handleSignIn(auth),
                                child: auth.loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('sign_in'.tr()),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('or'.tr(), style: TextStyle(color: colorScheme.outline)),
                                ),
                                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth),
                                icon: const Icon(FontAwesomeIcons.google, size: 18),
                                label: Text('sign_in_google'.tr()),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white, // White bg for Google button
                                  side: BorderSide(color: Colors.grey.shade300),
                                  foregroundColor: Colors.black87,
                                ),
                              ),
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

  Future<void> _handleSignIn(AuthProvider auth) async {
    if (_formKey.currentState!.validate()) {
      final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (success && mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      context.go('/');
    }
  }
}
