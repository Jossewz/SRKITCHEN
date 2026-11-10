import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts/inventory_distribution_chart.dart';
import '../widgets/charts/stock_bar_chart.dart';
import '../widgets/motion.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _onlyActive = false;
  StockLevel? _levelFilter;
  String? _selectedName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = KitchenDataService.instance;

    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final resumen = svc.resumenInventario;
        final filtered = svc.filterInventory(
          query: _query,
          onlyActive: _onlyActive,
          levelFilter: _levelFilter,
        );

        final sortedForChart = [...filtered]
          ..sort((a, b) => a.stock.compareTo(b.stock));
        final chartItems = sortedForChart
            .take(10)
            .map((e) => e.toStockItem())
            .toList();

        StockItem? selectedItem;
        if (_selectedName != null) {
          for (final it in chartItems) {
            if (it.name == _selectedName) {
              selectedItem = it;
              break;
            }
          }
        }

        final criticalList = filtered
            .where((p) => p.stockLevel == StockLevel.critico)
            .toList();
        final lowList = filtered
            .where((p) => p.stockLevel == StockLevel.bajo)
            .toList();
        final normalList = filtered
            .where((p) => p.stockLevel == StockLevel.normal)
            .toList();

        return ScreenScaffold(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Inventario',
                subtitle:
                    'Disponibilidad · ${resumen.totalProductos} productos registrados',
                showBell: true,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => svc.refreshAll(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SyncStatusBanner(onRefresh: () => svc.refreshAll()),
                        const SizedBox(height: 10),
                        if (svc.isLoading)
                          const DashboardSkeletonView()
                        else if (svc.error != null)
                          AppCard(
                            child: StateView.error(
                              title: svc.error!.title,
                              message: svc.error!.userMessage,
                              onAction: () => svc.refreshAll(),
                            ),
                          )
                        else ...[
                          // 1. Resumen y Gráfica Circular Interactiva de Clasificación
                          FadeSlideIn(
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Clasificación por nivel de stock',
                                        style: ts(
                                          15,
                                          AppColors.navy,
                                          weight: bold,
                                        ),
                                      ),
                                      if (_levelFilter != null)
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => _levelFilter = null,
                                          ),
                                          child: Text(
                                            'Ver todos',
                                            style: ts(
                                              12,
                                              AppColors.primary,
                                              weight: semi,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Toca un segmento o nivel para filtrar el catálogo',
                                    style: ts(11, AppColors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  InventoryDistributionChart(
                                    niveles: resumen,
                                    selectedLevel: _levelFilter,
                                    onSelectLevel: (lvl) =>
                                        setState(() => _levelFilter = lvl),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 2. Buscador y filtros (Nombre/Descripción + Solo Activos + Nivel)
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            style: ts(14, AppColors.text, height: 1.4),
                            decoration: appInputDecoration(
                              'Buscar por nombre, descripción o unidad...',
                              suffix: _query.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 18,
                                        color: AppColors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: AppColors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _filterChip(
                                        label:
                                            'Todos (${resumen.totalProductos})',
                                        selected: _levelFilter == null,
                                        color: AppColors.primary,
                                        onTap: () =>
                                            setState(() => _levelFilter = null),
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        label:
                                            'Críticos ≤5 (${resumen.conteoCriticos})',
                                        selected:
                                            _levelFilter == StockLevel.critico,
                                        color: AppColors.danger,
                                        onTap: () => setState(
                                          () => _levelFilter =
                                              _levelFilter == StockLevel.critico
                                              ? null
                                              : StockLevel.critico,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        label:
                                            'Bajos 6–15 (${resumen.conteoBajos})',
                                        selected:
                                            _levelFilter == StockLevel.bajo,
                                        color: AppColors.warning,
                                        onTap: () => setState(
                                          () => _levelFilter =
                                              _levelFilter == StockLevel.bajo
                                              ? null
                                              : StockLevel.bajo,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _filterChip(
                                        label:
                                            'Normales >15 (${resumen.conteoNormales})',
                                        selected:
                                            _levelFilter == StockLevel.normal,
                                        color: AppColors.success,
                                        onTap: () => setState(
                                          () => _levelFilter =
                                              _levelFilter == StockLevel.normal
                                              ? null
                                              : StockLevel.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mostrar solo productos activos',
                                style: ts(12.5, AppColors.grey),
                              ),
                              AppSwitch(
                                value: _onlyActive,
                                onChanged: (v) =>
                                    setState(() => _onlyActive = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 3. Gráfica de barras horizontales de existencias
                          FadeSlideIn(
                            index: 1,
                            child: AppCard(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      'Existencias por producto',
                                      style: ts(
                                        15,
                                        AppColors.navy,
                                        weight: bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 10,
                                    ),
                                    child: Text(
                                      'Ordenado de menor a mayor disponibilidad · toca una barra',
                                      style: ts(11, AppColors.grey),
                                    ),
                                  ),
                                  StockBarChart(
                                    items: chartItems,
                                    selected: selectedItem,
                                    onSelect: (it) => setState(
                                      () => _selectedName =
                                          _selectedName == it.name
                                          ? null
                                          : it.name,
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: selectedItem == null
                                        ? const SizedBox(
                                            width: double.infinity,
                                          )
                                        : Container(
                                            key: ValueKey(selectedItem.name),
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: selectedItem
                                                  .level
                                                  .chartColor
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selectedItem
                                                    .level
                                                    .chartColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  selectedItem.level.icon,
                                                  color: selectedItem
                                                      .level
                                                      .chartColor,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${selectedItem.name} · ${selectedItem.units} un.',
                                                        style: ts(
                                                          14,
                                                          AppColors.navy,
                                                          weight: bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Estado: ${selectedItem.level.label} · Bajo ≤ ${selectedItem.lowThreshold} · Crítico ≤ ${selectedItem.criticalThreshold}',
                                                        style: ts(
                                                          12,
                                                          AppColors.grey,
                                                          height: 1.3,
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 4. Secciones de productos clasificados (Críticos, Bajos, Normales)
                          if (filtered.isEmpty)
                            const AppCard(
                              child: StateView.empty(
                                compact: true,
                                title: 'Sin productos en esta vista',
                                message:
                                    'Prueba cambiando el término de búsqueda o el filtro de nivel.',
                              ),
                            )
                          else ...[
                            if (criticalList.isNotEmpty) ...[
                              _InventoryGroupCard(
                                title: 'Productos críticos (Stock ≤ 5)',
                                badgeText: '${criticalList.length} críticos',
                                accentColor: AppColors.danger,
                                items: criticalList,
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (lowList.isNotEmpty) ...[
                              _InventoryGroupCard(
                                title: 'Productos con stock bajo (6 a 15)',
                                badgeText: '${lowList.length} bajos',
                                accentColor: AppColors.warning,
                                items: lowList,
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (normalList.isNotEmpty)
                              _InventoryGroupCard(
                                title: 'Productos con stock normal (> 15)',
                                badgeText: '${normalList.length} disponibles',
                                accentColor: AppColors.success,
                                items: normalList,
                              ),
                          ],
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

  Widget _filterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: ts(
            11.5,
            selected ? Colors.white : AppColors.text,
            weight: selected ? bold : semi,
          ),
        ),
      ),
    );
  }
}

class _InventoryGroupCard extends StatelessWidget {
  final String title;
  final String badgeText;
  final Color accentColor;
  final List<ProductoInventarioModel> items;

  const _InventoryGroupCard({
    required this.title,
    required this.badgeText,
    required this.accentColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: ts(15, AppColors.navy, weight: bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: ts(11, accentColor, weight: bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ProductDetailScreen(product: items[i].toProduct()),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i == items.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                ),
                child: Row(
                  children: [
                    ProductPhoto(product: items[i].toProduct(), height: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  items[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts(13.5, AppColors.text, weight: semi),
                                ),
                              ),
                              if (!items[i].activo) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.track,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Inactivo',
                                    style: ts(9.5, AppColors.grey),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items[i].descripcion} · ${fmtCop(items[i].price)}/${items[i].uMedida}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(11.5, AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${items[i].stock} ${items[i].uMedida}',
                          style: ts(14, AppColors.navy, weight: bold),
                        ),
                        Text(
                          items[i].stockLevel.label,
                          style: ts(
                            11,
                            items[i].stockLevel.color,
                            weight: semi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.primary,
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
