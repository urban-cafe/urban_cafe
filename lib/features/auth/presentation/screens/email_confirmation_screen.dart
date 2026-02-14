import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_cafe/core/routing/routes.dart';
import 'package:urban_cafe/core/theme.dart';

/// Email confirmation callback screen.
///
/// This screen is shown when users click the email verification link.
/// It handles the callback from Supabase and shows success/error states.
class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isError(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    return uri.queryParameters.containsKey('error') || uri.queryParameters.containsKey('error_code');
  }

  String _getErrorMessage(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final errorCode = uri.queryParameters['error_code'];
    final errorDescription = uri.queryParameters['error_description'];

    if (errorCode == 'otp_expired') {
      return 'email_link_expired'.tr();
    }

    if (errorDescription != null) {
      return errorDescription.replaceAll('+', ' ');
    }

    return 'email_verification_failed'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = _isError(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primaryContainer.withValues(alpha: 0.3), colorScheme.secondaryContainer.withValues(alpha: 0.3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
                          boxShadow: [BoxShadow(color: (isError ? colorScheme.error : colorScheme.primary).withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 64, color: isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      isError ? 'verification_failed'.tr() : 'email_verified'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: isError ? colorScheme.error.withValues(alpha: 0.3) : colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isError ? _getErrorMessage(context) : 'email_verified_message'.tr(),
                        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8)),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Button
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.login),
                      label: Text(isError ? 'try_again'.tr() : 'sign_in_now'.tr()),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
                        foregroundColor: isError ? colorScheme.onError : colorScheme.onPrimary,
                      ),
                    ),

                    if (!isError) ...[const SizedBox(height: 16), TextButton(onPressed: () => context.go(AppRoutes.home), child: Text('continue_browsing'.tr()))],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
