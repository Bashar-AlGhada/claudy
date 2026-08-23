import 'dart:math';

import 'package:flutter/material.dart';

/// Base for looping weather particle animations driven by a single
/// repeating controller.
abstract class ParticleAnimation extends StatefulWidget {
  const ParticleAnimation({
    super.key,
    this.intensity = 1.0,
    this.lowPower = false,
  });

  /// Strength of the effect from 0.0 (subtle) to 1.0 (full).
  final double intensity;

  /// Renders nothing when battery saving is active.
  final bool lowPower;
}

/// State base owning the controller lifecycle and the standard
/// RepaintBoundary/AnimatedBuilder/CustomPaint build pipeline.
abstract class ParticleAnimationState<W extends ParticleAnimation> extends State<W>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Random random = createRandom();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: cycleDuration,
    );
    if (!widget.lowPower) {
      _controller.repeat();
    }
    regenerate();
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lowPower != widget.lowPower) {
      // Keep the ticker idle while nothing is painted; without this the
      // controller keeps firing every vsync in battery-save mode.
      if (widget.lowPower) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
    if (shouldRegenerate(oldWidget)) {
      setState(regenerate);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowPower) return const SizedBox.expand();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: createPainter(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }

  /// Duration of one full particle cycle.
  Duration get cycleDuration;

  /// Override to seed [random] for deterministic layouts.
  Random createRandom() => Random();

  /// Whether the particle field must be regenerated for [oldWidget].
  bool shouldRegenerate(W oldWidget) => oldWidget.intensity != widget.intensity;

  /// Rebuilds the particle field; called on init and regeneration.
  @protected
  void regenerate();

  /// Builds the painter for the current [progress] (0.0 to 1.0).
  CustomPainter createPainter(double progress);
}
