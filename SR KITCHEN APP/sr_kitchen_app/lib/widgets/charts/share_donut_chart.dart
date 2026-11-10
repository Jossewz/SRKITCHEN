import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';

/// Dona de participación: ingresos del producto frente a las ventas totales
/// del mismo período. Tocar un sector lo resalta y actualiza el texto central.
class ShareDonutChart extends StatefulWidget {
  final String productName;
  final double productRevenue;
  final double totalSales;
  final double height;

  const ShareDonutChart({
    super.key,
    required this.productName,
    required this.productRevenue,
    required this.totalSales,
    this.height = 190,
  });

  @override
  State<ShareDonutChart> createState() => _ShareDonutChartState();
}

class _ShareDonutChartState extends State<ShareDonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final rev = widget.productRevenue.clamp(0, widget.totalSales).toDouble();
    final rest = (widget.totalSales - rev).clamp(0, double.infinity).toDouble();
    final pct = widget.totalSales == 0 ? 0.0 : rev / widget.totalSales * 100;
    final restPct = 100 - pct;

    final centerPct = _touched == 1 ? restPct : pct;
    final centerLabel = _touched == 1 ? 'Resto del menú' : widget.productName;

    PieChartSectionData section(int i, double v, Color c) {
      final t = _touched == i;
      return PieChartSectionData(
        value: v <= 0 ? 0.0001 : v,
        color: c,
        radius: t ? 34 : 28,
        showTitle: false,
      );
    }

    return Row(
      children: [
        SizedBox(
          width: widget.height,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: widget.height / 2 - 40,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                  sections: [
                    section(0, rev, AppColors.primary),
                    section(1, rest, AppColors.track),
                  ],
                  pieTouchData: PieTouchData(
                    touchCallback: (event, resp) {
                      if (!event.isInterestedForInteractions ||
                          resp?.touchedSection == null) {
                        return;
                      }
                      final i = resp!.touchedSection!.touchedSectionIndex;
                      if (event is FlTapUpEvent && i >= 0) {
                        setState(() => _touched = _touched == i ? null : i);
                      }
                    },
                  ),
                ),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fmtPct(centerPct),
                      style: ts(18, AppColors.navy, weight: bold),
                    ),
                    Text(
                      centerLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: ts(10, AppColors.grey, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(
                AppColors.primary,
                widget.productName,
                '${fmtCop(rev)} · ${fmtPct(pct)}',
              ),
              const SizedBox(height: 10),
              _legend(
                AppColors.border,
                'Resto del menú',
                '${fmtCop(rest)} · ${fmtPct(restPct)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Porcentaje de los ingresos totales del período.',
                style: ts(11, AppColors.greyLight, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color c, String title, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 3),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.greyLight, width: 0.5),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(12, AppColors.text, weight: semi),
            ),
            Text(value, style: ts(11, AppColors.grey)),
          ],
        ),
      ),
    ],
  );
}
