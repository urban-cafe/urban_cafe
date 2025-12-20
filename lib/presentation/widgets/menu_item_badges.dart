import 'package:flutter/material.dart';

class MenuItemBadges extends StatelessWidget {
  final bool isMostPopular;
  final bool isWeekendSpecial;

  const MenuItemBadges({super.key, required this.isMostPopular, required this.isWeekendSpecial});

  @override
  Widget build(BuildContext context) {
    if (!isMostPopular && !isWeekendSpecial) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isMostPopular) _Badge(text: 'Most Popular', backgroundColor: Colors.amber.shade100, textColor: Colors.brown.shade800, icon: Icons.star_rounded, iconColor: Colors.brown.shade800),
        if (isWeekendSpecial) _Badge(text: 'Weekend Specials', backgroundColor: Colors.brown.shade100, textColor: Colors.brown.shade900, icon: Icons.local_offer_rounded, iconColor: Colors.brown.shade700),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;

  const _Badge({required this.text, required this.backgroundColor, required this.textColor, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}
