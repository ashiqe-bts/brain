import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/theme/brain_theme.dart';

class ProgressChartPoint {
  const ProgressChartPoint({
    required this.at,
    required this.value,
    required this.label,
    this.note,
  });

  final DateTime at;
  final double value;
  final String label;
  final String? note;
  bool get hollow => note != null;
}

class ProgressChartSeries {
  const ProgressChartSeries({
    required this.label,
    required this.color,
    required this.points,
  });

  final String label;
  final Color color;
  final List<ProgressChartPoint> points;
}

class ProgressSparkline extends StatelessWidget {
  const ProgressSparkline({
    super.key,
    required this.points,
    required this.color,
    required this.semanticLabel,
  });

  final List<ProgressChartPoint> points;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(
            points: points,
            color: color,
            grid: context.brain.outline,
          ),
        ),
      ),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.points,
    required this.color,
    required this.grid,
  });

  final List<ProgressChartPoint> points;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()
        ..color = grid.withValues(alpha: .35)
        ..strokeWidth = 1,
    );
    if (points.isEmpty) return;
    final values = points.map((point) => point.value);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    Offset offset(int index) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final ratio = maxValue == minValue
          ? .5
          : (points[index].value - minValue) / (maxValue - minValue);
      return Offset(x, size.height - 5 - ratio * (size.height - 10));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(offset(0).dx, offset(0).dy);
      for (var index = 1; index < points.length; index++) {
        final next = offset(index);
        path.lineTo(next.dx, next.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(offset(index), 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.grid != grid;
}

class ProgressLineChart extends StatefulWidget {
  const ProgressLineChart({
    super.key,
    required this.series,
    required this.valueLabel,
    this.minimum,
    this.maximum,
    this.height = 230,
  });

  final List<ProgressChartSeries> series;
  final String valueLabel;
  final double? minimum;
  final double? maximum;
  final double height;

  @override
  State<ProgressLineChart> createState() => _ProgressLineChartState();
}

class _ProgressLineChartState extends State<ProgressLineChart> {
  int selected = -1;

  List<(ProgressChartSeries, ProgressChartPoint)> get _points => [
    for (final series in widget.series)
      for (final point in series.points) (series, point),
  ]..sort((a, b) => a.$2.at.compareTo(b.$2.at));

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points.isEmpty) {
      return Semantics(
        label: 'No ${widget.valueLabel.toLowerCase()} history yet',
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'Complete a comparable session to start this chart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.brain.textMuted),
            ),
          ),
        ),
      );
    }
    final active = selected >= 0 && selected < points.length
        ? points[selected]
        : points.last;
    final summary = widget.series
        .where((series) => series.points.isNotEmpty)
        .map((series) {
          final latest = series.points.last;
          return '${series.label}, latest ${latest.label} on ${DateFormat.MMMd().format(latest.at)}';
        })
        .join('. ');
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousPointIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextPointIntent(),
      },
      actions: {
        _PreviousPointIntent: CallbackAction<_PreviousPointIntent>(
          onInvoke: (_) => setState(() {
            final current = selected < 0 ? points.length - 1 : selected;
            selected = math.max(0, current - 1);
          }),
        ),
        _NextPointIntent: CallbackAction<_NextPointIntent>(
          onInvoke: (_) => setState(() {
            selected = math.min(points.length - 1, selected + 1);
          }),
        ),
      },
      child: Semantics(
        focusable: true,
        label:
            '${widget.valueLabel} progress chart. $summary. Use left and right arrow keys to inspect points.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (var index = 0; index < widget.series.length; index++)
                  if (widget.series[index].points.isNotEmpty)
                    _LegendItem(series: widget.series[index], index: index),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final width = context.size?.width ?? 1;
                final fraction = (details.localPosition.dx / width).clamp(0, 1);
                setState(
                  () => selected = ((points.length - 1) * fraction).round(),
                );
              },
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ProgressChartPainter(
                    series: widget.series,
                    minimum: widget.minimum,
                    maximum: widget.maximum,
                    selectedPoint: active.$2,
                    grid: context.brain.outline,
                    text: context.brain.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                '${active.$1.label} · ${DateFormat.MMMd().add_jm().format(active.$2.at.toLocal())} · ${active.$2.label}${active.$2.note == null ? '' : ' · ${active.$2.note}'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousPointIntent extends Intent {
  const _PreviousPointIntent();
}

class _NextPointIntent extends Intent {
  const _NextPointIntent();
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.series, required this.index});

  final ProgressChartSeries series;
  final int index;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _markerIcon(index),
        color: series.color,
        size: 18,
        semanticLabel: 'Series ${index + 1}',
      ),
      const SizedBox(width: 5),
      Text(series.label),
    ],
  );
}

IconData _markerIcon(int index) => switch (index % 5) {
  0 => Icons.circle,
  1 => Icons.square,
  2 => Icons.change_history,
  3 => Icons.diamond,
  _ => Icons.add,
};

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({
    required this.series,
    required this.selectedPoint,
    required this.grid,
    required this.text,
    this.minimum,
    this.maximum,
  });

  final List<ProgressChartSeries> series;
  final ProgressChartPoint selectedPoint;
  final Color grid;
  final Color text;
  final double? minimum;
  final double? maximum;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0, top = 12.0, right = 8.0, bottom = 28.0;
    final area = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final points = series.expand((item) => item.points).toList();
    final minDate = points
        .map((point) => point.at)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = points
        .map((point) => point.at)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final rawMin = points.map((point) => point.value).reduce(math.min);
    final rawMax = points.map((point) => point.value).reduce(math.max);
    final padding = rawMin == rawMax
        ? math.max(1, rawMin.abs() * .1)
        : (rawMax - rawMin) * .12;
    final minValue = minimum ?? rawMin - padding;
    final maxValue = maximum ?? rawMax + padding;
    final dateSpan = math.max(1, maxDate.difference(minDate).inMilliseconds);
    Offset offset(ProgressChartPoint point) {
      final x =
          area.left +
          area.width * point.at.difference(minDate).inMilliseconds / dateSpan;
      final ratio =
          (point.value - minValue) / math.max(.0001, maxValue - minValue);
      return Offset(x, area.bottom - area.height * ratio.clamp(0, 1));
    }

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = area.top + area.height * index / 4;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), gridPaint);
      final value = maxValue - (maxValue - minValue) * index / 4;
      _drawText(
        canvas,
        value.toStringAsFixed(value.abs() < 10 ? 1 : 0),
        Offset(0, y - 7),
        text,
      );
    }

    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final item = series[seriesIndex];
      final trend = item.points.where((point) => !point.hollow).toList();
      if (trend.length > 1) {
        final path = Path()
          ..moveTo(offset(trend.first).dx, offset(trend.first).dy);
        for (final point in trend.skip(1)) {
          final position = offset(point);
          path.lineTo(position.dx, position.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = item.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
      for (final point in item.points) {
        final position = offset(point);
        _drawMarker(
          canvas,
          position,
          item.color,
          seriesIndex,
          hollow: point.hollow,
          selected: identical(point, selectedPoint),
        );
      }
    }
    _drawText(
      canvas,
      DateFormat.MMMd().format(minDate),
      Offset(area.left, area.bottom + 7),
      text,
    );
    final end = DateFormat.MMMd().format(maxDate);
    final painter = TextPainter(
      text: TextSpan(
        text: end,
        style: TextStyle(color: text, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(area.right - painter.width, area.bottom + 7));
  }

  void _drawText(Canvas canvas, String value, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  void _drawMarker(
    Canvas canvas,
    Offset at,
    Color color,
    int index, {
    required bool hollow,
    required bool selected,
  }) {
    final paint = Paint()
      ..color = color
      ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = selected ? 3 : 2;
    final radius = selected ? 6.5 : 4.5;
    switch (index % 5) {
      case 1:
        canvas.drawRect(
          Rect.fromCenter(center: at, width: radius * 2, height: radius * 2),
          paint,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy - radius)
            ..lineTo(at.dx + radius, at.dy + radius)
            ..lineTo(at.dx - radius, at.dy + radius)
            ..close(),
          paint,
        );
      case 3:
        canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy - radius)
            ..lineTo(at.dx + radius, at.dy)
            ..lineTo(at.dx, at.dy + radius)
            ..lineTo(at.dx - radius, at.dy)
            ..close(),
          paint,
        );
      case 4:
        canvas.drawLine(
          Offset(at.dx - radius, at.dy),
          Offset(at.dx + radius, at.dy),
          paint,
        );
        canvas.drawLine(
          Offset(at.dx, at.dy - radius),
          Offset(at.dx, at.dy + radius),
          paint,
        );
      default:
        canvas.drawCircle(at, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedPoint != selectedPoint ||
      oldDelegate.grid != grid ||
      oldDelegate.text != text;
}
