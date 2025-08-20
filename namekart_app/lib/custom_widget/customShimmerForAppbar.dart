import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CustomShimmerForAppbarDirection { ltr, rtl, ttb, btt }

class CustomShimmerForAppbar extends StatefulWidget {
  final Widget child;
  final Duration period;
  final CustomShimmerForAppbarDirection direction;
  final Gradient gradient;
  final int loop;
  final bool enabled;
  final BorderRadius? borderRadius;
  final double opacity;
  final double shimmerWidth;
  final double shimmerCenter;

  static Gradient buildGradient({
    required Color baseColor,
    required Color highlightColor,
    required double shimmerWidth,
    required double shimmerCenter,
    required double opacity,
  }) {
    final double start = (shimmerCenter - shimmerWidth / 2).clamp(0.0, 1.0);
    final double end = (shimmerCenter + shimmerWidth / 2).clamp(0.0, 1.0);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.centerRight,
      colors: [
        baseColor.withOpacity(0.0),
        baseColor.withOpacity(0.5),
        highlightColor.withOpacity(opacity),
        baseColor.withOpacity(0.5),
        baseColor.withOpacity(0.0),
      ],
      stops: [
        0.0,
        start,
        shimmerCenter,
        end,
        1.0,
      ],
    );
  }

  const CustomShimmerForAppbar({
    super.key,
    required this.child,
    required this.gradient,
    this.direction = CustomShimmerForAppbarDirection.ltr,
    this.period = const Duration(milliseconds: 1500),
    this.loop = 0,
    this.enabled = true,
    this.borderRadius,
    this.opacity = 1,
    this.shimmerWidth = 0.2,
    this.shimmerCenter = 0.5,
  });

  CustomShimmerForAppbar.fromColors({
    Key? key,
    required this.child,
    required Color baseColor,
    required Color highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.direction = CustomShimmerForAppbarDirection.ltr,
    this.loop = 0,
    this.enabled = true,
    this.borderRadius,
    this.opacity = 1,
    this.shimmerWidth = 0.2,
    this.shimmerCenter = 0.5,
  }) : gradient = CustomShimmerForAppbar.buildGradient(
    baseColor: baseColor,
    highlightColor: highlightColor,
    shimmerWidth: shimmerWidth,
    shimmerCenter: shimmerCenter,
    opacity: opacity,
  );

  @override
  _CustomShimmerForAppbarState createState() => _CustomShimmerForAppbarState();
}

class _CustomShimmerForAppbarState extends State<CustomShimmerForAppbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
      lowerBound: 0.0,
      upperBound: 2.0,
    )..addStatusListener((status) {
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

  double _computeFadeOpacity(double percent) {
    // Fade in/out when entering or exiting
    if (percent < 0.2) {
      return percent / 0.2;
    } else if (percent > 1.8) {
      return (2.0 - percent) / 0.2;
    }
    return 1.0;
  }

  @override
  void didUpdateWidget(CustomShimmerForAppbar oldWidget) {
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
      builder: (context, child) {
        final fadeOpacity = _computeFadeOpacity(_controller.value);
        return Opacity(
          opacity: fadeOpacity,
          child: _CustomShimmerForAppbarEffect(
            child: child,
            direction: widget.direction,
            gradient: widget.gradient,
            percent: _controller.value,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CustomShimmerForAppbarEffect extends SingleChildRenderObjectWidget {
  final double percent;
  final CustomShimmerForAppbarDirection direction;
  final Gradient gradient;

  const _CustomShimmerForAppbarEffect({
    Widget? child,
    required this.percent,
    required this.direction,
    required this.gradient,
  }) : super(child: child);

  @override
  _CustomShimmerForAppbarRenderObject createRenderObject(BuildContext context) {
    return _CustomShimmerForAppbarRenderObject(percent, direction, gradient);
  }

  @override
  void updateRenderObject(
      BuildContext context, _CustomShimmerForAppbarRenderObject shimmer) {
    shimmer
      ..percent = percent
      ..gradient = gradient
      ..direction = direction;
  }
}

class _CustomShimmerForAppbarRenderObject extends RenderProxyBox {
  CustomShimmerForAppbarDirection _direction;
  Gradient _gradient;
  double _percent;

  _CustomShimmerForAppbarRenderObject(
      this._percent, this._direction, this._gradient);

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

  set direction(CustomShimmerForAppbarDirection newDirection) {
    if (newDirection != _direction) {
      _direction = newDirection;
      markNeedsLayout();
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

      switch (_direction) {
        case CustomShimmerForAppbarDirection.rtl:
          dx = _offset(width * 1.5, -width * 1.5, _percent);
          dy = 0.0;
          rect = Rect.fromLTWH(dx - width, dy, width * 3, height);
          break;
        case CustomShimmerForAppbarDirection.ttb:
          dx = 0.0;
          dy = _offset(-height * 1.5, height * 1.5, _percent);
          rect = Rect.fromLTWH(dx, dy - height, width, height * 3);
          break;
        case CustomShimmerForAppbarDirection.btt:
          dx = 0.0;
          dy = _offset(height * 1.5, -height * 1.5, _percent);
          rect = Rect.fromLTWH(dx, dy - height, width, height * 3);
          break;
        case CustomShimmerForAppbarDirection.ltr:
        default:
          dx = _offset(-width * 1.5, width * 1.5, _percent);
          dy = 0.0;
          rect = Rect.fromLTWH(dx - width, dy, width * 3, height);
          break;
      }

      layer ??= ShaderMaskLayer();
      layer!
        ..shader = _gradient.createShader(rect)
        ..maskRect = offset & size
        ..blendMode = BlendMode.overlay;

      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }

  double _offset(double start, double end, double percent) {
    return start + (end - start) * percent.clamp(0.0, 2.0);
  }
}
