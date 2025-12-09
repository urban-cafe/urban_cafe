// transitions.dart (create a small helper)
import 'package:flutter/material.dart';

/// Modern fade + slight slide + scale transition used for web.
Widget defaultTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  // Primary curve
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

  // Slide from 12 px down -> 0
  final slideOffset = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved);

  // Slight scale from 0.995 -> 1.0
  final scale = Tween<double>(begin: 0.995, end: 1.0).animate(curved);

  // Fade in
  final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

  return FadeTransition(
    opacity: opacity,
    child: SlideTransition(
      position: slideOffset,
      child: ScaleTransition(scale: scale, child: child),
    ),
  );
}
