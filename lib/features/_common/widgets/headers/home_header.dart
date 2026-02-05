import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String location;
  final String? userName;
  final String? avatarUrl;

  const HomeHeader({
    super.key,
    required this.location,
    this.userName,
    this.avatarUrl,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, ${userName ?? 'Guest'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // InkWell(
          //   onTap: () => context.go('/profile'),
          //   borderRadius: BorderRadius.circular(14),
          //   child: Container(
          //     width: 48,
          //     height: 48,
          //     decoration: BoxDecoration(
          //       color: cs.primaryContainer,
          //       borderRadius: BorderRadius.circular(14),
          //       border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 2),
          //       image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover) : null,
          //     ),
          //     child: avatarUrl == null ? Icon(Icons.person_rounded, color: cs.onPrimaryContainer) : null,
          //   ),
          // ),
        ],
      ),
    );
  }
}
