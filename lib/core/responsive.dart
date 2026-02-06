import 'package:flutter/widgets.dart';

/// Material 3 window size classes for responsive layouts.
enum WindowSizeClass { compact, medium, expanded }

/// Responsive utilities following Material 3 guidelines.
class Responsive {
  /// Material 3 breakpoints
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 840;
  static const double expandedBreakpoint = 1200;

  static double width(BuildContext context, double percentage) {
    return MediaQuery.sizeOf(context).width * (percentage / 100);
  }

  static double height(BuildContext context, double percentage) {
    return MediaQuery.sizeOf(context).height * (percentage / 100);
  }

  /// Get the current window size class based on Material 3 guidelines.
  static WindowSizeClass windowSizeClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) return WindowSizeClass.compact;
    if (width < mediumBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  /// Compact: < 600dp (phones)
  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compactBreakpoint;

  /// Medium: 600-840dp (small tablets, foldables)
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < mediumBreakpoint;
  }

  /// Expanded: >= 840dp (large tablets, desktop)
  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= mediumBreakpoint;

  // Legacy methods for backwards compatibility
  static bool isMobile(BuildContext context) => isCompact(context);
  static bool isTablet(BuildContext context) => isMedium(context);
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  /// Get responsive grid column count
  static int gridColumns(BuildContext context) {
    final sizeClass = windowSizeClass(context);
    switch (sizeClass) {
      case WindowSizeClass.compact:
        return 2;
      case WindowSizeClass.medium:
        return 3;
      case WindowSizeClass.expanded:
        return 4;
    }
  }
}
