import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../models/chart_models.dart';
import '../state_views.dart';

/// Colores y señales no cromáticas para cada nivel de stock.
/// Normal = verde + check, Bajo = ámbar + advertencia, Crítico = rojo + error.
extension StockLevelVisual on StockLevel {
  Color get chartColor => switch (this) {
    StockLevel.normal => AppColors.success,
    StockLevel.bajo => AppColors.warning,
    StockLevel.critico => AppColors.danger,
  };

  IconData get icon => switch (this) {
    StockLevel.normal => Icons.check_circle_outline,
    StockLevel.bajo => Icons.warning_amber_rounded,
    StockLevel.critico => Icons.error_outline,
  };
}

/// Barras horizontales de existencias. El estado se comunica con color,
/// icono y texto ("Normal/Bajo/Crítico"), no solo con el color.
class StockBarChart extends StatelessWidget {
  final List<StockItem> items;
  final StockItem? selected;
  final ValueChanged<StockItem> onSelect;

  const StockBarChart({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  static const double rowHeight = 46;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 140,
        child: StateView.empty(
          compact: true,
          title: 'Sin resultados',
          message: 'Ningún producto coincide con tu búsqueda.',
        ),
      );
    }
    final maxUnits = items.map((e) => e.units).reduce((a, b) => a > b ? a : b);
    final maxY = (maxUnits * 1.15).ceilToDouble().clamp(5, double.infinity);

    final data = BarChartData(
      rotationQuarterTurns: 1,
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY.toDouble(),
      minY: 0,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 128,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= items.length) return const SizedBox.shrink();
              final it = items[i];
              final sel = identical(it, selected);
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: SizedBox(
                  width: 122,
                  child: Row(
                    children: [
                      Icon(it.level.icon, size: 14, color: it.level.chartColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(
                                12,
                                AppColors.text,
                                weight: sel ? bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${it.units} un. · ${it.level.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(10.5, AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        allowTouchBarBackDraw: true,
        touchCallback: (event, response) {
          final spot = response?.spot;
          if (event is FlTapUpEvent && spot != null) {
            onSelect(items[spot.touchedBarGroupIndex]);
          }
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItem: (group, gi, rod, ri) {
            final it = items[gi];
            return BarTooltipItem(
              '${it.name}\n',
              ts(11, Colors.white70),
              children: [
                TextSpan(
                  text:
                      '${it.units} un. · ${it.level.label}\nBajo ≤ ${it.lowThreshold} · Crítico ≤ ${it.criticalThreshold}',
                  style: ts(12, Colors.white, weight: semi),
                ),
              ],
            );
          },
        ),
      ),
      barGroups: [
        for (var i = 0; i < items.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: items[i].units.toDouble(),
                width: 18,
                color: items[i].level.chartColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(6),
                ),
                borderSide: identical(items[i], selected)
                    ? const BorderSide(color: AppColors.navy, width: 2)
                    : BorderSide.none,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY.toDouble(),
                  color: AppColors.track,
                ),
              ),
            ],
          ),
      ],
    );

    return Semantics(
      label:
          'Existencias. ${[for (final e in items) '${e.name} ${e.units} unidades, ${e.level.label}'].join('; ')}.',
      child: SizedBox(
        height: rowHeight * items.length + 8,
        child: BarChart(
          data,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
