import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts/top_products_bar_chart.dart';
import '../widgets/motion.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';

class Top5Screen extends StatefulWidget {
  const Top5Screen({super.key});

  @override
  State<Top5Screen> createState() => _Top5ScreenState();
}

class _Top5ScreenState extends State<Top5Screen> {
  int _period = 1;
  bool _showTop10 = false;
  bool _showRevenue = false;
  String? _selectedName;

  void _open(Product p, SalesPeriod period) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailScreen(product: p, initialPeriod: period),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final svc = KitchenDataService.instance;

    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final period = SalesPeriodX.fromIndex(_period);
        final limit = _showTop10 ? 10 : 5;
        final topList = svc.productRankingsForPeriod(period, limite: limit);
        final totalUnits = topList.fold<int>(0, (a, r) => a + r.units);
        final totalRevenue = topList.fold<double>(0, (a, r) => a + r.revenue);
        final selIdx = topList.indexWhere(
          (r) => r.product.name == _selectedName,
        );
        final selected = selIdx >= 0 ? topList[selIdx] : null;

        return ScreenScaffold(
          child: Column(
            children: [
              ScreenHeader(
                title: _showTop10 ? 'Top 10 platillos' : 'Top 5 productos',
                subtitle: period.rangeLabel,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PeriodFilter(
                        selected: _period,
                        onChanged: (i) => setState(() => _period = i),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Align(
                                key: ValueKey(
                                  '$_period-$_showTop10-$_showRevenue',
                                ),
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _showRevenue
                                          ? fmtCop(totalRevenue)
                                          : '$totalUnits unidades vendidas',
                                      style: ts(
                                        20,
                                        AppColors.navy,
                                        weight: bold,
                                        height: 1.3,
                                      ),
                                    ),
                                    Text(
                                      _showRevenue
                                          ? '$totalUnits uds acumuladas en el ranking'
                                          : 'Recaudación: ${fmtCop(totalRevenue)}',
                                      style: ts(12, AppColors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showTop10 = !_showTop10),
                            icon: const Icon(Icons.format_list_numbered, size: 16),
                            label: Text(_showTop10 ? 'Ver Top 5' : 'Ver Top 10'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (topList.isEmpty)
                        const AppCard(
                          child: StateView.empty(
                            compact: true,
                            title: 'Sin productos vendidos',
                            message:
                                'No hay ventas en el período seleccionado.',
                          ),
                        )
                      else ...[
                        FadeSlideIn(
                          child: AppCard(
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          _showRevenue
                                              ? 'Recaudación (COP) · toca una barra'
                                              : 'Unidades vendidas · toca una barra',
                                          style: ts(12, AppColors.grey),
                                        ),
                                      ),
                                    ),
                                    SegmentedButton<bool>(
                                      showSelectedIcon: false,
                                      style: const ButtonStyle(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                                      onSelectionChanged: (s) => setState(
                                        () => _showRevenue = s.first,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TopProductsBarChart(
                                  items: topList,
                                  selectedIndex: selIdx >= 0 ? selIdx : null,
                                  showRevenue: _showRevenue,
                                  onSelect: (i) => setState(
                                    () => _selectedName =
                                        topList[i].product.name,
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: selected == null
                                      ? const SizedBox(width: double.infinity)
                                      : _SelectedPanel(
                                          ranking: selected,
                                          onOpen: () =>
                                              _open(selected.product, period),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < topList.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: i == selIdx
                                    ? AppColors.primarySoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  ProductRankRow(
                                    rank: topList[i].position,
                                    product: topList[i].product,
                                    subtitle:
                                        '${topList[i].units} uds · ${fmtCop(topList[i].revenue)} (${fmtPct(topList[i].share)})',
                                    photoSize: 32,
                                    rowHeight: 50,
                                    numberSize: 13,
                                    chevronSize: 16,
                                    nameStyle: ts(
                                      14,
                                      AppColors.text,
                                      weight: semi,
                                    ),
                                    onTap: () =>
                                        _open(topList[i].product, period),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Container(
                                      height: 4,
                                      color: AppColors.track,
                                      alignment: Alignment.centerLeft,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: topList.first.units > 0
                                              ? topList[i].units /
                                                    topList.first.units
                                              : 0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, w, _) =>
                                            FractionallySizedBox(
                                              widthFactor: w.clamp(0, 1),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: i == 0
                                                      ? AppColors.primary
                                                      : AppColors.barSoft,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectedPanel extends StatelessWidget {
  final ProductRanking ranking;
  final VoidCallback onOpen;
  const _SelectedPanel({required this.ranking, required this.onOpen});

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(ranking.product.name),
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${ranking.position} · ${ranking.product.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(14, AppColors.navy, weight: bold),
              ),
              const SizedBox(height: 3),
              Text(
                '${ranking.units} uds · ${fmtCop(ranking.revenue)} · ${fmtPct(ranking.share)} del ranking',
                style: ts(12, AppColors.grey, height: 1.3),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onOpen,
          child: Text(
            'Ver detalle →',
            style: ts(12, AppColors.primary, weight: semi),
          ),
        ),
      ],
    ),
  );
}
