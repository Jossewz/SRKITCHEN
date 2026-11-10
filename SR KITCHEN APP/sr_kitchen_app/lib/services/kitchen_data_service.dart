import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_chart_data.dart';
import '../data/mock_backend_source.dart';
import '../models/api_models.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import 'api_service.dart';
import 'app_exception.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'environment_config.dart';

/// Origen de los datos actualmente presentados en las pantallas.
enum DataOrigin {
  liveApi, // Obtenidos del backend Spring Boot (/api/mobile/**)
  mockDemo, // Obtenidos de la fuente simulada coherente (MockBackendSource)
  localCache, // Recuperados de la caché persistente local (Modo Offline)
}

extension DataOriginX on DataOrigin {
  String get badgeLabel => switch (this) {
    DataOrigin.liveApi => 'ACTUALIZADO · API',
    DataOrigin.mockDemo => 'MODO DEMO · MOCK',
    DataOrigin.localCache => 'ALMACENADO LOCALMENTE',
  };

  String get statusDescription => switch (this) {
    DataOrigin.liveApi => 'Datos sincronizados con el servidor del restaurante',
    DataOrigin.mockDemo =>
      'Datos simulados coherentes activos para validación visual',
    DataOrigin.localCache =>
      'Sin conexión · Mostrando última copia guardada en el dispositivo',
  };
}

/// Servicio central de datos de SR Kitchen Mobile.
///
/// Desacopla por completo las pantallas de las peticiones HTTP, de la caché
/// offline y de los datos simulados, manteniendo coherencia total entre
/// Dashboard, Ventas, Inventario y Ranking de Platillos.
class KitchenDataService extends ChangeNotifier {
  KitchenDataService._() {
    EnvironmentConfig.instance.addListener(_onConfigChanged);
    ConnectivityService.instance.onConnectionRestored = _onConnectionRestored;
  }

  static final KitchenDataService instance = KitchenDataService._();

  bool _loading = false;
  bool _syncing = false;
  AppException? _error;
  DataOrigin _origin = DataOrigin.mockDemo;
  DateTime _lastUpdated = DateTime.now();

  MobileDashboardModel _dashboard = MockBackendSource.instance.getDashboard();
  List<ProductoInventarioModel> _inventario = MockBackendSource.catalog;
  final Map<SalesPeriod, SalesSeries> _salesSeries = {};

  bool get isLoading =>
      _loading ||
      EnvironmentConfig.instance.simulatedState == SimulatedVisualState.loading;

  bool get isSyncing => _syncing;

  AppException? get error =>
      EnvironmentConfig.instance.simulatedState == SimulatedVisualState.error
      ? AppException.fromHttpStatus(500)
      : _error;

  bool get isSimulatedEmpty =>
      EnvironmentConfig.instance.simulatedState == SimulatedVisualState.empty;

  static const _emptySalesTotals = VentasTotalesModel(
    totalVentas: 0,
    totalVentasFormateado: '\$ 0',
    cantidadVentas: 0,
    totalItemsVendidos: 0,
    ventasHoy: 0,
    ventasHoyFormateado: '\$ 0',
    cantidadVentasHoy: 0,
  );
  static const _emptySalesAverage = PromedioVentasModel(
    promedioVenta: 0,
    promedioVentaFormateado: '\$ 0',
    promedioVentasHoy: 0,
    promedioVentasHoyFormateado: '\$ 0',
    totalVentas: 0,
    cantidadVentas: 0,
  );

  DataOrigin get origin {
    if (!ConnectivityService.instance.online.value ||
        EnvironmentConfig.instance.simulatedState ==
            SimulatedVisualState.offline) {
      return DataOrigin.localCache;
    }
    return _origin;
  }

  DateTime get lastUpdated {
    if (EnvironmentConfig.instance.simulatedState ==
        SimulatedVisualState.offline) {
      return DateTime.now().subtract(const Duration(minutes: 25));
    }
    return _lastUpdated;
  }

  String get lastUpdatedTimeLabel {
    final d = lastUpdated;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${fmtDate(d)} · $hh:$mm';
  }

  String get relativeAgeLabel {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inSeconds < 45) return 'hace unos segundos';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'hace $m ${m == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'hace $h ${h == 1 ? 'hora' : 'horas'}';
    }
    final d = diff.inDays;
    return 'hace $d ${d == 1 ? 'día' : 'días'}';
  }

  MobileDashboardModel get dashboard => _dashboard;

  List<ProductoInventarioModel> get inventario =>
      isSimulatedEmpty ? const [] : _inventario;

  List<ProductoInventarioModel> get inventory => inventario;

  List<PlatilloRankingModel> get rankings => _dashboard.topPlatillos;

  InventarioNivelesModel get resumenInventario => isSimulatedEmpty
      ? const InventarioNivelesModel(
          totalProductos: 0,
          conteoCriticos: 0,
          conteoBajos: 0,
          conteoNormales: 0,
          requiereAtencion: false,
          criticos: [],
          bajos: [],
          normales: [],
        )
      : _dashboard.resumenInventario;

  MejorVentaModel get mejorVenta => _dashboard.mejorVenta;

  void _onConfigChanged() {
    refreshAll(silent: true);
  }

  void _onConnectionRestored() {
    // Al recuperar internet, si hay sesión válida, sincroniza automáticamente
    if (AuthService.instance.isAuthenticated ||
        EnvironmentConfig.instance.mode != DataSourceMode.api) {
      refreshAll(silent: true);
    }
  }

  /// Carga o sincroniza todos los módulos priorizando el endpoint unificado
  /// `GET /api/mobile/dashboard` junto con el catálogo de inventario.
  Future<void> refreshAll({
    bool silent = false,
    SalesPeriod period = SalesPeriod.week,
  }) async {
    if (_syncing) return;
    _syncing = true;
    if (!silent) {
      _loading = true;
    }
    _error = null;
    notifyListeners();

    final restId = AuthService.instance.currentRestaurantId;
    final mode = EnvironmentConfig.instance.mode;
    final isOffline = !ConnectivityService.instance.online.value;

    try {
      if (isOffline) {
        await _loadFromCacheOrMockFallback(restId, period: period);
        return;
      }

      if (mode == DataSourceMode.mock) {
        await _loadFromMock(restId, period: period);
        return;
      }

      // Modo API o Híbrido: intenta consumir `GET /api/mobile/dashboard` e `/inventario`
      try {
        final results = await Future.wait([
          ApiService.instance.getDashboard(),
          ApiService.instance.getInventario(),
        ]);
        final apiDash = results[0] as MobileDashboardModel;
        final apiInv = results[1] as List<ProductoInventarioModel>;

        _dashboard = apiDash;
        _inventario = apiInv.isNotEmpty
            ? apiInv
            : apiDash.resumenInventario.todos;
        _origin = DataOrigin.liveApi;
        _lastUpdated = DateTime.now();
        _error = null;

        await CacheService.instance.saveDashboard(
          restId,
          _dashboard,
          isFromMock: false,
        );
        await CacheService.instance.saveInventario(
          restId,
          _inventario,
          isFromMock: false,
        );
        await loadSalesSeries(period);
      } on AppException catch (e) {
        if (mode == DataSourceMode.hybrid && e.isNetworkRelated) {
          // Si hay copia en caché real previa, la prioriza; de lo contrario usa Mock
          final cachedDash = await CacheService.instance.getDashboard(restId);
          final cachedInv = await CacheService.instance.getInventario(restId);
          if (cachedDash != null && !cachedDash.isFromMock) {
            _dashboard = cachedDash.data;
            _inventario =
                cachedInv?.data ?? cachedDash.data.resumenInventario.todos;
            _origin = DataOrigin.localCache;
            _lastUpdated = cachedDash.updatedAt;
          } else {
            await _loadFromMock(restId, period: period);
          }
        } else {
          // En modo API puro, intenta recuperar la caché local antes de fallar
          final loadedCache = await _tryRestoreCacheOnly(restId);
          if (!loadedCache) {
            _error = e;
          }
        }
      }
    } finally {
      _loading = false;
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromMock(
    int restId, {
    SalesPeriod period = SalesPeriod.week,
  }) async {
    final mockDash = MockBackendSource.instance.getDashboard(period: period);
    final mockInv = MockBackendSource.instance.getInventario();
    _dashboard = mockDash;
    _inventario = mockInv;
    _origin = DataOrigin.mockDemo;
    _lastUpdated = DateTime.now();
    _error = null;

    await CacheService.instance.saveDashboard(
      restId,
      _dashboard,
      isFromMock: true,
    );
    await CacheService.instance.saveInventario(
      restId,
      _inventario,
      isFromMock: true,
    );
  }

  Future<bool> _tryRestoreCacheOnly(int restId) async {
    final cachedDash = await CacheService.instance.getDashboard(restId);
    final cachedInv = await CacheService.instance.getInventario(restId);
    if (cachedDash != null) {
      if (EnvironmentConfig.instance.mode == DataSourceMode.api &&
          cachedDash.isFromMock) {
        return false;
      }
      _dashboard = cachedDash.data;
      _inventario = cachedInv?.data ?? cachedDash.data.resumenInventario.todos;
      _origin = DataOrigin.localCache;
      _lastUpdated = cachedDash.updatedAt;
      return true;
    }
    return false;
  }

  Future<void> _loadFromCacheOrMockFallback(
    int restId, {
    SalesPeriod period = SalesPeriod.week,
  }) async {
    final restored = await _tryRestoreCacheOnly(restId);
    if (!restored) {
      if (EnvironmentConfig.instance.mode == DataSourceMode.api) {
        _error = AppException.noInternet();
      } else {
        await _loadFromMock(restId, period: period);
        _origin = DataOrigin.localCache;
      }
    }
  }

  // ===========================================================================
  // CONSULTAS CONTEXTUALES PARA PANTALLAS Y GRÁFICAS
  // ===========================================================================

  /// La serie API se carga explícitamente; DemoSales solo se usa con MOCK.
  SalesSeries salesSeriesForPeriod(SalesPeriod period) {
    if (isSimulatedEmpty) {
      return SalesSeries(current: const [], hourly: period.isHourly);
    }
    final mode = EnvironmentConfig.instance.mode;
    if (mode == DataSourceMode.mock) {
      return DemoSales.forPeriod(period);
    }
    if (_origin == DataOrigin.mockDemo && mode == DataSourceMode.hybrid) {
      return SalesSeries(current: const [], hourly: period.isHourly);
    }
    return _salesSeries[period] ??
        SalesSeries(current: const [], hourly: period.isHourly);
  }

  Future<void> loadSalesSeries(SalesPeriod period) async {
    final mode = EnvironmentConfig.instance.mode;
    if (mode == DataSourceMode.mock ||
        (mode == DataSourceMode.hybrid && _origin != DataOrigin.liveApi) ||
        !ConnectivityService.instance.online.value) {
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.instance.getVentasSerie(period),
        ApiService.instance.getVentasSerie(period, anterior: true),
      ]);
      final current = results[0];
      final previous = results[1];
      _salesSeries[period] = SalesSeries(
        current: [
          for (final point in current) SalesPoint(point.timestamp, point.monto),
        ],
        previous: previous.isEmpty
            ? null
            : [
                for (final point in previous)
                  SalesPoint(point.timestamp, point.monto),
              ],
        hourly: period.isHourly,
      );
      if (_error?.kind == AppErrorKind.serialization ||
          _error?.kind == AppErrorKind.serverError) {
        _error = null;
      }
    } on AppException catch (e) {
      _salesSeries.remove(period);
      _error = e;
    } finally {
      notifyListeners();
    }
  }

  SalesSeries salesSeriesForRange(DateTimeRange range) {
    if (isSimulatedEmpty) {
      return const SalesSeries(current: [], hourly: false);
    }
    if (EnvironmentConfig.instance.mode == DataSourceMode.mock) {
      return DemoSales.forRange(range);
    }
    return const SalesSeries(current: [], hourly: false);
  }

  VentasTotalesModel ventasForPeriod(SalesPeriod period) {
    final mode = EnvironmentConfig.instance.mode;
    if (mode == DataSourceMode.mock) {
      return MockBackendSource.instance.getVentasTotales(period: period);
    }
    if (_origin == DataOrigin.liveApi || _origin == DataOrigin.localCache) {
      return _dashboard.ventasTotales;
    }
    return _emptySalesTotals;
  }

  PromedioVentasModel promedioForPeriod(SalesPeriod period) {
    final mode = EnvironmentConfig.instance.mode;
    if (mode == DataSourceMode.mock) {
      return MockBackendSource.instance.getPromedioVentas(period: period);
    }
    if (_origin == DataOrigin.liveApi || _origin == DataOrigin.localCache) {
      return _dashboard.promedioVentas;
    }
    return _emptySalesAverage;
  }

  /// Ranking de platillos (`PlatilloRankingModel`) hasta `limite` elementos.
  List<PlatilloRankingModel> rankingModelsForPeriod(
    SalesPeriod period, {
    int limite = 10,
  }) {
    if (isSimulatedEmpty) return const [];
    final mode = EnvironmentConfig.instance.mode;
    if (mode == DataSourceMode.mock) {
      return MockBackendSource.buildRanking(limite: limite, period: period);
    }
    if (_origin == DataOrigin.liveApi || _origin == DataOrigin.localCache) {
      return _dashboard.topPlatillos.take(limite).toList();
    }
    return const [];
  }

  /// Ranking adaptado al modelo de gráficas (`ProductRanking`).
  List<ProductRanking> productRankingsForPeriod(
    SalesPeriod period, {
    int limite = 5,
  }) {
    final models = rankingModelsForPeriod(period, limite: limite);
    return models.map((m) => m.toProductRanking()).toList();
  }

  /// Lista de productos/platillos combinando el ranking y el catálogo de inventario.
  List<Product> catalogProducts({
    String query = '',
    String? category,
    StockLevel? stockFilter,
    bool onlyActive = false,
    SalesPeriod period = SalesPeriod.week,
  }) {
    if (isSimulatedEmpty) return const [];
    final ranking = rankingModelsForPeriod(period, limite: 10);
    final soldByName = {
      for (final r in ranking) r.nombre.toLowerCase(): r.unidadesVendidas,
    };

    final sourceList = _inventario.isNotEmpty
        ? _inventario
        : MockBackendSource.catalog;
    final filtered = sourceList.where((item) {
      if (onlyActive && !item.activo) return false;
      if (category != null &&
          category != 'Todos' &&
          item.categoria.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (stockFilter != null && item.stockLevel != stockFilter) {
        return false;
      }
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchDesc = item.descripcion.toLowerCase().contains(q);
        final matchCat = item.categoria.toLowerCase().contains(q);
        if (!matchName && !matchDesc && !matchCat) return false;
      }
      return true;
    });

    return filtered
        .map(
          (item) => item.toProduct(
            soldOverride:
                soldByName[item.name.toLowerCase()] ?? item.unidadesVendidas,
          ),
        )
        .toList();
  }

  /// Filtra el inventario respetando búsqueda, estado activo y nivel de stock.
  List<ProductoInventarioModel> filterInventory({
    String query = '',
    bool onlyActive = false,
    StockLevel? levelFilter,
  }) {
    if (isSimulatedEmpty) return const [];
    return _inventario.where((item) {
      if (onlyActive && !item.activo) return false;
      if (levelFilter != null && item.stockLevel != levelFilter) return false;
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.descripcion.toLowerCase().contains(q) &&
            !item.uMedida.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
