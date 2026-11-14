import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../models/chart_models.dart';
import '../state_views.dart';

/// Gráfico interactivo de líneas de ventas (`fl_chart`) con formato COP.
///
/// * Selección táctil de puntos con indicador visual resaltado y callback
///   contextual ([onPointSelected]).
/// * Tooltip enriquecido al tocar (muestra fecha/hora, valor exacto y variación
///   frente al período anterior cuando aplica).
/// * Opcional: zoom con pellizco y desplazamiento horizontal ([zoomable]).
/// * Opcional: segunda serie para comparar ([SalesSeries.previous]).
/// * Estado vacío cuando no hay puntos.
class SalesLineChart extends StatefulWidget {
  final SalesSeries series;
  final double height;
  final bool zoomable;
  final bool showComparison;
  final String currentLabel;
  final String previousLabel;
  final String valueLabel;
  final String Function(double) formatValue;
  final String Function(double) formatAxis;
  final void Function(SalesPoint? point, double? previousValue)? onPointSelected;

  const SalesLineChart({
    super.key,
    required this.series,
    this.height = 240,
    this.zoomable = false,
    this.showComparison = false,
    this.currentLabel = 'Actual',
    this.previousLabel = 'Anterior',
    this.valueLabel = 'Ventas',
    this.formatValue = fmtCop,
    this.formatAxis = fmtCopCompact,
    this.onPointSelected,
  });

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  final TransformationController _transform = TransformationController();
  int? _selectedIndex;

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  void didUpdateWidget(covariant SalesLineChart old) {
    super.didUpdateWidget(old);
    if (!_sameData(old.series, widget.series)) {
      _transform.value = Matrix4.identity();
      _selectedIndex = null;
    }
  }

  static bool _sameData(SalesSeries a, SalesSeries b) {
    if (a.current.length != b.current.length) return false;
    if (a.current.isEmpty) return true;
    return a.current.first.time == b.current.first.time &&
        a.current.last.time == b.current.last.time &&
        a.total == b.total;
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  String _axisDate(DateTime t) =>
      widget.series.hourly ? '${t.hour}h' : '${t.day} ${_months[t.month - 1]}';

  String _tipDate(DateTime t) => widget.series.hourly
      ? '${t.day} ${_months[t.month - 1]}, ${t.hour.toString().padLeft(2, '0')}:00'
      : '${t.day} ${_months[t.month - 1]} ${t.year}';

  double _niceMax(double v) {
    if (v <= 0) return 1;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final f = v / exp;
    final nice = f <= 1
        ? 1
        : f <= 2
        ? 2
        : f <= 2.5
        ? 2.5
        : f <= 5
        ? 5
        : 10;
    return nice * exp;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.series;
    if (s.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const StateView.empty(
          compact: true,
          title: 'Sin ventas en este período',
          message: 'Elige otro período o rango de fechas.',
        ),
      );
    }

    final prev = widget.showComparison ? s.previous : null;
    final n = s.current.length;
    final all = [...s.current, ...?prev];
    final rawMax = all.map((p) => p.value).reduce(math.max);
    final maxY = _niceMax(rawMax * 1.08);
    final yInterval = maxY / 4;
    final xInterval = math.max(1, (n / 5).ceil()).toDouble();

    final spots = [
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), s.current[i].value),
    ];
    final prevSpots = prev == null
        ? null
        : [
            for (var i = 0; i < math.min(n, prev.length); i++)
              FlSpot(i.toDouble(), prev[i].value),
          ];

    final data = LineChartData(
      minX: 0,
      maxX: (n - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: xInterval,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 1),
        getDrawingVerticalLine: (_) => FlLine(
          color: AppColors.border.withValues(alpha: 0.45),
          strokeWidth: 0.8,
          dashArray: const [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: yInterval,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              meta: meta,
              child: Text(widget.formatAxis(v), style: ts(10, AppColors.grey)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: xInterval,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if (v != i.toDouble() || i < 0 || i >= n) {
                return const SizedBox.shrink();
              }
              final isSel = _selectedIndex == i;
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _axisDate(s.current[i].time),
                  style: ts(
                    10,
                    isSel ? AppColors.primary : AppColors.grey,
                    weight: isSel ? bold : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          final spotsTouched = response?.lineBarSpots;
          if (event is FlTapUpEvent ||
              event is FlPanUpdateEvent ||
              event is FlLongPressMoveUpdate) {
            if (spotsTouched != null && spotsTouched.isNotEmpty) {
              final idx = spotsTouched.first.spotIndex;
              if (idx >= 0 && idx < s.current.length && _selectedIndex != idx) {
                setState(() => _selectedIndex = idx);
                final prevVal = (prev != null && idx < prev.length)
                    ? prev[idx].value
                    : null;
                widget.onPointSelected?.call(s.current[idx], prevVal);
              }
            }
          }
        },
        getTouchedSpotIndicator: (barData, spotIndexes) => [
          for (final _ in spotIndexes)
            TouchedSpotIndicatorData(
              FlLine(
                color: AppColors.primary.withValues(alpha: 0.45),
                strokeWidth: 1.5,
                dashArray: const [4, 3],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 5.5,
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                      strokeColor: Colors.white,
                    ),
              ),
            ),
        ],
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItems: (touched) => [
            for (final t in touched)
              if (t.barIndex == 0)
                LineTooltipItem(
                  '${_tipDate(s.current[t.spotIndex].time)}\n',
                  ts(11, Colors.white70),
                  children: [
                    TextSpan(
                      text:
                          '${widget.currentLabel}: ${widget.formatValue(t.y)}',
                      style: ts(12, Colors.white, weight: bold),
                    ),
                  ],
                )
              else
                LineTooltipItem(
                  '${widget.previousLabel}: ${widget.formatValue(t.y)}',
                  ts(12, const Color(0xFFB8C4D4)),
                ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: n > 2,
          curveSmoothness: 0.22,
          preventCurveOverShooting: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: n <= 16 || _selectedIndex != null,
            checkToShowDot: (spot, barData) =>
                n <= 14 || spot.x.round() == _selectedIndex,
            getDotPainter: (spot, percent, barData, index) {
              final isSelected = index == _selectedIndex;
              return FlDotCirclePainter(
                radius: isSelected ? 5.5 : 3.2,
                color: isSelected ? AppColors.navy : AppColors.primary,
                strokeWidth: isSelected ? 2.5 : 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x3800509E), Color(0x0000509E)],
            ),
          ),
        ),
        if (prevSpots != null)
          LineChartBarData(
            spots: prevSpots,
            isCurved: n > 2,
            curveSmoothness: 0.22,
            preventCurveOverShooting: true,
            color: AppColors.greyLight,
            barWidth: 2,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
          ),
      ],
    );

    final selIdx = (_selectedIndex != null && _selectedIndex! < n)
        ? _selectedIndex!
        : null;
    final selPoint = selIdx != null ? s.current[selIdx] : null;
    final selPrev = (selIdx != null && prev != null && selIdx < prev.length)
        ? prev[selIdx].value
        : null;

    return Semantics(
      label:
          '${widget.valueLabel}: $n puntos, total ${widget.formatValue(s.current.fold(0.0, (a, p) => a + p.value))}. '
          'Toca el gráfico para ver valores exactos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: widget.height,
            child: LineChart(
              data,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              transformationConfig: FlTransformationConfig(
                scaleAxis: widget.zoomable
                    ? FlScaleAxis.horizontal
                    : FlScaleAxis.none,
                minScale: 1,
                maxScale: 6,
                transformationController: widget.zoomable ? _transform : null,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: selPoint == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_tipDate(selPoint.time)} · ${widget.formatValue(selPoint.value)}'
                              '${selPrev != null ? ' (Ant: ${widget.formatValue(selPrev)})' : ''}',
                              style: ts(12, AppColors.navy, weight: semi),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedIndex = null);
                              widget.onPointSelected?.call(null, null);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Leyenda simple para las series del gráfico (actual vs. anterior).
class ChartLegend extends StatelessWidget {
  final List<(String, Color, bool)> items; // (texto, color, punteada)
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      for (final (label, color, dashed) in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < (dashed ? 3 : 1); i++)
                    Container(
                      width: dashed ? 5 : 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: ts(11, AppColors.grey)),
          ],
        ),
    ],
  );
}
