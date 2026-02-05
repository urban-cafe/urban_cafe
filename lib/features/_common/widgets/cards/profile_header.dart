import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String email;
  final String role;
  final String initial;

  const ProfileHeader({super.key, required this.email, required this.role, required this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primaryContainer, width: 4),
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 3),
              ),
              child: Icon(Icons.edit, size: 16, color: colorScheme.onPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          email,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Text(
            role,
            style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }
}
