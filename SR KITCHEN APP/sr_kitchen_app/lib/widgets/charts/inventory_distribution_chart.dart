import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/api_models.dart';
import '../../models/app_models.dart';
import 'stock_bar_chart.dart';

/// Gráfica circular interactiva de distribución de inventario por nivel de stock
/// (`CRÍTICO <= 5`, `BAJO 6..15`, `NORMAL > 15`).
///
/// Tocar un segmento del anillo o su indicador lateral selecciona/filtra esa
/// clasificación y actualiza el resumen central.
class InventoryDistributionChart extends StatelessWidget {
  final InventarioNivelesModel niveles;
  final StockLevel? selectedLevel;
  final ValueChanged<StockLevel?> onSelectLevel;
  final double size;

  const InventoryDistributionChart({
    super.key,
    required this.niveles,
    required this.selectedLevel,
    required this.onSelectLevel,
    this.size = 156,
  });

  @override
  Widget build(BuildContext context) {
    final total = niveles.totalProductos;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final segments = <({StockLevel level, int count, String rule})>[
      (
        level: StockLevel.critico,
        count: niveles.conteoCriticos,
        rule: '≤ 5 uds',
      ),
      (
        level: StockLevel.bajo,
        count: niveles.conteoBajos,
        rule: '6–15 uds',
      ),
      (
        level: StockLevel.normal,
        count: niveles.conteoNormales,
        rule: '> 15 uds',
      ),
    ];

    final activeSegment = selectedLevel == null
        ? null
        : segments.firstWhere((s) => s.level == selectedLevel);
    final centerCount = activeSegment != null ? activeSegment.count : total;
    final centerLabel = activeSegment != null
        ? activeSegment.level.label
        : 'Total ítems';
    final centerPct = activeSegment != null && total > 0
        ? fmtPct(activeSegment.count / total * 100)
        : null;

    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: size / 2 - 34,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                  sections: [
                    for (var i = 0; i < segments.length; i++)
                      PieChartSectionData(
                        value: segments[i].count <= 0
                            ? 0.001
                            : segments[i].count.toDouble(),
                        color: selectedLevel == null ||
                                selectedLevel == segments[i].level
                            ? segments[i].level.chartColor
                            : segments[i].level.chartColor.withValues(
                                alpha: 0.28,
                              ),
                        radius: selectedLevel == segments[i].level ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                  pieTouchData: PieTouchData(
                    touchCallback: (event, resp) {
                      if (!event.isInterestedForInteractions ||
                          resp?.touchedSection == null) {
                        return;
                      }
                      final idx = resp!.touchedSection!.touchedSectionIndex;
                      if (event is FlTapUpEvent &&
                          idx >= 0 &&
                          idx < segments.length) {
                        final tapped = segments[idx].level;
                        onSelectLevel(selectedLevel == tapped ? null : tapped);
                      }
                    },
                  ),
                ),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$centerCount',
                    style: ts(
                      20,
                      activeSegment?.level.chartColor ?? AppColors.navy,
                      weight: bold,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: ts(11, AppColors.grey, weight: semi),
                  ),
                  if (centerPct != null)
                    Text(
                      centerPct,
                      style: ts(10, AppColors.greyLight),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final seg in segments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelectLevel(
                      selectedLevel == seg.level ? null : seg.level,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selectedLevel == seg.level
                            ? seg.level.chartColor.withValues(alpha: 0.12)
                            : AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedLevel == seg.level
                              ? seg.level.chartColor
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            seg.level.icon,
                            size: 16,
                            color: seg.level.chartColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${seg.level.label} (${seg.rule})',
                                  style: ts(
                                    12,
                                    AppColors.text,
                                    weight: selectedLevel == seg.level
                                        ? bold
                                        : semi,
                                  ),
                                ),
                                Text(
                                  total > 0
                                      ? '${fmtPct(seg.count / total * 100)} del inventario'
                                      : '0 %',
                                  style: ts(10.5, AppColors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${seg.count}',
                            style: ts(15, AppColors.navy, weight: bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

