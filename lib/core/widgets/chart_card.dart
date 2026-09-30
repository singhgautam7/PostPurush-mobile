import 'dart:math' as math;

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../util/format.dart';
import 'cards.dart';

/// One series on a line chart.
@immutable
class ChartSeries {
  const ChartSeries({
    required this.values,
    required this.colour,
    this.dashed = false,
    this.dots = false,
    this.strokeWidth = 2.5,
  });

  final List<double> values;
  final Color colour;
  final bool dashed;
  final bool dots;
  final double strokeWidth;

  @override
  bool operator ==(Object other) =>
      other is ChartSeries &&
      other.colour == colour &&
      other.dashed == dashed &&
      other.dots == dots &&
      other.strokeWidth == strokeWidth &&
      _same(other.values, values);

  @override
  int get hashCode =>
      Object.hash(colour, dashed, dots, strokeWidth, Object.hashAll(values));

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The board's chart: a `divider` grid of three rules, one solid `primary`
/// series with dots, one dashed `accent` comparison, and mono 9 axis labels.
/// No fills, no gradients, no chart package.
class LineChartPainter extends CustomPainter {
  const LineChartPainter({
    required this.series,
    required this.gridColour,
    required this.labelColour,
    required this.maxValue,
    required this.labels,
    required this.textScaler,
  });

  final List<ChartSeries> series;
  final Color gridColour;
  final Color labelColour;

  /// The top of the scale. Rounded by the caller so the label is a round
  /// number, which is what makes `800 ms` and `400` readable.
  final double maxValue;

  /// The two right-hand axis labels, top first.
  final List<String> labels;
  final TextScaler textScaler;

  static const double _top = 10;
  static const double _bottom = 110;
  static const double _height = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.height / _height;
    double y(double at) => at * scale;

    final Paint grid = Paint()
      ..color = gridColour
      ..strokeWidth = 1;
    for (final double rule in <double>[_top, 60, _bottom]) {
      canvas.drawLine(Offset(0, y(rule)), Offset(size.width, y(rule)), grid);
    }

    // The plot inset matches the board's 20dp first point and 20dp tail.
    const double inset = 20;
    final double plotWidth = math.max(1, size.width - inset * 2);
    final double span = maxValue <= 0 ? 1 : maxValue;

    for (final ChartSeries s in series) {
      if (s.values.length < 2) continue;
      final List<Offset> points = <Offset>[
        for (int i = 0; i < s.values.length; i++)
          Offset(
            inset + plotWidth * i / (s.values.length - 1),
            y(
              _bottom -
                  (_bottom - _top) * (s.values[i].clamp(0, span) / span),
            ),
          ),
      ];
      final Paint stroke = Paint()
        ..color = s.colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(s.dashed ? _dash(path) : path, stroke);
      if (s.dots) {
        final Paint dot = Paint()..color = s.colour;
        for (final Offset p in points) {
          canvas.drawCircle(p, 3, dot);
        }
      }
    }

    for (int i = 0; i < labels.length && i < 2; i++) {
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppType.monoAxis.copyWith(color: labelColour),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      label.paint(
        canvas,
        Offset(
          size.width - label.width - 2,
          y(i == 0 ? _top : 60) + 2,
        ),
      );
      label.dispose();
    }
  }

  /// A 4-on, 4-off dash, which is what the board's `stroke-dasharray` is.
  static Path _dash(Path source) {
    const double on = 4;
    const double off = 4;
    final Path out = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double at = 0;
      while (at < metric.length) {
        final double end = math.min(at + on, metric.length);
        out.addPath(metric.extractPath(at, end), Offset.zero);
        at = end + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(LineChartPainter old) =>
      old.maxValue != maxValue ||
      old.gridColour != gridColour ||
      old.labelColour != labelColour ||
      old.textScaler != textScaler ||
      !_sameLabels(old.labels, labels) ||
      !_sameSeries(old.series, series);

  static bool _sameLabels(List<String> a, List<String> b) =>
      a.length == b.length &&
      List<int>.generate(a.length, (int i) => i).every((int i) => a[i] == b[i]);

  static bool _sameSeries(List<ChartSeries> a, List<ChartSeries> b) =>
      a.length == b.length &&
      List<int>.generate(a.length, (int i) => i).every((int i) => a[i] == b[i]);
}

/// A titled card holding one chart, its legend and its x-axis labels.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.series,
    required this.xLabels,
    this.note,
    this.legend = const <(String, bool)>[],
    this.unit = '',
    this.height = 120,
    super.key,
  });

  final String title;

  /// A mono note on the right instead of a legend: `48.1 req/s`, `live`.
  final String? note;
  final List<ChartSeries> series;

  /// `Mon`..`Sun`, or an empty list for a chart with no labelled axis.
  final List<String> xLabels;

  /// `('avg', false)` for a solid swatch, `('P95', true)` for a dashed one.
  final List<(String, bool)> legend;

  /// Appended to the top axis label: `ms`.
  final String unit;
  final double height;

  /// Rounds the scale up to something a label can print: 1 · 2 · 5 · 10 · 20…
  static double niceMax(Iterable<double> values) {
    final double peak = values.isEmpty
        ? 1
        : values.reduce((double a, double b) => a > b ? a : b);
    if (peak <= 0) return 1;
    final double magnitude = math.pow(10, (math.log(peak) / math.ln10).floor())
        .toDouble();
    for (final double step in <double>[1, 2, 2.5, 5, 10]) {
      final double candidate = magnitude * step;
      if (candidate >= peak) return candidate;
    }
    return magnitude * 10;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double max = niceMax(series.expand((ChartSeries s) => s.values));
    final String topLabel =
        '${_short(max)}${unit.isEmpty ? '' : ' $unit'}';
    final String midLabel = _short(max / 2);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.md,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppType.titleMedium.copyWith(color: c.onSurface),
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Space.md,
                  children: <Widget>[
                    for (final (String label, bool dashed) in legend)
                      _LegendItem(label: label, dashed: dashed),
                  ],
                ),
            ],
          ),
          RepaintBoundary(
            child: SizedBox(
              height: height,
              child: CustomPaint(
                size: Size.infinite,
                painter: LineChartPainter(
                  series: series,
                  gridColour: c.divider,
                  labelColour: c.onSurfaceVariant,
                  maxValue: max,
                  labels: <String>[topLabel, midLabel],
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ),
          ),
          if (xLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: Space.md, right: Space.row),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final String label in xLabels)
                    Text(
                      label,
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _short(double value) => value >= 1000
      ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
      : value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.dashed});

  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        SizedBox(
          width: 14,
          height: 3,
          child: dashed
              ? CustomPaint(painter: _DashSwatch(c.accent))
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: Radii.fullR,
                  ),
                ),
        ),
        Text(
          label,
          style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DashSwatch extends CustomPainter {
  const _DashSwatch(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = 2;
    double at = 0;
    while (at < size.width) {
      canvas.drawLine(
        Offset(at, size.height / 2),
        Offset(math.min(at + 4, size.width), size.height / 2),
        paint,
      );
      at += 8;
    }
  }

  @override
  bool shouldRepaint(_DashSwatch old) => old.colour != colour;
}

/// The status-code distribution: one 12dp bar split by band, then a two-column
/// legend with a dot, a label and a count.
class StatusBreakdownCard extends StatelessWidget {
  const StatusBreakdownCard({
    required this.counts,
    required this.total,
    super.key,
  });

  /// In band order: 2xx, 3xx, 4xx, 5xx.
  final List<int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<Color> colours = <Color>[
      c.success,
      c.hue(AppColors.catHues[1]),
      c.hue(AppColors.catHues[3]),
      c.danger,
    ];
    const List<String> labels = <String>['2xx', '3xx', '4xx', '5xx'];
    final int sum = counts.fold(0, (int a, int b) => a + b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.md,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Status codes',
                  style: AppType.titleMedium.copyWith(color: c.onSurface),
                ),
              ),
              Text(
                '${Fmt.thousands(total)} responses',
                style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: Radii.fullR,
            child: SizedBox(
              height: 12,
              child: sum == 0
                  ? ColoredBox(color: c.surfaceContainerHigh)
                  : Row(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (int i = 0; i < counts.length; i++)
                          if (counts[i] > 0)
                            Expanded(
                              flex: counts[i],
                              child: ColoredBox(color: colours[i]),
                            ),
                      ],
                    ),
            ),
          ),
          // Two columns, so four bands sit in two rows as the board draws them.
          Column(
            spacing: 6,
            children: <Widget>[
              for (int row = 0; row < 2; row++)
                Row(
                  spacing: Space.lg,
                  children: <Widget>[
                    for (int col = 0; col < 2; col++)
                      Expanded(
                        child: _BandLegend(
                          colour: colours[row * 2 + col],
                          label: labels[row * 2 + col],
                          count: counts[row * 2 + col],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

}

class _BandLegend extends StatelessWidget {
  const _BandLegend({
    required this.colour,
    required this.label,
    required this.count,
  });

  final Color colour;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Row(
      spacing: Space.sm,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            label,
            style: AppType.chipLabel.copyWith(color: c.onSurface),
          ),
        ),
        Text(
          Fmt.thousands(count),
          style: AppType.monoTabular.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}
