import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!auth.isConfigured)
                  const Text('Supabase not configured. See README to enable admin auth.'),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          final ok = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
                          if (ok) Navigator.pop(context);
                        },
                  child: auth.loading ? const CircularProgressIndicator() : const Text('Sign In'),
                ),
                if (auth.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(auth.error!)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
