import 'package:flutter/material.dart';

/// Custom animation curves for premium feel
class AppCurves {
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve snappy = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Animation duration constants
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 50);
}

/// Staggered animation helper widget
class StaggeredAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const StaggeredAnimation({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 30),
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.smooth));
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.emphasized),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Scale on press animation wrapper
class ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const ScaleTapWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Animated heart/favorite button with bounce
class AnimatedHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedHeartButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            size: widget.size,
            color: widget.isFavorite
                ? (widget.activeColor ?? Colors.red)
                : (widget.inactiveColor ?? cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Shimmer effect for loading states and premium cards
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.baseColor ?? cs.surfaceContainerHighest,
              widget.highlightColor ?? cs.surface,
              widget.baseColor ?? cs.surfaceContainerHighest,
            ],
            stops: [
              _controller.value - 0.3,
              _controller.value,
              _controller.value + 0.3,
            ].map((s) => s.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Pulse animation for status indicators
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

/// Slide and fade transition for page routes
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
