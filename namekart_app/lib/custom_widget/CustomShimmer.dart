import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CustomShimmerDirection { ltr, rtl, ttb, btt }

class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final CustomShimmerDirection direction;
  final Gradient gradient;
  final int loop;
  final bool enabled;
  final BorderRadius? borderRadius;
  final double opacity;

  const CustomShimmer({
    super.key,
    required this.child,
    required this.gradient,
    this.direction = CustomShimmerDirection.ltr,
    this.period = const Duration(milliseconds: 1500),
    this.loop = 0,
    this.enabled = true,
    this.borderRadius,
    this.opacity = 1,
  });

  CustomShimmer.fromColors({
    Key? key,
    required this.child,
    required Color baseColor,
    required Color highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.direction = CustomShimmerDirection.ltr,
    this.loop = 0,
    this.enabled = true,
    this.borderRadius,
    this.opacity = 1,
  }) : gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      baseColor.withOpacity(0.2), // Keep it subtle
      baseColor.withOpacity(0.5),
      highlightColor.withOpacity(opacity),
      baseColor.withOpacity(0.5),
      baseColor.withOpacity(0.2),
    ],
    stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0],
  );

  @override
  _CustomShimmerState createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _count++;
          if (widget.loop <= 0) {
            _controller.repeat();
          } else if (_count < widget.loop) {
            _controller.forward(from: 0.0);
          }
        }
      });
    if (widget.enabled) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CustomShimmer oldWidget) {
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.stop();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => _CustomShimmerEffect(
        child: child,
        direction: widget.direction,
        gradient: widget.gradient,
        percent: _controller.value,
        borderRadius: widget.borderRadius,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CustomShimmerEffect extends SingleChildRenderObjectWidget {
  final double percent;
  final CustomShimmerDirection direction;
  final Gradient gradient;
  final BorderRadius? borderRadius;

  const _CustomShimmerEffect({
    Widget? child,
    required this.percent,
    required this.direction,
    required this.gradient,
    this.borderRadius,
  }) : super(child: child);

  @override
  _CustomShimmerRenderObject createRenderObject(BuildContext context) {
    return _CustomShimmerRenderObject(percent, direction, gradient, borderRadius);
  }

  @override
  void updateRenderObject(BuildContext context, _CustomShimmerRenderObject CustomShimmer) {
    CustomShimmer
      ..percent = percent
      ..gradient = gradient
      ..direction = direction
      ..borderRadius = borderRadius;
  }
}

class _CustomShimmerRenderObject extends RenderProxyBox {
  CustomShimmerDirection _direction;
  Gradient _gradient;
  double _percent;
  BorderRadius? _borderRadius;

  _CustomShimmerRenderObject(this._percent, this._direction, this._gradient, this._borderRadius);

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  set percent(double newValue) {
    if (newValue != _percent) {
      _percent = newValue;
      markNeedsPaint();
    }
  }

  set gradient(Gradient newValue) {
    if (newValue != _gradient) {
      _gradient = newValue;
      markNeedsPaint();
    }
  }

  set direction(CustomShimmerDirection newDirection) {
    if (newDirection != _direction) {
      _direction = newDirection;
      markNeedsLayout();
    }
  }

  set borderRadius(BorderRadius? newBorderRadius) {
    if (newBorderRadius != _borderRadius) {
      _borderRadius = newBorderRadius;
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);

      final double width = child!.size.width;
      final double height = child!.size.height;
      Rect rect;
      double dx, dy;

      if (_direction == CustomShimmerDirection.rtl) {
        dx = _offset(width, -width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      } else if (_direction == CustomShimmerDirection.ttb) {
        dx = 0.0;
        dy = _offset(-height, height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else if (_direction == CustomShimmerDirection.btt) {
        dx = 0.0;
        dy = _offset(height, -height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else {
        dx = _offset(-width, width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      }

      if (_borderRadius != null) {
        layer ??= ShaderMaskLayer();
        layer!
          ..shader = _gradient.createShader(rect)
          ..maskRect = Rect.fromLTWH(
            offset.dx,
            offset.dy,
            width,
            height,
          )
          ..blendMode = BlendMode.overlay;
      } else {
        layer ??= ShaderMaskLayer();
        layer!
          ..shader = _gradient.createShader(rect)
          ..maskRect = offset & size
          ..blendMode = BlendMode.overlay;
      }

      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }

  double _offset(double start, double end, double percent) {
    return start + (end - start) * percent;
  }
}