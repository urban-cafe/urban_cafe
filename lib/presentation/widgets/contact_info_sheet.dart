// presentation/widgets/contact_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:urban_cafe/core/common_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfoSheet extends StatelessWidget {
  const ContactInfoSheet({super.key});

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(3)),
          ),

          const SizedBox(height: 24),

          Text(
            'Contact Us',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),

          const SizedBox(height: 28),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text(CommonConstants.address, style: theme.textTheme.bodyLarge)),
            ],
          ),

          const SizedBox(height: 28),

          // Phone Numbers
          _buildPhoneTile(context, CommonConstants.phoneNumber1),
          const SizedBox(height: 12),
          _buildPhoneTile(context, CommonConstants.phoneNumber2),
          const SizedBox(height: 12),
          _buildPhoneTile(context, CommonConstants.phoneNumber3),

          const SizedBox(height: 28),

          // Opening Hours
          Row(
            children: [
              Icon(Icons.access_time_filled, color: colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Text(
                CommonConstants.openTime,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile(BuildContext context, String phone) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.phone_rounded, color: colorScheme.primary, size: 26),
      title: Text(
        phone,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
      ),
      onTap: () => _callPhone(phone),
    );
  }
}
