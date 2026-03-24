import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Thunder/lightning animation with random flashes and optional lightning bolts.
class ThunderAnimation extends StatefulWidget {
  const ThunderAnimation({
    super.key,
    this.intensity = 1.0,
    this.lowPower = false,
  });

  /// Storm intensity affecting flash frequency (0.0-1.0).
  final double intensity;

  /// Disables animation when battery saving is active.
  final bool lowPower;

  @override
  State<ThunderAnimation> createState() => _ThunderAnimationState();
}

class _ThunderAnimationState extends State<ThunderAnimation>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _boltController;
  final Random _random = Random();
  int _flashScheduleToken = 0;

  double _flashOpacity = 0.0;
  List<Offset>? _lightningPath;
  bool _isFlashing = false;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: Tokens.lightningFlashDuration,
    );

    _boltController = AnimationController(
      vsync: this,
      duration: Tokens.lightningFlashDuration * 2,
    );

    _flashController.addStatusListener(_onFlashStatus);
    if (!widget.lowPower) {
      _scheduleNextFlash();
    }
  }

  void _onFlashStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isFlashing = false;
        _lightningPath = null;
      });
      _scheduleNextFlash();
    }
  }

  void _scheduleNextFlash() {
    if (!mounted) return;
    final scheduleToken = ++_flashScheduleToken;

    // Random interval: 5-15 seconds, shorter with higher intensity
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    final minDelay = (15 - 10 * clampedIntensity).toInt();
    final maxDelay = (20 - 10 * clampedIntensity).toInt();
    final delay = Duration(
      seconds: minDelay + _random.nextInt(maxDelay - minDelay + 1),
    );

    Future.delayed(delay, () {
      if (!mounted || scheduleToken != _flashScheduleToken) return;
      if (!widget.lowPower) {
        _triggerFlash();
      }
    });
  }

  void _triggerFlash() {
    // Generate lightning bolt path
    _lightningPath = _generateLightningPath();

    setState(() => _isFlashing = true);

    // Flash sequence: bright -> dim -> bright -> fade
    _flashSequence();
  }

  Future<void> _flashSequence() async {
    if (!mounted) return;

    // First flash
    setState(() => _flashOpacity = 0.4 + _random.nextDouble() * 0.3);
    _boltController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    setState(() => _flashOpacity = 0.1);

    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Second flash (sometimes)
    if (_random.nextBool()) {
      setState(() => _flashOpacity = 0.3 + _random.nextDouble() * 0.2);
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
    }

    // Fade out
    setState(() => _flashOpacity = 0.0);
    _flashController.forward(from: 0);
  }

  List<Offset> _generateLightningPath() {
    final points = <Offset>[];
    final startX = 0.2 + _random.nextDouble() * 0.6;

    var x = startX;
    var y = 0.0;

    points.add(Offset(x, y));

    while (y < 0.7) {
      // Random horizontal deviation
      x += (_random.nextDouble() - 0.5) * 0.15;
      x = x.clamp(0.1, 0.9);

      // Random vertical step
      y += 0.05 + _random.nextDouble() * 0.1;

      points.add(Offset(x, y));

      // Occasionally add a branch
      if (_random.nextDouble() < 0.3 && points.length > 2) {
        final branchStart = points[points.length - 2];
        final branchEnd = Offset(
          branchStart.dx + (_random.nextDouble() - 0.5) * 0.2,
          branchStart.dy + 0.1 + _random.nextDouble() * 0.1,
        );
        // Store branch as separate segment (will be drawn separately)
        points.add(branchStart);
        points.add(branchEnd);
        points.add(Offset(x, y)); // Continue main bolt
      }
    }

    return points;
  }

  @override
  void didUpdateWidget(covariant ThunderAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lowPower != widget.lowPower) {
      if (widget.lowPower) {
        _flashScheduleToken++;
        _flashController.stop();
        _boltController.stop();
        _flashOpacity = 0.0;
        _isFlashing = false;
        _lightningPath = null;
      } else {
        _scheduleNextFlash();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _flashScheduleToken++;
    _flashController.dispose();
    _boltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowPower) return const SizedBox.expand();

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Screen flash overlay
          if (_flashOpacity > 0)
            AnimatedOpacity(
              opacity: _flashOpacity,
              duration: const Duration(milliseconds: 30),
              child: Container(color: Colors.white),
            ),

          // Lightning bolt
          if (_isFlashing && _lightningPath != null)
            AnimatedBuilder(
              animation: _boltController,
              builder: (context, _) => CustomPaint(
                painter: _LightningPainter(
                  path: _lightningPath!,
                  progress: _boltController.value,
                ),
                size: Size.infinite,
              ),
            ),
        ],
      ),
    );
  }
}

class _LightningPainter extends CustomPainter {
  _LightningPainter({required this.path, required this.progress});

  static final Paint _glowPaint = Paint()
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _corePaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  static final Paint _innerPaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final List<Offset> path;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final visiblePoints = (path.length * progress).ceil().clamp(2, path.length);
    final opacity = 1.0 - progress * 0.7;

    // Glow effect
    _glowPaint.color = Colors.white.withValues(alpha: opacity * 0.4);
    _corePaint.color = Colors.white.withValues(alpha: opacity);
    _innerPaint.color = const Color(0xFFE0E8FF).withValues(alpha: opacity);

    final boltPath = Path();
    boltPath.moveTo(path[0].dx * size.width, path[0].dy * size.height);

    for (var i = 1; i < visiblePoints; i++) {
      boltPath.lineTo(path[i].dx * size.width, path[i].dy * size.height);
    }

    canvas.drawPath(boltPath, _glowPaint);
    canvas.drawPath(boltPath, _corePaint);
    canvas.drawPath(boltPath, _innerPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.path != path;
}
