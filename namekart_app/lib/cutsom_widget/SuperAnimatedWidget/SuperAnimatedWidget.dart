import 'package:flutter/material.dart';

enum AnimationEffect { fade, scale, slide }

class SuperAnimatedWidget extends StatefulWidget {
  final Widget child;
  final List<AnimationEffect> effects;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;

  const SuperAnimatedWidget({
    required this.child,
    this.effects = const [AnimationEffect.fade],
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.slideOffset = const Offset(0.0, 0.1), // Slide from bottom by default
    Key? key,
  }) : super(key: key);

  @override
  State<SuperAnimatedWidget> createState() => _SuperAnimatedWidgetState();
}

class _SuperAnimatedWidgetState extends State<SuperAnimatedWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(_animation);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedChild() {
    Widget animated = widget.child;

    if (widget.effects.contains(AnimationEffect.slide)) {
      animated = SlideTransition(position: _slideAnimation, child: animated);
    }

    if (widget.effects.contains(AnimationEffect.scale)) {
      animated = ScaleTransition(scale: _animation, child: animated);
    }

    if (widget.effects.contains(AnimationEffect.fade)) {
      animated = FadeTransition(opacity: _animation, child: animated);
    }

    return animated;
  }

  @override
  Widget build(BuildContext context) => _buildAnimatedChild();
}