import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../models/chart_models.dart';
import '../state_views.dart';

/// Barras horizontales del Ranking de Platillos (`fl_chart`, `rotationQuarterTurns: 1`).
///
/// * Tocar una barra la selecciona ([selectedIndex]) y notifica con [onSelect].
/// * Soporta visualizar por Unidades Vendidas ([showRevenue] = false) o por
///   Recaudación en COP ([showRevenue] = true).
class TopProductsBarChart extends StatelessWidget {
  final List<ProductRanking> items;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool showRevenue;

  const TopProductsBarChart({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.showRevenue = false,
  });

  static const double rowHeight = 54;

  double _val(ProductRanking r) => showRevenue ? r.revenue : r.units.toDouble();

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 160,
        child: StateView.empty(
          compact: true,
          title: 'Sin productos vendidos',
          message: 'No hay ventas de productos en este período.',
        ),
      );
    }
    final maxRaw = items.map(_val).reduce(math.max);
    final maxY = maxRaw <= 0 ? 10.0 : (maxRaw * 1.12).ceilToDouble();

    final data = BarChartData(
      rotationQuarterTurns: 1,
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
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
            reservedSize: 120,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= items.length) return const SizedBox.shrink();
              final it = items[i];
              final sel = i == selectedIndex;
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: SizedBox(
                  width: 114,
                  child: Row(
                    children: [
                      Text(
                        '${it.position}',
                        style: ts(12, AppColors.primary, weight: bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(
                                12,
                                AppColors.text,
                                weight: sel ? bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              showRevenue
                                  ? '${fmtCopCompact(it.revenue)} · ${fmtPct(it.share)}'
                                  : '${it.units} uds · ${fmtPct(it.share)}',
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
            onSelect(spot.touchedBarGroupIndex);
          }
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
            '#${items[gi].position} · ${items[gi].product.name}\n',
            ts(11, Colors.white70),
            children: [
              TextSpan(
                text:
                    '${items[gi].units} uds · ${fmtCop(items[gi].revenue)} (${fmtPct(items[gi].share)})',
                style: ts(12, Colors.white, weight: bold),
              ),
            ],
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < items.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _val(items[i]),
                width: 22,
                color: i == selectedIndex
                    ? AppColors.primary
                    : AppColors.barSoft,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(6),
                ),
                borderSide: i == selectedIndex
                    ? const BorderSide(color: AppColors.navy, width: 2)
                    : BorderSide.none,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppColors.track,
                ),
              ),
            ],
          ),
      ],
    );

    return Semantics(
      label:
          'Top ${items.length} productos. ${[for (final e in items) '${e.product.name} ${e.units} unidades'].join(', ')}.',
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
