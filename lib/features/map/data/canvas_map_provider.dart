import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/map/domain/map_provider.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter/material.dart';

class CanvasMapProvider implements MapProvider {
  @override
  String get name => 'Canvas';

  @override
  Widget build({
    required Set<MapOverlay> overlays,
    required GeoCoordinate? marker,
    required ValueChanged<GeoCoordinate> onTap,
  }) {
    return _CanvasMapView(
      overlays: overlays,
      marker: marker,
      onTap: onTap,
    );
  }
}

class _CanvasMapView extends StatelessWidget {
  const _CanvasMapView({
    required this.overlays,
    required this.marker,
    required this.onTap,
  });

  final Set<MapOverlay> overlays;
  final GeoCoordinate? marker;
  final ValueChanged<GeoCoordinate> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            final local = box?.globalToLocal(details.globalPosition);
            if (local == null) return;
            final size = box!.size;
            final normalizedX = (local.dx / size.width).clamp(0.0, 1.0);
            final normalizedY = (local.dy / size.height).clamp(0.0, 1.0);
            final lon = (normalizedX * 360.0) - 180.0;
            final lat = 90.0 - (normalizedY * 180.0);
            onTap(GeoCoordinate(lat: lat, lon: lon));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MapPainter(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
                  overlays: overlays,
                ),
              ),
              if (marker != null)
                Align(
                  alignment: Alignment(marker!.lon / 180, -marker!.lat / 90),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.color, required this.overlays});

  final Color color;
  final Set<MapOverlay> overlays;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = color.withValues(alpha: 0.05);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const steps = 6;
    for (var i = 1; i < steps; i++) {
      final x = size.width * i / steps;
      final y = size.height * i / steps;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (overlays.contains(MapOverlay.heatmap)) {
      final p = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.green.withValues(alpha: 0.12),
            Colors.orange.withValues(alpha: 0.12),
            Colors.red.withValues(alpha: 0.15),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, p);
    }

    if (overlays.contains(MapOverlay.radar)) {
      final p = Paint()..color = Colors.tealAccent.withValues(alpha: 0.08);
      for (var i = 0; i < 10; i++) {
        final r = size.shortestSide * (i / 10);
        canvas.drawCircle(size.center(Offset.zero), r, p);
      }
    }

    if (overlays.contains(MapOverlay.wind)) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var y = 12.0; y < size.height; y += 24) {
        for (var x = 12.0; x < size.width; x += 48) {
          canvas.drawLine(Offset(x, y), Offset(x + 22, y - 6), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.overlays != overlays;
  }
}

