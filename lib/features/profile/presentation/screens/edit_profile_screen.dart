import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/_common/widgets/buttons/primary_button.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.profile?.fullName ?? '';
    _phoneController.text = auth.profile?.phoneNumber ?? '';
    _addressController.text = auth.profile?.address ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(fullName: _nameController.text.trim(), phoneNumber: _phoneController.text.trim(), address: _addressController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_updated_successfully'.tr()), backgroundColor: Theme.of(context).colorScheme.primary));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'failed_to_update_profile'.tr()), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text('edit_profile'.tr()), centerTitle: true, backgroundColor: cs.surface, scrolledUnderElevation: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Icon(Icons.person_rounded, size: 50, color: cs.onPrimary),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Full Name Field
                    Text(
                      'full_name'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(cs, 'enter_your_full_name'.tr(), Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'please_enter_your_name'.tr();
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Field
                    Text(
                      'Phone Number',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: _phoneController, decoration: _inputDecoration(cs, 'Enter your phone number', Icons.phone_outlined), keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),

                    // Address Field
                    Text(
                      'Address',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration(cs, 'Enter your address', Icons.location_on_outlined),
                      maxLines: 3,
                      keyboardType: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    PrimaryButton(text: 'save_changes'.tr(), onPressed: _saveProfile, isLoading: _isLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: cs.primary),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
    );
  }
}
