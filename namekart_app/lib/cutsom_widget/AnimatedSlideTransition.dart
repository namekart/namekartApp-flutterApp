import 'package:flutter/material.dart';

enum BoxAnimationType {
  fadeInFromTop,
  fadeInFromBottom,
  fadeInFromLeft,
  fadeInFromRight,
  fadeOutToTop,
  fadeOutToBottom,
  fadeOutToLeft,
  fadeOutToRight,
  none, // For no animation
}

class AnimatedSlideTransition extends StatefulWidget {
  final Widget child;
  final BoxAnimationType animationType;
  final Duration duration;
  final Curve curve;
  final bool playAnimation; // Control when to play the animation

  const AnimatedSlideTransition({
    super.key,
    required this.child,
    this.animationType = BoxAnimationType.fadeInFromBottom,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.playAnimation = true, // Default to true to play on initial build
  });

  @override
  State<AnimatedSlideTransition> createState() => _AnimatedSlideTransitionState();
}

class _AnimatedSlideTransitionState extends State<AnimatedSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _updateAnimation();

    if (widget.playAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationType != oldWidget.animationType) {
      _updateAnimation();
      if (widget.playAnimation) {
        _controller.reset();
        _controller.forward();
      }
    } else if (widget.playAnimation != oldWidget.playAnimation) {
      if (widget.playAnimation) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _updateAnimation() {
    Tween<Offset> tween;
    switch (widget.animationType) {
      case BoxAnimationType.fadeInFromTop:
        tween = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);
        break;
      case BoxAnimationType.fadeInFromBottom:
        tween = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
        break;
      case BoxAnimationType.fadeInFromLeft:
        tween = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero);
        break;
      case BoxAnimationType.fadeInFromRight:
        tween = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
        break;
      case BoxAnimationType.fadeOutToTop:
        tween = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1));
        break;
      case BoxAnimationType.fadeOutToBottom:
        tween = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1));
        break;
      case BoxAnimationType.fadeOutToLeft:
        tween = Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0));
        break;
      case BoxAnimationType.fadeOutToRight:
        tween = Tween<Offset>(begin: Offset.zero, end: const Offset(1, 0));
        break;
      case BoxAnimationType.none:
        tween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
        break;
    }
    _offsetAnimation = tween.animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animationType == BoxAnimationType.none) {
      return widget.child;
    }
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition( // Added FadeTransition for a more natural "fade in" effect
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}