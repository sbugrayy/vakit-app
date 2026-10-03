// Kıble pusula ekranı, kadran çizimi ve durum bileşenleri.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/qibla/cubit/qibla_cubit.dart';
import 'package:vakit/qibla/cubit/qibla_state.dart';
import 'package:vakit/qibla/repository/heading_source.dart';
import 'package:vakit/theme/app_spacing.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = QiblaCubit(
          locationStore: context.read<LocationStore>(),
          headingSource: context.read<HeadingSource>(),
        );
        unawaited(cubit.start());
        return cubit;
      },
      child: const QiblaView(),
    );
  }
}

class QiblaView extends StatelessWidget {
  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıble'),
      ),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          return switch (state) {
            QiblaInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            QiblaNeedsCoordinates() => const _NeedsCoordinatesView(),
            QiblaUnavailable(:final message) => _UnavailableView(
              message: message,
            ),
            QiblaReady() => _ReadyView(state: state),
          };
        },
      ),
    );
  }
}

class _NeedsCoordinatesView extends StatelessWidget {
  const _NeedsCoordinatesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: AppSpacing.xxl * 2,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Kıble yönü için konumunuzun koordinatı gerekiyor. '
              "Konum Seçimi'nde 'Konumumu bul'u kullanın.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () async {
                await context.push('/konum');
                if (context.mounted) {
                  await context.read<QiblaCubit>().start();
                }
              },
              child: const Text('Konumumu bul'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: AppSpacing.xxl * 2,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});

  final QiblaReady state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = state.reading?.heading ?? 0;
    final needsCalibration = state.reading?.needsCalibration ?? false;
    final formattedDistance = NumberFormat.decimalPattern(
      'tr',
    ).format(state.distanceKm.round());

    final (alignmentText, alignmentColor) = switch (state.aligned) {
      true => ('Kıbleye dönüksünüz', theme.colorScheme.primary),
      false => switch (state.turn) {
        final turn? when turn > 0 => (
          'Telefonu sağa çevirin',
          theme.colorScheme.onSurface,
        ),
        final turn? => (
          'Telefonu sola çevirin',
          theme.colorScheme.onSurface,
        ),
        null => (
          'Pusula aranıyor...',
          theme.colorScheme.onSurfaceVariant,
        ),
      },
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsCalibration) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Pusula hassasiyeti düşük. '
                          'Telefonu havada 8 çizerek kalibre edin.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: CompassDialPainter(
                  heading: heading,
                  bearing: state.bearing,
                  isAligned: state.aligned,
                  colorScheme: theme.colorScheme,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${state.bearing.round()}°',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Kıble açısı',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              alignmentText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: alignmentColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Kâbe'ye uzaklık $formattedDistance km",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassDialPainter extends CustomPainter {
  CompassDialPainter({
    required this.heading,
    required this.bearing,
    required this.isAligned,
    required this.colorScheme,
  });

  final double heading;
  final double bearing;
  final bool isAligned;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - AppSpacing.lg;

    final circlePaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas
      ..drawCircle(center, radius, circlePaint)
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-heading * math.pi / 180);

    final tickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2.5;

    for (var i = 0; i < 360; i += 15) {
      final rad = i * math.pi / 180;
      final isMajor = i % 90 == 0;
      final tickLength = isMajor ? AppSpacing.md : AppSpacing.sm;
      final outerR = radius - AppSpacing.xs;
      final innerR = outerR - tickLength;

      final p1 = Offset(innerR * math.sin(rad), -innerR * math.cos(rad));
      final p2 = Offset(outerR * math.sin(rad), -outerR * math.cos(rad));

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    _drawDirectionLabels(canvas, radius);
    _drawKaabaMarker(canvas, radius);

    canvas.restore();

    _drawPhoneIndicator(canvas, center, radius);
  }

  void _drawDirectionLabels(Canvas canvas, double radius) {
    final labels = <int, String>{
      0: 'K',
      90: 'D',
      180: 'G',
      270: 'B',
    };

    final labelDistance = radius - AppSpacing.xl;

    for (final entry in labels.entries) {
      final rad = entry.key * math.pi / 180;
      final isNorth = entry.key == 0;
      final textSpan = TextSpan(
        text: entry.value,
        style: TextStyle(
          color: isNorth ? colorScheme.error : colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final x = labelDistance * math.sin(rad) - textPainter.width / 2;
      final y = -labelDistance * math.cos(rad) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawKaabaMarker(Canvas canvas, double radius) {
    final rad = bearing * math.pi / 180;
    final markerDistance = radius - AppSpacing.xl;
    final center = Offset(
      markerDistance * math.sin(rad),
      -markerDistance * math.cos(rad),
    );

    final linePaint = Paint()
      ..color = isAligned ? colorScheme.primary : colorScheme.secondary
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset.zero,
      Offset(
        (radius - AppSpacing.xs) * math.sin(rad),
        -(radius - AppSpacing.xs) * math.cos(rad),
      ),
      linePaint,
    );

    final markerPaint = Paint()
      ..color = isAligned ? colorScheme.primary : colorScheme.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, AppSpacing.sm, markerPaint);

    final innerPaint = Paint()
      ..color = isAligned ? colorScheme.onPrimary : colorScheme.onSecondary
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: AppSpacing.sm,
        height: AppSpacing.sm,
      ),
      innerPaint,
    );
  }

  void _drawPhoneIndicator(Canvas canvas, Offset center, double radius) {
    final indicatorPaint = Paint()
      ..color = isAligned ? colorScheme.primary : colorScheme.error
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius - AppSpacing.sm)
      ..lineTo(center.dx - AppSpacing.sm, center.dy - radius - AppSpacing.lg)
      ..lineTo(center.dx + AppSpacing.sm, center.dy - radius - AppSpacing.lg)
      ..close();

    canvas.drawPath(path, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.bearing != bearing ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.colorScheme != colorScheme;
  }
}
