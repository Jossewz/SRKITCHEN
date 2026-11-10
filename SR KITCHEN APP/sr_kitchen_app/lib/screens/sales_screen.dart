import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/api_models.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts/sales_line_chart.dart';
import '../widgets/motion.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'top5_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _period = 1;
  DateTimeRange? _range;
  bool _compare = true;
  bool _showBestSaleItems = false;

  @override
  void initState() {
    super.initState();
    unawaited(KitchenDataService.instance.loadSalesSeries(SalesPeriod.week));
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final shell = MainShell.maybeOf(context);
    final svc = KitchenDataService.instance;

    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final period = SalesPeriodX.fromIndex(_period);
        final series = _range != null
            ? svc.salesSeriesForRange(_range!)
            : svc.salesSeriesForPeriod(period);
        final ventasDto = svc.ventasForPeriod(period);
        final promedioDto = svc.promedioForPeriod(period);
        final mejorVenta = svc.mejorVenta;
        final ranking = svc.rankingModelsForPeriod(period, limite: 5);

        final hasData = !series.isEmpty;
        final total = hasData ? series.total : 0.0;
        final avg = hasData ? total / series.current.length : 0.0;
        final bestPoint = hasData ? series.best : null;
        final prevTotal = series.previousTotal;
        final growth = (prevTotal == null || prevTotal == 0)
            ? null
            : (total - prevTotal) / prevTotal * 100;
        final canCompare = series.previous != null;

        return ScreenScaffold(
          child: Column(
            children: [
              const ScreenHeader(
                title: 'Ventas',
                subtitle: 'Rendimiento financiero y récord comercial',
                showBell: true,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => svc.refreshAll(period: period),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SyncStatusBanner(
                          onRefresh: () => svc.refreshAll(period: period),
                        ),
                        const SizedBox(height: 10),
                        PeriodFilter(
                          selected: _period,
                          onChanged: (i) {
                            setState(() {
                              _period = i;
                              _range = null;
                            });
                            unawaited(
                              svc.loadSalesSeries(SalesPeriodX.fromIndex(i)),
                            );
                          },
                          height: 36,
                          fontSize: 12,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _pickRange,
                          child: SizedBox(
                            height: 26,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _range == null
                                        ? 'Rango personalizado'
                                        : '${fmtDate(_range!.start)} – ${fmtDate(_range!.end)}',
                                    style: ts(
                                      12,
                                      AppColors.primary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (svc.isLoading)
                          const DashboardSkeletonView()
                        else if (svc.error != null)
                          AppCard(
                            child: StateView.error(
                              title: svc.error!.title,
                              message: svc.error!.userMessage,
                              onAction: () => svc.refreshAll(period: period),
                            ),
                          )
                        else ...[
                          // 1. Tarjeta de evolución de ventas con gráfica interactiva
                          AppCard(
                            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _range != null
                                      ? 'Rango personalizado'
                                      : period.title,
                                  style: ts(13, AppColors.grey, height: 1.4),
                                ),
                                const SizedBox(height: 6),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Align(
                                    key: ValueKey(
                                      '$_period-${_range?.start}-${_range?.end}-$total',
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      fmtCop(total),
                                      style: ts(
                                        30,
                                        AppColors.navy,
                                        weight: bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (growth != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${growth >= 0 ? '↑' : '↓'} ${fmtPct(growth.abs())} vs. período anterior',
                                    style: ts(
                                      12,
                                      growth >= 0
                                          ? AppColors.success
                                          : AppColors.danger,
                                      weight: semi,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (canCompare)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Comparar con período anterior',
                                          style: ts(12, AppColors.grey),
                                        ),
                                      ),
                                      AppSwitch(
                                        value: _compare,
                                        onChanged: (v) =>
                                            setState(() => _compare = v),
                                      ),
                                    ],
                                  ),
                                if (canCompare && _compare) ...[
                                  const SizedBox(height: 6),
                                  const ChartLegend(
                                    items: [
                                      ('Actual', AppColors.primary, false),
                                      ('Anterior', AppColors.greyLight, true),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                SalesLineChart(
                                  series: series,
                                  zoomable: true,
                                  showComparison: canCompare && _compare,
                                ),
                                if (hasData && series.current.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      left: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.pinch_outlined,
                                          size: 14,
                                          color: AppColors.greyLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pellizca para acercar · toca un punto para detalle',
                                          style: ts(11, AppColors.greyLight),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 2. Indicadores de Transacciones, Unidades, Ticket Promedio y Ventas de Hoy
                          FadeSlideIn(
                            index: 1,
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _metricCell(
                                        'Transacciones',
                                        '${ventasDto.cantidadVentas} órdenes',
                                        'Hoy: ${ventasDto.cantidadVentasHoy}',
                                      ),
                                      const SizedBox(width: 12),
                                      _metricCell(
                                        'Unidades vendidas',
                                        '${ventasDto.totalItemsVendidos} uds',
                                        'Platos y bebidas',
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _metricCell(
                                        'Ticket promedio',
                                        fmtCop(promedioDto.promedioVenta),
                                        'Hoy: ${fmtCop(promedioDto.promedioVentasHoy)}',
                                      ),
                                      const SizedBox(width: 12),
                                      _metricCell(
                                        period.isHourly && _range == null
                                            ? 'Mejor hora'
                                            : 'Mejor día /Promedio',
                                        bestPoint != null
                                            ? fmtCop(bestPoint.value)
                                            : fmtCop(avg),
                                        bestPoint != null
                                            ? (period.isHourly && _range == null
                                                  ? '${bestPoint.time.hour}:00'
                                                  : fmtDate(bestPoint.time))
                                            : 'Prom: ${fmtCop(avg)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 3. Tarjeta de Mejor Venta Registrada (Mesa, Mesero, Fecha e Ítems)
                          if (mejorVenta.hasValidSale)
                            FadeSlideIn(
                              index: 2,
                              child: _BestSaleCard(
                                mejorVenta: mejorVenta,
                                expanded: _showBestSaleItems,
                                onToggle: () => setState(
                                  () =>
                                      _showBestSaleItems = !_showBestSaleItems,
                                ),
                              ),
                            ),
                          if (mejorVenta.hasValidSale)
                            const SizedBox(height: 14),
                          // 4. Más vendidos
                          SectionHeader(
                            title: 'Más vendidos',
                            action: 'Ver Top 5 →',
                            onAction: () => shell?.pushOnTab(
                              MainShellState.tabProducts,
                              const Top5Screen(),
                            ),
                            titleStyle: ts(
                              15,
                              AppColors.navy,
                              weight: semi,
                              height: 1.4,
                            ),
                            actionStyle: ts(
                              12,
                              AppColors.primary,
                              weight: semi,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (ranking.isEmpty)
                            const AppCard(
                              child: StateView.empty(
                                compact: true,
                                title: 'Sin ventas de platillos',
                                message: 'No se registran platillos vendidos en este período.',
                              ),
                            )
                          else
                            AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < ranking.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: ProductRankRow(
                                        rank: ranking[i].posicion,
                                        product: ranking[i].toProduct(),
                                        subtitle:
                                            '${ranking[i].unidadesVendidas} vendidas · ${fmtCop(ranking[i].ingresosTotales)} (${fmtPct(ranking[i].porcentajeTotal)})',
                                        photoSize: 40,
                                        rowHeight: 46,
                                        numberSize: 14,
                                        chevronSize: 18,
                                        nameStyle: ts(
                                          13,
                                          AppColors.text,
                                          weight: semi,
                                          height: 1.4,
                                        ),
                                        onTap: () => shell?.pushOnTab(
                                          MainShellState.tabProducts,
                                          ProductDetailScreen(
                                            product: ranking[i].toProduct(),
                                            initialPeriod: period,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCell(String label, String value, String sub) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(11.5, AppColors.grey)),
        const SizedBox(height: 4),
        Text(value, style: ts(17, AppColors.navy, weight: bold)),
        const SizedBox(height: 2),
        Text(sub, style: ts(11, AppColors.greyLight)),
      ],
    ),
  );
}

class _BestSaleCard extends StatelessWidget {
  final MejorVentaModel mejorVenta;
  final bool expanded;
  final VoidCallback onToggle;

  const _BestSaleCard({
    required this.mejorVenta,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mejor venta registrada',
                      style: ts(14, AppColors.navy, weight: bold),
                    ),
                    Text(
                      'Factura #${mejorVenta.facturaId} · ${mejorVenta.fechaFormateada}',
                      style: ts(11.5, AppColors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                fmtCop(mejorVenta.monto),
                style: ts(18, AppColors.success, weight: bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _badge(Icons.table_restaurant_outlined, mejorVenta.mesa),
              _badge(Icons.badge_outlined, 'Mesero: ${mejorVenta.mesero}'),
              _badge(
                Icons.shopping_bag_outlined,
                '${mejorVenta.totalItems} unidades',
              ),
            ],
          ),
          if (mejorVenta.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      expanded
                          ? 'Ocultar detalle de productos'
                          : 'Ver detalle de productos (${mejorVenta.items.length})',
                      style: ts(12, AppColors.primary, weight: semi),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: !expanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 6),
                          for (final it in mejorVenta.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${it.cantidad}x',
                                      style: ts(
                                        11,
                                        AppColors.primary,
                                        weight: bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      it.nombre,
                                      style: ts(12.5, AppColors.text),
                                    ),
                                  ),
                                  Text(
                                    fmtCop(it.subtotal),
                                    style: ts(
                                      12.5,
                                      AppColors.navy,
                                      weight: semi,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(text, style: ts(11.5, AppColors.text, weight: semi)),
      ],
    ),
  );
}
