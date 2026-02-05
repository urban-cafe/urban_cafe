import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;

  const LoyaltyCard({
    super.key,
    required this.points,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.amber.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade700.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.brown,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$points',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.brown,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loyalty Points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.brown.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
