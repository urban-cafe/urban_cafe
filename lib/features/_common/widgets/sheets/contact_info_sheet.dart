// presentation/widgets/contact_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:urban_cafe/core/common_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfoSheet extends StatelessWidget {
  const ContactInfoSheet({super.key});

  Future<void> _callPhone(String phone) async {
    // Fix: Remove spaces to ensure the dialer works on all devices
    final cleanNumber = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),

          const SizedBox(height: 28),

          // Address
          InkWell(
            onTap: () async {
              final String googleMapsUrl = CommonConstants.googleMapURl;
              final Uri uri = Uri.parse(googleMapsUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              // CHANGE 1: Added horizontal: 16 to match the Phone Tile padding
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CHANGE 2: Changed size to 24 to match Phone icon (was 28)
                  Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(CommonConstants.address, style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface, height: 1.4))],
                    ),
                  ),
                ],
              ),
            ),
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
          Padding(
            // CHANGE 3: Added padding here too so "Opening Hours" aligns as well
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: colorScheme.primary, size: 24), // Size 24
                const SizedBox(width: 16),
                Text(
                  CommonConstants.openTime,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile(BuildContext context, String phone) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _callPhone(phone),
          child: Padding(
            // This padding (16) determines the alignment.
            // We matched the Address section to this.
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.phone_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 16),
                Text(
                  phone,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
