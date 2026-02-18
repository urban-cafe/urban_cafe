import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:urban_cafe/core/common_constants.dart';
import 'package:urban_cafe/core/responsive.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch phone call to $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sizeClass = Responsive.windowSizeClass(context);
    final isCompact = sizeClass == WindowSizeClass.compact;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('contact_us'.tr(), style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 48, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // Use Cards for better separation
            _buildSectionTitle(context, 'phone_numbers'.tr()),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildContactTile(
                    context,
                    icon: Icons.phone_rounded,
                    title: 'Phone'.tr(),
                    subtitle: CommonConstants.phoneNumber1,
                    onTap: () => _makePhoneCall(CommonConstants.phoneNumber1),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildContactTile(
                    context,
                    icon: Icons.phone_iphone_rounded,
                    title: 'Alternative Phone'.tr(),
                    subtitle: CommonConstants.phoneNumber2,
                    onTap: () => _makePhoneCall(CommonConstants.phoneNumber2),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildContactTile(
                    context,
                    icon: Icons.phone_iphone_rounded,
                    title: 'Alternative Phone'.tr(),
                    subtitle: CommonConstants.phoneNumber3,
                    onTap: () => _makePhoneCall(CommonConstants.phoneNumber3),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'visit_us'.tr()),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildContactTile(context, icon: Icons.access_time_filled_rounded, title: 'Opening Hours'.tr(), subtitle: CommonConstants.openTime, iconColor: Colors.orange),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildContactTile(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'Address'.tr(),
                    subtitle: CommonConstants.address,
                    onTap: () => _launchUrl(CommonConstants.googleMapURl),
                    iconColor: Colors.red,
                    trailing: const Icon(Icons.map, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Social Media'.tr()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(context, icon: FontAwesomeIcons.facebook, label: 'Facebook', color: const Color(0xFF1877F2), onTap: () => _launchUrl(CommonConstants.facebookUrl)),
                _buildSocialButton(context, icon: FontAwesomeIcons.instagram, label: 'Instagram', color: const Color(0xFFE4405F), onTap: () => _launchUrl(CommonConstants.instagramUrl)),
                _buildSocialButton(context, icon: FontAwesomeIcons.tiktok, label: 'TikTok', color: Colors.black, onTap: () => _launchUrl(CommonConstants.tiktokUrl)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Color? iconColor, Widget? trailing}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (iconColor ?? cs.primary).withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? cs.primary, size: 20),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSocialButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Center(child: FaIcon(icon, color: color, size: 28)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
