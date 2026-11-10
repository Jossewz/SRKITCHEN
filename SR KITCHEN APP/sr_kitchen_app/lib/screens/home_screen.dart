import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/auth_service.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts/sales_line_chart.dart';
import '../widgets/motion.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'top5_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _period = 1;

  @override
  void initState() {
    super.initState();
    unawaited(KitchenDataService.instance.loadSalesSeries(SalesPeriod.week));
  }

  @override
  Widget build(BuildContext context) {
    final shell = MainShell.maybeOf(context);
    final svc = KitchenDataService.instance;
    final auth = AuthService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([svc, auth]),
      builder: (context, _) {
        final period = SalesPeriodX.fromIndex(_period);
        final series = svc.salesSeriesForPeriod(period);
        final ventasDto = svc.ventasForPeriod(period);
        final promedioDto = svc.promedioForPeriod(period);
        final mejorVenta = svc.mejorVenta;
        final ranking = svc.rankingModelsForPeriod(period, limite: 5);
        final starDish = ranking.isNotEmpty
            ? ranking.first
            : svc.dashboard.platilloMasVendido;
        final invResumen = svc.resumenInventario;

        final sales = series.isEmpty ? 0.0 : series.total;
        final prevTotal = series.previousTotal;
        final growth = (prevTotal == null || prevTotal == 0)
            ? null
            : (sales - prevTotal) / prevTotal * 100;

        final restaurantName = svc.dashboard.restaurante.nombre.isNotEmpty
            ? svc.dashboard.restaurante.nombre
            : DemoData.restaurant;
        final firstName = auth.displayName.split(' ').first;

        return ScreenScaffold(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Hola, $firstName',
                subtitle: '$restaurantName · ${PeriodFilter.labels[_period]}',
                boldTitle: true,
                showBell: true,
                height: 64,
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
                            setState(() => _period = i);
                            unawaited(
                              svc.loadSalesSeries(SalesPeriodX.fromIndex(i)),
                            );
                          },
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
                          // 1. Gráfica principal de evolución de ventas
                          FadeSlideIn(
                            child: AppCard(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                12,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        period.rangeLabel,
                                        style: ts(12, AppColors.grey),
                                      ),
                                      Text(
                                        '${ventasDto.cantidadVentas} transacciones',
                                        style: ts(
                                          11.5,
                                          AppColors.primary,
                                          weight: semi,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (c, a) => FadeTransition(
                                      opacity: a,
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: const Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(a),
                                        child: c,
                                      ),
                                    ),
                                    child: Align(
                                      key: ValueKey('$_period-$sales'),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        fmtCop(sales),
                                        style: ts(
                                          30,
                                          AppColors.navy,
                                          weight: bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (growth != null && prevTotal != null)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Anterior: ${fmtCop(prevTotal)}',
                                            style: ts(13, AppColors.grey),
                                          ),
                                        ),
                                        Text(
                                          '${growth >= 0 ? '↑' : '↓'} ${fmtPct(growth.abs())}',
                                          style: ts(
                                            13,
                                            growth >= 0
                                                ? AppColors.success
                                                : AppColors.danger,
                                            weight: semi,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Sin período anterior para comparar',
                                      style: ts(13, AppColors.grey),
                                    ),
                                  const SizedBox(height: 10),
                                  SalesLineChart(
                                    series: series,
                                    height: 190,
                                    currentLabel: period.isHourly
                                        ? 'Hoy'
                                        : 'Actual',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 2. Tarjetas de Indicadores Clave del Dashboard Unificado
                          FadeSlideIn(
                            index: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _KpiMetricCard(
                                    icon: Icons.today_outlined,
                                    label: 'Ventas del día',
                                    value: fmtCop(ventasDto.ventasHoy),
                                    subtitle:
                                        '${ventasDto.cantidadVentasHoy} órdenes hoy',
                                    onTap: () => shell?.selectTab(
                                      MainShellState.tabSales,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiMetricCard(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Ticket promedio',
                                    value: fmtCop(promedioDto.promedioVenta),
                                    subtitle:
                                        'Hoy: ${fmtCop(promedioDto.promedioVentasHoy)}',
                                    onTap: () => shell?.selectTab(
                                      MainShellState.tabSales,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeSlideIn(
                            index: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _KpiMetricCard(
                                    icon: Icons.workspace_premium_outlined,
                                    label: 'Mejor venta',
                                    value: fmtCop(mejorVenta.monto),
                                    subtitle:
                                        '${mejorVenta.mesa} · ${mejorVenta.mesero}',
                                    accentColor: AppColors.success,
                                    onTap: () => shell?.selectTab(
                                      MainShellState.tabSales,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _KpiMetricCard(
                                    icon: Icons.star_outline_rounded,
                                    label: 'Platillo #1',
                                    value: starDish?.nombre ?? 'Sin ventas',
                                    valueFontSize: 15,
                                    subtitle: starDish != null
                                        ? '${starDish.unidadesVendidas} uds · ${fmtPct(starDish.porcentajeTotal)}'
                                        : '0 unidades',
                                    onTap: starDish == null
                                        ? null
                                        : () => shell?.pushOnTab(
                                            MainShellState.tabProducts,
                                            ProductDetailScreen(
                                              product: starDish.toProduct(),
                                              initialPeriod: period,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // 3. Ranking de platillos más vendidos
                          SectionHeader(
                            title: 'Más vendidos',
                            action: 'Ver Top 5 →',
                            onAction: () => shell?.pushOnTab(
                              MainShellState.tabProducts,
                              const Top5Screen(),
                            ),
                            titleStyle: ts(16, AppColors.navy, weight: semi),
                            actionStyle: ts(
                              13,
                              AppColors.primary,
                              weight: semi,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (ranking.isEmpty)
                            const AppCard(
                              child: StateView.empty(
                                compact: true,
                                title: 'Sin ventas registradas',
                                message: 'Aún no hay platillos vendidos en este período.',
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
                                    ProductRankRow(
                                      rank: ranking[i].posicion,
                                      product: ranking[i].toProduct(),
                                      subtitle:
                                          '${ranking[i].unidadesVendidas} uds · ${fmtCop(ranking[i].ingresosTotales)} (${fmtPct(ranking[i].porcentajeTotal)})',
                                      photoSize: 34,
                                      rowHeight: 48,
                                      numberSize: 13,
                                      chevronSize: 16,
                                      nameStyle: ts(
                                        13,
                                        AppColors.text,
                                        weight: semi,
                                      ),
                                      onTap: () => shell?.pushOnTab(
                                        MainShellState.tabProducts,
                                        ProductDetailScreen(
                                          product: ranking[i].toProduct(),
                                          initialPeriod: period,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          // 4. Estado del inventario
                          SectionHeader(
                            title: 'Inventario',
                            action: 'Consultar →',
                            onAction: () =>
                                shell?.selectTab(MainShellState.tabInventory),
                            titleStyle: ts(16, AppColors.navy, weight: semi),
                            actionStyle: ts(
                              13,
                              AppColors.primary,
                              weight: semi,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _indicator(
                                      'Normal (>15)',
                                      '${invResumen.conteoNormales}',
                                      AppColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    _indicator(
                                      'Bajo (6–15)',
                                      '${invResumen.conteoBajos}',
                                      AppColors.warning,
                                    ),
                                    const SizedBox(width: 12),
                                    _indicator(
                                      'Crítico (≤5)',
                                      '${invResumen.conteoCriticos}',
                                      AppColors.danger,
                                    ),
                                  ],
                                ),
                                if (invResumen
                                    .atencionPrioritaria
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(
                                    height: 12,
                                    color: AppColors.border,
                                  ),
                                  for (final item
                                      in invResumen.atencionPrioritaria.take(4))
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => shell?.selectTab(
                                        MainShellState.tabInventory,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.stockLevel ==
                                                      StockLevel.critico
                                                  ? Icons.error_outline
                                                  : Icons.warning_amber_rounded,
                                              size: 15,
                                              color:
                                                  item.stockLevel ==
                                                      StockLevel.critico
                                                  ? AppColors.danger
                                                  : AppColors.warning,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: ts(13, AppColors.text),
                                              ),
                                            ),
                                            Text(
                                              '${item.stock} ${item.uMedida}',
                                              style: ts(
                                                12.5,
                                                item.stockLevel.color,
                                                weight: semi,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 15,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
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

  Widget _indicator(String label, String value, Color valueColor) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(11.5, AppColors.grey)),
        const SizedBox(height: 3),
        Text(value, style: ts(22, valueColor, weight: bold)),
      ],
    ),
  );
}

class _KpiMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final double valueFontSize;
  final VoidCallback? onTap;

  const _KpiMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.accentColor = AppColors.primary,
    this.valueFontSize = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(11.5, AppColors.grey, weight: semi),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(valueFontSize, AppColors.navy, weight: bold),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(11, AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
