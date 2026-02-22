import 'package:flutter/material.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileActionTile({super.key, required this.icon, required this.title, required this.subtitle, this.iconColor, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 18),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant) : null),
    );
  }
}
