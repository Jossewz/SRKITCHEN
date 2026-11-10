import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';

/// Envoltorio con marca de tiempo para cada registro almacenado en caché local.
class CachedSnapshot<T> {
  final T data;
  final DateTime updatedAt;
  final bool isFromMock;

  const CachedSnapshot({
    required this.data,
    required this.updatedAt,
    this.isFromMock = false,
  });

  Duration get age => DateTime.now().difference(updatedAt);

  /// Devuelve una descripción legible en español de la antigüedad del dato.
  String get relativeAgeLabel {
    final diff = age;
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
}

/// Servicio de caché local persistente aislado por `restaurantId`.
///
/// Garantiza que cuando se pierda la conexión a internet, la aplicación
/// conserve la última información consultada sin dejar pantallas vacías ni
/// sobrescribir copias válidas si una petición posterior falla.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final Map<String, String> _memoryCache = {};

  String _scopedKey(Object restaurantId, String resource) =>
      'sr_kitchen_cache_r${_parseRestId(restaurantId)}_$resource';

  Future<void> saveDashboard(
    Object restaurantId,
    MobileDashboardModel dashboard, {
    bool isFromMock = false,
  }) async {
    final rId = _parseRestId(restaurantId);
    await _saveRaw(
      _scopedKey(rId, 'dashboard'),
      dashboard.toJson(),
      isFromMock: isFromMock,
    );
    // También sincroniza las sub-secciones individuales para acceso granular
    await saveInventarioNiveles(
      rId,
      dashboard.resumenInventario,
      isFromMock: isFromMock,
    );
    await saveVentasTotales(
      rId,
      dashboard.ventasTotales,
      isFromMock: isFromMock,
    );
    await savePromedioVentas(
      rId,
      dashboard.promedioVentas,
      isFromMock: isFromMock,
    );
    await saveMejorVenta(
      rId,
      dashboard.mejorVenta,
      isFromMock: isFromMock,
    );
    await saveRankingPlatillos(
      rId,
      RankingPlatillosResponse(
        totalPlatillosVendidos: dashboard.topPlatillos.fold<int>(
          0,
          (a, b) => a + b.unidadesVendidas,
        ),
        totalPlatillosEnRanking: dashboard.topPlatillos.length,
        ranking: dashboard.topPlatillos,
      ),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<MobileDashboardModel>?> getDashboard(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'dashboard'),
      (json) => MobileDashboardModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> saveInventario(
    Object restaurantId,
    List<ProductoInventarioModel> items, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'inventario_list'),
      items.map((e) => e.toJson()).toList(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<List<ProductoInventarioModel>>?> getInventario(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'inventario_list'),
      (raw) => (raw as List)
          .whereType<Map>()
          .map(
            (e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  Future<void> saveInventarioNiveles(
    Object restaurantId,
    InventarioNivelesModel niveles, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'inventario_niveles'),
      niveles.toJson(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<InventarioNivelesModel>?> getInventarioNiveles(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'inventario_niveles'),
      (json) => InventarioNivelesModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> saveVentasTotales(
    Object restaurantId,
    VentasTotalesModel ventas, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'ventas_totales'),
      ventas.toJson(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<VentasTotalesModel>?> getVentasTotales(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'ventas_totales'),
      (json) => VentasTotalesModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> savePromedioVentas(
    Object restaurantId,
    PromedioVentasModel promedio, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'ventas_promedio'),
      promedio.toJson(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<PromedioVentasModel>?> getPromedioVentas(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'ventas_promedio'),
      (json) => PromedioVentasModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> saveMejorVenta(
    Object restaurantId,
    MejorVentaModel mejor, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'ventas_mejor'),
      mejor.toJson(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<MejorVentaModel>?> getMejorVenta(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'ventas_mejor'),
      (json) => MejorVentaModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> saveRankingPlatillos(
    Object restaurantId,
    RankingPlatillosResponse ranking, {
    bool isFromMock = false,
  }) async {
    await _saveRaw(
      _scopedKey(restaurantId, 'platillos_ranking'),
      ranking.toJson(),
      isFromMock: isFromMock,
    );
  }

  Future<CachedSnapshot<RankingPlatillosResponse>?> getRankingPlatillos(
    Object restaurantId,
  ) async {
    return _readRaw(
      _scopedKey(restaurantId, 'platillos_ranking'),
      (json) => RankingPlatillosResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  int _parseRestId(Object id) =>
      id is int ? id : (int.tryParse(id.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 1);

  Future<void> saveInventory(
    Object restaurantId,
    List<ProductoInventarioModel> items, {
    bool isFromMock = false,
  }) =>
      saveInventario(_parseRestId(restaurantId), items, isFromMock: isFromMock);

  Future<List<ProductoInventarioModel>?> getInventory(Object restaurantId) async =>
      (await getInventario(_parseRestId(restaurantId)))?.data;

  Future<void> clear() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('sr_kitchen_cache_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  Future<void> clearRestaurantCache(int restaurantId) async {
    final prefix = 'sr_kitchen_cache_r${restaurantId}_';
    _memoryCache.removeWhere((k, _) => k.startsWith(prefix));
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  Future<void> _saveRaw(
    String key,
    Object payload, {
    bool isFromMock = false,
  }) async {
    final envelope = jsonEncode({
      'updatedAt': DateTime.now().toIso8601String(),
      'isFromMock': isFromMock,
      'payload': payload,
    });
    _memoryCache[key] = envelope;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, envelope);
    } catch (_) {}
  }

  Future<CachedSnapshot<T>?> _readRaw<T>(
    String key,
    T Function(Object rawPayload) parser,
  ) async {
    String? raw = _memoryCache[key];
    if (raw == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(key);
        if (raw != null) _memoryCache[key] = raw;
      } catch (_) {}
    }
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final updatedAt =
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now();
      final isFromMock = map['isFromMock'] == true;
      final payload = map['payload'];
      if (payload == null) return null;
      return CachedSnapshot<T>(
        data: parser(payload),
        updatedAt: updatedAt,
        isFromMock: isFromMock,
      );
    } catch (_) {
      return null;
    }
  }
}

