import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Thunder/lightning animation with random flashes and lightning bolts.
class ThunderAnimation extends StatefulWidget {
  const ThunderAnimation({
    super.key,
    this.intensity = 1.0,
    this.lowPower = false,
  });

  /// Storm intensity affecting flash frequency.
  final double intensity;

  /// Disables the animation when battery saving is active.
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
  _LightningBolt? _lightningBolt;
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
      _scheduleNextFlash(first: true);
    }
  }

  void _onFlashStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isFlashing = false;
        _lightningBolt = null;
      });
      _scheduleNextFlash();
    }
  }

  void _scheduleNextFlash({bool first = false}) {
    if (!mounted) return;
    final scheduleToken = ++_flashScheduleToken;

    final Duration delay;
    if (first) {
      // Strike shortly after mount so the effect is immediately visible.
      delay = Duration(milliseconds: 1200 + _random.nextInt(800));
    } else {
      // 8-12 s at intensity 0, shrinking to 3-6 s at full intensity.
      final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
      final minDelay = (8 - 5 * clampedIntensity).toInt();
      final maxDelay = (12 - 6 * clampedIntensity).toInt();
      delay = Duration(
        seconds: minDelay + _random.nextInt(maxDelay - minDelay + 1),
      );
    }

    Future.delayed(delay, () {
      if (!mounted || scheduleToken != _flashScheduleToken) return;
      if (!widget.lowPower) {
        _triggerFlash();
      }
    });
  }

  void _triggerFlash() {
    _lightningBolt = _generateLightningBolt();

    setState(() => _isFlashing = true);
    _flashSequence(++_flashScheduleToken);
  }

  /// bright -> dim -> (sometimes) bright again -> fade, mimicking a real
  /// multi-strobe lightning strike before the fade-out controller runs.
  Future<void> _flashSequence(int sequenceToken) async {
    if (!mounted) return;

    setState(() => _flashOpacity = 0.4 + _random.nextDouble() * 0.3);
    _boltController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted || sequenceToken != _flashScheduleToken) return;

    setState(() => _flashOpacity = 0.1);

    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted || sequenceToken != _flashScheduleToken) return;

    if (_random.nextBool()) {
      setState(() => _flashOpacity = 0.3 + _random.nextDouble() * 0.2);
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted || sequenceToken != _flashScheduleToken) return;
    }

    setState(() => _flashOpacity = 0.0);
    _flashController.forward(from: 0);
  }

  _LightningBolt _generateLightningBolt() {
    final mainPoints = <Offset>[];
    final branches = <List<Offset>>[];
    final startX = 0.2 + _random.nextDouble() * 0.6;

    var x = startX;
    var y = 0.0;

    mainPoints.add(Offset(x, y));

    while (y < 0.7) {
      x += (_random.nextDouble() - 0.5) * 0.15;
      x = x.clamp(0.1, 0.9);

      y += 0.05 + _random.nextDouble() * 0.1;

      mainPoints.add(Offset(x, y));

      if (_random.nextDouble() < 0.3 && mainPoints.length > 2) {
        final branchStart = mainPoints[mainPoints.length - 2];
        branches.add([
          branchStart,
          Offset(
            branchStart.dx + (_random.nextDouble() - 0.5) * 0.2,
            branchStart.dy + 0.1 + _random.nextDouble() * 0.1,
          ),
        ]);
      }
    }

    return _LightningBolt(mainPoints: mainPoints, branches: branches);
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
        _lightningBolt = null;
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
          if (_isFlashing && _lightningBolt != null)
            AnimatedBuilder(
              animation: _boltController,
              builder: (context, _) => CustomPaint(
                painter: _LightningPainter(
                  bolt: _lightningBolt!,
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

class _LightningBolt {
  _LightningBolt({required this.mainPoints, required this.branches});

  final List<Offset> mainPoints;
  final List<List<Offset>> branches;
}

class _LightningPainter extends CustomPainter {
  _LightningPainter({required this.bolt, required this.progress});

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

  final _LightningBolt bolt;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final visiblePoints =
        (bolt.mainPoints.length * progress).ceil().clamp(2, bolt.mainPoints.length);
    final opacity = 1.0 - progress * 0.55;

    _glowPaint.color = Colors.white.withValues(alpha: opacity * 0.5);
    _corePaint.color = Colors.white.withValues(alpha: opacity);
    _innerPaint.color = const Color(0xFFE0E8FF).withValues(alpha: opacity);

    final boltPath = Path();
    final points = bolt.mainPoints;
    boltPath.moveTo(points[0].dx * size.width, points[0].dy * size.height);

    for (var i = 1; i < visiblePoints; i++) {
      boltPath.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }

    // Branch tips appear only once the trunk has grown past their origin.
    for (final branch in bolt.branches) {
      final originIndex = points.indexOf(branch[0]);
      if (originIndex < 0 || originIndex >= visiblePoints) continue;
      boltPath.moveTo(
        branch[0].dx * size.width,
        branch[0].dy * size.height,
      );
      boltPath.lineTo(
        branch[1].dx * size.width,
        branch[1].dy * size.height,
      );
    }

    canvas.drawPath(boltPath, _glowPaint);
    canvas.drawPath(boltPath, _corePaint);
    canvas.drawPath(boltPath, _innerPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bolt != bolt;
}
