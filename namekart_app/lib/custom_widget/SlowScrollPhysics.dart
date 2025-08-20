import 'package:flutter/cupertino.dart';

class SlowScrollPhysics extends ClampingScrollPhysics {
  final double speedFactor;
  const SlowScrollPhysics({ScrollPhysics? parent, this.speedFactor = 0.3})
      : super(parent: parent);

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(parent: buildParent(ancestor), speedFactor: speedFactor);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * speedFactor);
  }
}
