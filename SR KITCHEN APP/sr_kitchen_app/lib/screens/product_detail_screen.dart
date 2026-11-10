import 'package:flutter/material.dart';

import '../data/demo_chart_data.dart';
import '../models/api_models.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts/sales_line_chart.dart';
import '../widgets/charts/share_donut_chart.dart';
import '../widgets/motion.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  /// Período con el que se abre (por ejemplo, el elegido en el Top 5).
  final SalesPeriod initialPeriod;
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.initialPeriod = SalesPeriod.week,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _period = widget.initialPeriod.index;

  /// false = unidades, true = ingresos. Se muestran en gráficos separados
  /// (una sola magnitud por eje), alternando con este selector.
  bool _showRevenue = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final period = SalesPeriodX.fromIndex(_period);
    final fallbackStats = DemoProductStats.statsFor(p, period) ??
        ProductRanking(
          product: p,
          units: p.sold,
          revenue: p.sold * p.price,
          share: 0,
          position: -1,
        );
    final rankings = KitchenDataService.instance.rankings;
    final rIdx = rankings.indexWhere(
      (r) => r.nombre.trim().toLowerCase() == p.name.trim().toLowerCase(),
    );
    final PlatilloRankingModel? rankingItem = rIdx >= 0 ? rankings[rIdx] : null;

    final unitsSold = rankingItem?.cantidadVendida ?? fallbackStats.units;
    final totalRevenue = rankingItem?.totalVentas ?? fallbackStats.revenue;
    final sharePct = rankingItem?.porcentaje ?? fallbackStats.share;
    final rankingPos = rankingItem != null ? (rIdx + 1) : fallbackStats.position;

    final totalSales = DemoSales.totalFor(period);
    final unitsSeries = DemoProductStats.unitsSeries(p, period);
    final points = _showRevenue
        ? DemoProductStats.revenueSeries(p, period)
        : unitsSeries;
    final series = SalesSeries(current: points, hourly: period.isHourly);

    final invItem = KitchenDataService.instance.inventory
        .where(
          (i) => i.nombre.trim().toLowerCase() == p.name.trim().toLowerCase(),
        )
        .firstOrNull;
    final stockAvailable = invItem?.stockActual ?? p.stockUnits;
    final stockStatusLabel = invItem != null
        ? invItem.stockLevel.label
        : p.stock.label;
    final stockStatusColor = invItem != null
        ? invItem.stockLevel.color
        : p.stock.color;

    final inventoryText = stockAvailable != null
        ? 'Inventario: $stockAvailable disponibles · $stockStatusLabel'
        : 'Inventario: $stockStatusLabel';

    return ScreenScaffold(
      child: Column(
        children: [
          ScreenHeader(
            title: p.name,
            subtitle: p.category,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: 'product-photo-${p.imageKey}',
                    child: ProductPhoto(
                      product: p,
                      height: 120,
                      width: double.infinity,
                      circle: false,
                      radius: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    style: ts(22, AppColors.navy, weight: bold, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${p.category} · ${fmtCop(p.price)} c/u',
                    style: ts(14, AppColors.grey, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  PeriodFilter(
                    selected: _period,
                    onChanged: (i) => setState(() => _period = i),
                  ),
                  const SizedBox(height: 12),
                  // TODO(API): estad\u00edsticas reales del producto por per\u00edodo.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_period),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankingPos > 0
                              ? '$unitsSold vendidas     ·     #$rankingPos en ranking'
                              : '$unitsSold vendidas · fuera del Top ranking',
                          style: ts(
                            18,
                            AppColors.navy,
                            weight: bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fmtPct(sharePct)} de las ventas · ${fmtCop(totalRevenue)}',
                          style: ts(13, AppColors.grey, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    child: AppCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _showRevenue
                                      ? (period.isHourly
                                            ? 'Ingresos por hora (COP)'
                                            : 'Ingresos por d\u00eda (COP)')
                                      : (period.isHourly
                                            ? 'Unidades por hora'
                                            : 'Unidades por d\u00eda'),
                                  style: ts(
                                    15,
                                    AppColors.navy,
                                    weight: bold,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              SegmentedButton<bool>(
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    label: Text('Uds'),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text('COP'),
                                  ),
                                ],
                                selected: {_showRevenue},
                                onSelectionChanged: (s) =>
                                    setState(() => _showRevenue = s.first),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SalesLineChart(
                            series: series,
                            height: 210,
                            zoomable: unitsSeries.length > 12,
                            valueLabel: _showRevenue ? 'Ingresos' : 'Unidades',
                            currentLabel: _showRevenue
                                ? 'Ingresos'
                                : 'Unidades',
                            formatValue: _showRevenue
                                ? fmtCop
                                : (v) => '${v.round()} uds',
                            formatAxis: _showRevenue
                                ? fmtCopCompact
                                : (v) => v.round().toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 1,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participaci\u00f3n en las ventas',
                            style: ts(
                              15,
                              AppColors.navy,
                              weight: bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ShareDonutChart(
                            productName: p.name,
                            productRevenue: totalRevenue,
                            totalSales: totalSales,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    inventoryText,
                    style: ts(13, stockStatusColor, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA: PERFIL  (frame "Principal / Configuración y perfil")
// ─────────────────────────────────────────────────────────────────────────────
