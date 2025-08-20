import 'dart:math';
import 'package:flutter/material.dart';

enum AnimationType {
  slide,
  scale,
  rotate,
  bounce,
  vibrate,
  flyUpLoop,
}

class AnimatedAvatarIcon extends StatefulWidget {
  final Widget child;
  final AnimationType? animationType;
  final Duration duration;
  final bool reverse; // Added reverse option

  const AnimatedAvatarIcon({
    Key? key,
    required this.child,
    this.animationType,
    this.duration = const Duration(milliseconds: 1600),
    this.reverse = false, // Default to false
  }) : super(key: key);

  @override
  State<AnimatedAvatarIcon> createState() => _AnimatedAvatarIconState();
}

class _AnimatedAvatarIconState extends State<AnimatedAvatarIcon> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _doubleAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.animationType ?? AnimationType.values[Random().nextInt(AnimationType.values.length)];

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (_type == AnimationType.flyUpLoop) {
      _setupFlyAnimation();
    } else {
      _setupBasicAnimation();
    }

    // Use reverse option to determine repeat behavior
    if (widget.reverse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.repeat();
    }
  }

  void _setupBasicAnimation() {
    switch (_type) {
      case AnimationType.slide:
        _doubleAnimation = Tween<double>(begin: 0, end: -30).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.scale:
        _doubleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.rotate:
        _doubleAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear),
        );
        break;
      case AnimationType.bounce:
        _doubleAnimation = Tween<double>(begin: 0, end: 15).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.vibrate:
        _doubleAnimation = Tween<double>(begin: -2, end: 2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear),
        );
        break;
      default:
        break;
    }
  }

  void _setupFlyAnimation() {
    _positionAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 1.2), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.5)).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFlyAnimation() {
    return SlideTransition(
      position: _positionAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }

  Widget _buildOtherAnimations() {
    switch (_type) {
      case AnimationType.slide:
        return AnimatedBuilder(
          animation: _doubleAnimation,
          builder: (_, child) => Transform.translate(offset: Offset(0, _doubleAnimation.value), child: child),
          child: widget.child,
        );
      case AnimationType.scale:
        return ScaleTransition(scale: _doubleAnimation, child: widget.child);
      case AnimationType.rotate:
        return RotationTransition(turns: _doubleAnimation, child: widget.child);
      case AnimationType.bounce:
        return AnimatedBuilder(
          animation: _doubleAnimation,
          builder: (_, child) => Transform.translate(offset: Offset(0, -_doubleAnimation.value), child: child),
          child: widget.child,
        );
      case AnimationType.vibrate:
        return AnimatedBuilder(
          animation: _doubleAnimation,
          builder: (_, child) => Transform.translate(offset: Offset(_doubleAnimation.value, 0), child: child),
          child: widget.child,
        );
      default:
        return widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _type == AnimationType.flyUpLoop ? _buildFlyAnimation() : _buildOtherAnimations();
  }
}