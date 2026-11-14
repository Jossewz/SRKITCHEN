import 'package:flutter/material.dart';

import '../main.dart';
import '../models/app_models.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'top5_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Todos';
  StockLevel? _stockFilter;

  static const _categories = [
    'Todos',
    'Pizzas',
    'Hamburguesas',
    'Bebidas',
    'Comida rápida',
    'Platos fuertes',
    'Postres',
    'Insumos y cocina',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = MainShell.maybeOf(context);
    final svc = KitchenDataService.instance;

    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final items = svc.catalogProducts(
          query: _query,
          category: _selectedCategory,
          stockFilter: _stockFilter,
        );
        final starDish = svc.dashboard.platilloMasVendido;

        return ScreenScaffold(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Productos y Platillos',
                subtitle: '${items.length} resultados en catálogo',
                onBack: shell != null
                    ? () => shell.selectTab(MainShellState.tabHome)
                    : null,
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
                        // Tarjeta destacada de Platillo Estrella + Acceso a Ranking
                        if (starDish != null && !svc.isSimulatedEmpty) ...[
                          AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ProductPhoto(
                                  product: starDish.toProduct(),
                                  height: 48,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Platillo #1 más vendido',
                                        style: ts(
                                          11.5,
                                          AppColors.primary,
                                          weight: bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        starDish.nombre,
                                        style: ts(
                                          15,
                                          AppColors.navy,
                                          weight: bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${starDish.unidadesVendidas} uds · ${fmtCop(starDish.ingresosTotales)} (${fmtPct(starDish.porcentajeTotal)})',
                                        style: ts(12, AppColors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const Top5Screen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Ranking →',
                                    style: ts(
                                      12.5,
                                      AppColors.primary,
                                      weight: bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Buscar productos o platillos',
                          style: ts(13, AppColors.text, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          style: ts(14, AppColors.text, height: 1.4),
                          decoration: appInputDecoration(
                            'Nombre o categoría',
                            hintColor: AppColors.grey,
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
                        // Filtros interactivos por categoría
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final cat in _categories)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: _selectedCategory == cat,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: Colors.white,
                                    labelStyle: ts(
                                      12,
                                      _selectedCategory == cat
                                          ? Colors.white
                                          : AppColors.text,
                                      weight: _selectedCategory == cat
                                          ? bold
                                          : FontWeight.w500,
                                    ),
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = cat,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Filtro por estado de stock
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _stockChip('Todos los estados', null),
                              const SizedBox(width: 6),
                              _stockChip('Normal', StockLevel.normal),
                              const SizedBox(width: 6),
                              _stockChip('Bajo', StockLevel.bajo),
                              const SizedBox(width: 6),
                              _stockChip('Crítico', StockLevel.critico),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (svc.isLoading)
                          const DashboardSkeletonView()
                        else if (items.isEmpty)
                          const AppCard(
                            child: StateView.empty(
                              compact: true,
                              title: 'Sin productos encontrados',
                              message:
                                  'Ajusta la categoría, el nivel de stock o el texto de búsqueda.',
                            ),
                          )
                        else
                          AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < items.length; i++)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                          product: items[i],
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      height: 78,
                                      decoration: BoxDecoration(
                                        border: i == items.length - 1
                                            ? null
                                            : const Border(
                                                bottom: BorderSide(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                      ),
                                      child: Row(
                                        children: [
                                          ProductPhoto(
                                            product: items[i],
                                            height: 46,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  items[i].name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: ts(
                                                    14,
                                                    AppColors.text,
                                                    weight: semi,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${items[i].category} · ${fmtCop(items[i].price)}',
                                                  style: ts(
                                                    12,
                                                    AppColors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${items[i].stock.label}${items[i].stockUnits != null ? ' (${items[i].stockUnits} uds)' : ''} · ${items[i].sold} vendidas',
                                                  style: ts(
                                                    12,
                                                    items[i].stock.color,
                                                    weight: semi,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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
      },
    );
  }

  Widget _stockChip(String label, StockLevel? level) {
    final isSelected = _stockFilter == level;
    final color = level?.color ?? AppColors.navy;
    return GestureDetector(
      onTap: () => setState(() => _stockFilter = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: ts(
            11.5,
            isSelected ? color : AppColors.grey,
            weight: isSelected ? bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
