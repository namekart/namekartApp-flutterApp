import 'package:flutter/material.dart';

class AutoAnimatedContainerWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AutoAnimatedContainerWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
