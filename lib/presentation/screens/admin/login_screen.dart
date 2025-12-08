import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/validators.dart';
import 'package:urban_cafe/presentation/providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

    // 1. Wrap in PopScope to capture Android system back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate back to the Main Menu instead of exiting
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Login'),
          // 2. Add an explicit Back Button in the App Bar
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            child: Text('Supabase not configured. See README to enable admin auth.', style: TextStyle(color: Colors.brown)),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email, // Global Email Validator
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    validator: (v) => AppValidators.required(v, 'Password'), // Global Required Validator
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();

                              final messenger = ScaffoldMessenger.of(context);
                              final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);

                              if (!context.mounted) return;

                              if (success) {
                                context.go('/admin');
                              } else {
                                messenger.showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                              }
                            },
                      child: auth.loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
