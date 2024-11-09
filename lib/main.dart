import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

void main() {
  runApp(const MaterialApp(home: ArcAnimationDemo()));
}

double rotationChange(Offset position, Offset delta) {
  /// Pan location on the wheel
  bool onTop = position.dy.isNegative;
  bool onLeftSide = position.dx.isNegative;
  bool onRightSide = !onLeftSide;
  bool onBottom = !onTop;

  /// Pan movements
  bool panUp = delta.dy.isNegative;
  bool panLeft = delta.dx.isNegative;
  bool panRight = !panLeft;
  bool panDown = !panUp;

  /// Absoulte change on axis
  double yChange = delta.dy.abs();
  double xChange = delta.dx.abs();

  /// Directional change on wheel
  double verticalRotation = (onRightSide && panDown) || (onLeftSide && panUp)
      ? yChange
      : yChange * -1;

  double horizontalRotation =
      (onTop && panRight) || (onBottom && panLeft) ? xChange : xChange * -1;

  // Total computed change
  double rotationalChange = verticalRotation + horizontalRotation;
  return rotationalChange;
}

double unitVelocity(Offset pixelsPerSecond, Size size) {
  final unitsPerSecondX = pixelsPerSecond.dx / size.width;
  final unitsPerSecondY = pixelsPerSecond.dy / size.height;
  final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
  return unitsPerSecond.distance;
}

class ArcAnimationDemo extends StatelessWidget {
  const ArcAnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const DraggableCard(),
    );
  }
}

/// A draggable card that moves back to [Alignment.center] when it's
/// released.
class DraggableCard extends StatefulWidget {
  const DraggableCard({super.key});

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with TickerProviderStateMixin {
  late AnimationController _draggingController;
  late AnimationController _spinningController;

  /// The alignment of the card as it is dragged or being animated.
  ///
  /// While the card is being dragged, this value is set to the values computed
  /// in the GestureDetector onPanUpdate callback. If the animation is running,
  /// this value is set to the value of the [_draggingAnimation].
  Alignment _dragAlignment = Alignment.center;
  double _spinningAngle = 0;
  bool direction = false;

  late Animation<Alignment> _draggingAnimation;
  late Animation<double> _spinningAnimation;

  /// Calculates and runs a [SpringSimulation].
  void _runDraggingAnimation(unitVelocity) {
    _draggingAnimation = _draggingController.drive(
      AlignmentTween(
        begin: _dragAlignment,
        end: Alignment.center,
      ),
    );

    const spring = SpringDescription(
      mass: 30,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    _draggingController.animateWith(simulation);
  }

  void _runSpinningAnimation(double unitVelocity) {
    const double acceleration = -2.0;
    final int time = unitVelocity < 1 ? 1 : (-unitVelocity ~/ acceleration);

    //Calculate the distance
    final distance = (unitVelocity * time) + (0.5 * acceleration * time * time);
    //Calculate the end angle and adjust it according to the direction
    double endAngle = _spinningAngle + distance * (direction ? -1 : 1);

    //Round the end angle to the nearest 2pi to make the widget upright
    endAngle = (endAngle / (pi * 2)).round() * (pi * 2);

    _spinningAnimation = Tween<double>(
      begin: _spinningAngle,
      end: endAngle,
    ).animate(
      CurvedAnimation(
        parent: _spinningController,
        curve: Curves.decelerate,
      ),
    );

    _spinningController.reset();
    _spinningController.animateTo(1, duration: Duration(seconds: time));
  }

  @override
  void initState() {
    super.initState();
    _draggingController = AnimationController(vsync: this);
    _spinningController = AnimationController(vsync: this);

    _draggingController.addListener(() {
      setState(() {
        _dragAlignment = _draggingAnimation.value;
      });
    });

    _spinningController.addListener(() {
      setState(() {
        _spinningAngle = _spinningAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _draggingController.dispose();
    _spinningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onPanDown: (details) {
              _spinningController.stop();
            },
            onPanUpdate: (details) {
              var position = details.localPosition;
              position -= Offset(size.width / 2, size.height / 2);
              double rotationalChange = rotationChange(position, details.delta);
              setState(() {
                direction = rotationalChange.isNegative;
                _spinningAngle += rotationalChange * 0.005;
              });
            },
            onPanEnd: (details) {
              final _unitVelocity =
                  unitVelocity(details.velocity.pixelsPerSecond, size);
              _runSpinningAnimation(_unitVelocity);
            },
          ),
        ),
        Align(
          alignment: _dragAlignment,
          child: GestureDetector(
            onPanDown: (details) {
              _draggingController.stop();
            },
            onPanUpdate: (details) {
              setState(() {
                _dragAlignment += Alignment(
                  details.delta.dx / (size.width / 2),
                  details.delta.dy / (size.height / 2),
                );
              });
            },
            onPanEnd: (details) {
              final _unitVelocity =
                  unitVelocity(details.velocity.pixelsPerSecond, size);
              _runDraggingAnimation(_unitVelocity);
            },
            child: Transform.rotate(
              angle: _spinningAngle,
              child: Image.asset(
                'assets/logo.png',
                height: 150,
                width: 150,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
