import 'dart:convert';

import 'app_models.dart';
import 'chart_models.dart';

/// Utilidades seguras de conversión JSON para evitar fallos ante valores nulos,
/// enteros enviados como decimales o cadenas numéricas.
double _toDouble(Object? v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) {
    final clean = v.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean) ?? fallback;
  }
  return fallback;
}

int _toInt(Object? v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) {
    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? fallback;
  }
  return fallback;
}

bool _toBool(Object? v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is String) {
    final lower = v.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  if (v is num) return v != 0;
  return fallback;
}

String _toStr(Object? v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

DateTime? _toDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(v.trim());
    if (parsed != null) return parsed;
    // Intenta formato dd/MM/yyyy HH:mm del backend
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})(?:\s+(\d{2}):(\d{2}))?$')
        .firstMatch(v.trim());
    if (m != null) {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
        m.group(4) != null ? int.parse(m.group(4)!) : 0,
        m.group(5) != null ? int.parse(m.group(5)!) : 0,
      );
    }
  }
  if (v is List && v.length >= 3) {
    // Jackson LocalDateTime como array [yyyy, MM, dd, HH, mm, ss]
    return DateTime(
      _toInt(v[0], 2026),
      _toInt(v[1], 1),
      _toInt(v[2], 1),
      v.length > 3 ? _toInt(v[3]) : 0,
      v.length > 4 ? _toInt(v[4]) : 0,
      v.length > 5 ? _toInt(v[5]) : 0,
    );
  }
  return null;
}

String normalizeImageKey(String name) {
  final lower = name
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
  if (lower.contains('pizza') && lower.contains('pollo')) {
    return 'pizza_de_pollo';
  }
  if (lower.contains('pizza')) return 'pizza_especial';
  if (lower.contains('hamburguesa')) return 'hamburguesa_clasica';
  if (lower.contains('limonada') ||
      lower.contains('jugo') ||
      lower.contains('bebida')) {
    return 'limonada';
  }
  if (lower.contains('perro')) return 'perro_caliente';
  return lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String inferCategory(String name, [String? description]) {
  final text = '${name.toLowerCase()} ${(description ?? '').toLowerCase()}';
  if (text.contains('pizza')) return 'Pizzas';
  if (text.contains('hamburguesa') || text.contains('burger')) {
    return 'Hamburguesas';
  }
  if (text.contains('limonada') ||
      text.contains('jugo') ||
      text.contains('gaseosa') ||
      text.contains('bebida') ||
      text.contains('cerveza') ||
      text.contains('agua')) {
    return 'Bebidas';
  }
  if (text.contains('perro') ||
      text.contains('papas') ||
      text.contains('alitas') ||
      text.contains('nachos')) {
    return 'Comida rápida';
  }
  if (text.contains('postre') ||
      text.contains('helado') ||
      text.contains('torta') ||
      text.contains('brownie')) {
    return 'Postres';
  }
  if (text.contains('queso') ||
      text.contains('harina') ||
      text.contains('aceite') ||
      text.contains('salsa') ||
      text.contains('tortilla') ||
      text.contains('carne') ||
      text.contains('pollo') ||
      text.contains('arroz') ||
      text.contains('tomate')) {
    return 'Insumos y cocina';
  }
  return 'Platos fuertes';
}

/// Modelo de sesión autenticada devuelto por `POST /api/mobile/login`.
class AuthSessionModel {
  final String token;
  final String type;
  final int restaurantId;
  final String nombre;
  final String? nombreRestaurante;
  final String email;
  final String role;
  final String mensaje;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isMockSession;

  const AuthSessionModel({
    required this.token,
    this.type = 'Bearer',
    required this.restaurantId,
    required this.nombre,
    this.nombreRestaurante,
    required this.email,
    required this.role,
    this.mensaje = 'Inicio de sesión exitoso',
    required this.issuedAt,
    required this.expiresAt,
    this.isMockSession = false,
  });

  /// Regla de negocio obligatoria: solo usuarios con rol ADMIN pueden acceder
  /// a la herramienta móvil administrativa.
  bool get isAdmin {
    final normalized = role.trim().toUpperCase();
    return normalized == 'ADMIN' || normalized == 'ROLE_ADMIN';
  }

  String get fullName => nombre;
  String get rol => role;
  String get restaurantName => nombreRestaurante ?? nombre;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get normalizedRole =>
      role.toUpperCase().replaceFirst(RegExp(r'^ROLE_'), '');

  factory AuthSessionModel.fromJson(
    Map<String, dynamic> json, {
    bool isMock = false,
  }) {
    final token = _toStr(json['token']);
    final now = DateTime.now();
    DateTime issued =
        _toDateTime(json['issuedAt']) ?? _extractJwtDate(token, 'iat') ?? now;
    DateTime expires =
        _toDateTime(json['expiresAt']) ??
        _extractJwtDate(token, 'exp') ??
        now.add(const Duration(hours: 24));

    final rawRole = _toStr(
      json['role'] ??
          json['rol'] ??
          _extractJwtClaim(token, 'role') ??
          _extractJwtClaim(token, 'rol'),
      'USER',
    );
    final restId = _toInt(
      json['restaurantId'] ??
          json['restaurant_id'] ??
          json['restauranteId'] ??
          _extractJwtClaim(token, 'restaurant_id'),
      1,
    );
    final restName = _toStr(
      json['nombreRestaurante'] ??
          json['restaurantName'] ??
          _extractJwtClaim(token, 'nombreRestaurante'),
    );

    return AuthSessionModel(
      token: token,
      type: _toStr(json['type'], 'Bearer'),
      restaurantId: restId,
      nombre: _toStr(
        json['nombre'] ?? json['name'] ?? _extractJwtClaim(token, 'nombre'),
        'Restaurante SR Kitchen',
      ),
      nombreRestaurante: restName.isNotEmpty ? restName : null,
      email: _toStr(
        json['email'] ??
            json['correo'] ??
            json['usuario'] ??
            json['mail'] ??
            _extractJwtClaim(token, 'sub'),
        'admin@rskitchen.com',
      ),
      role: rawRole,
      mensaje: _toStr(json['mensaje'], 'Inicio de sesión exitoso'),
      issuedAt: issued,
      expiresAt: expires,
      isMockSession: isMock || _toBool(json['isMockSession']),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'type': type,
    'restaurantId': restaurantId,
    'nombre': nombre,
    'email': email,
    'role': role,
    'mensaje': mensaje,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isMockSession': isMockSession,
  };

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  static Object? _extractJwtClaim(String token, String key) {
    final payload = _decodeJwtPayload(token);
    return payload?[key];
  }

  static DateTime? _extractJwtDate(String token, String key) {
    final claim = _extractJwtClaim(token, key);
    if (claim is num) {
      return DateTime.fromMillisecondsSinceEpoch(claim.toInt() * 1000);
    }
    return null;
  }
}

/// DTO de producto de inventario (`ProductoInventarioDTO.java`).
/// Reglas de negocio oficiales del backend:
/// - CRITICO: stock <= 5
/// - BAJO: 6 <= stock <= 15
/// - NORMAL: stock > 15
class ProductoInventarioModel {
  static const int umbralCritico = 5;
  static const int umbralBajo = 15;

  final int id;
  final String name;
  final String descripcion;
  final String uMedida;
  final double price;
  final int stock;
  final bool activo;
  final String nivelStock; // "CRITICO", "BAJO", "NORMAL"
  final String colorNivel; // "danger", "warning", "success"
  final String categoria;
  final int unidadesVendidas;

  const ProductoInventarioModel({
    required this.id,
    required this.name,
    required this.descripcion,
    required this.uMedida,
    required this.price,
    required this.stock,
    this.activo = true,
    required this.nivelStock,
    required this.colorNivel,
    this.categoria = 'Insumos y cocina',
    this.unidadesVendidas = 0,
  });

  /// Utiliza el valor calculado por el backend cuando está disponible;
  /// aplica la regla oficial como respaldo seguro.
  StockLevel get stockLevel {
    final upper = nivelStock.trim().toUpperCase();
    if (upper == 'CRITICO' || upper == 'CRÍTICO') return StockLevel.critico;
    if (upper == 'BAJO') return StockLevel.bajo;
    if (upper == 'NORMAL') return StockLevel.normal;
    if (stock <= umbralCritico) return StockLevel.critico;
    if (stock <= umbralBajo) return StockLevel.bajo;
    return StockLevel.normal;
  }

  String get nombre => name;
  int get stockActual => stock;
  double get precio => price;

  String get imageKey => normalizeImageKey(name);

  StockItem toStockItem() => StockItem(
    name: name,
    units: stock,
    lowThreshold: umbralBajo,
    criticalThreshold: umbralCritico,
  );

  Product toProduct({int? soldOverride}) => Product(
    name: name,
    category: categoria,
    price: price,
    sold: soldOverride ?? unidadesVendidas,
    stock: stockLevel,
    stockUnits: stock,
    imageKey: imageKey,
  );

  factory ProductoInventarioModel.fromJson(Map<String, dynamic> json) {
    final stockVal = _toInt(json['stock'] ?? json['stockActual']);
    final rawNivel = _toStr(json['nivelStock']);
    final resolvedNivel = rawNivel.isNotEmpty
        ? rawNivel.toUpperCase()
        : (stockVal <= umbralCritico
              ? 'CRITICO'
              : (stockVal <= umbralBajo ? 'BAJO' : 'NORMAL'));
    final rawColor = _toStr(json['colorNivel']);
    final resolvedColor = rawColor.isNotEmpty
        ? rawColor
        : (resolvedNivel == 'CRITICO'
              ? 'danger'
              : (resolvedNivel == 'BAJO' ? 'warning' : 'success'));
    final nameVal = _toStr(json['name'] ?? json['nombre'], 'Producto');
    final descVal = _toStr(
      json['descripcion'] ?? json['description'],
      'Insumo de inventario del restaurante',
    );

    return ProductoInventarioModel(
      id: _toInt(json['id']),
      name: nameVal,
      descripcion: descVal,
      uMedida: _toStr(json['uMedida'] ?? json['unidadMedida'], 'unidad'),
      price: _toDouble(json['price'] ?? json['precio']),
      stock: stockVal,
      activo: _toBool(json['activo'], true),
      nivelStock: resolvedNivel,
      colorNivel: resolvedColor,
      categoria: _toStr(json['categoria'], inferCategory(nameVal, descVal)),
      unidadesVendidas: _toInt(json['unidadesVendidas']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'descripcion': descripcion,
    'uMedida': uMedida,
    'price': price,
    'stock': stock,
    'activo': activo,
    'nivelStock': nivelStock,
    'colorNivel': colorNivel,
    'categoria': categoria,
    'unidadesVendidas': unidadesVendidas,
  };
}

/// DTO de resumen de niveles de inventario (`InventarioNivelesDTO.java`).
class InventarioNivelesModel {
  final int totalProductos;
  final int conteoCriticos;
  final int conteoBajos;
  final int conteoNormales;
  final bool requiereAtencion;
  final List<ProductoInventarioModel> criticos;
  final List<ProductoInventarioModel> bajos;
  final List<ProductoInventarioModel> normales;

  const InventarioNivelesModel({
    required this.totalProductos,
    required this.conteoCriticos,
    required this.conteoBajos,
    required this.conteoNormales,
    required this.requiereAtencion,
    required this.criticos,
    required this.bajos,
    required this.normales,
  });

  int get total => totalProductos;

  List<ProductoInventarioModel> get todos => [
    ...criticos,
    ...bajos,
    ...normales,
  ];

  List<ProductoInventarioModel> get atencionPrioritaria => [
    ...criticos,
    ...bajos,
  ];

  factory InventarioNivelesModel.fromProducts(
    List<ProductoInventarioModel> items,
  ) {
    final crit = <ProductoInventarioModel>[];
    final baj = <ProductoInventarioModel>[];
    final norm = <ProductoInventarioModel>[];
    for (final p in items) {
      switch (p.stockLevel) {
        case StockLevel.critico:
          crit.add(p);
        case StockLevel.bajo:
          baj.add(p);
        case StockLevel.normal:
          norm.add(p);
      }
    }
    return InventarioNivelesModel(
      totalProductos: items.length,
      conteoCriticos: crit.length,
      conteoBajos: baj.length,
      conteoNormales: norm.length,
      requiereAtencion: crit.isNotEmpty || baj.isNotEmpty,
      criticos: crit,
      bajos: baj,
      normales: norm,
    );
  }

  factory InventarioNivelesModel.fromJson(Map<String, dynamic> json) {
    List<ProductoInventarioModel> parseList(Object? raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()),
          )
          .toList();
    }

    final crit = parseList(json['criticos']);
    final baj = parseList(json['bajos']);
    final norm = parseList(json['normales']);
    final cCrit = _toInt(
      json['conteoCriticos'] ??
          (json['criticos'] is! List ? json['criticos'] : null),
      crit.length,
    );
    final cBaj = _toInt(
      json['conteoBajos'] ?? (json['bajos'] is! List ? json['bajos'] : null),
      baj.length,
    );
    final cNorm = _toInt(
      json['conteoNormales'] ??
          (json['normales'] is! List ? json['normales'] : null),
      norm.length,
    );
    final total = _toInt(
      json['totalProductos'] ?? json['total'],
      cCrit + cBaj + cNorm,
    );

    return InventarioNivelesModel(
      totalProductos: total,
      conteoCriticos: cCrit,
      conteoBajos: cBaj,
      conteoNormales: cNorm,
      requiereAtencion: _toBool(
        json['requiereAtencion'],
        cCrit > 0 || cBaj > 0,
      ),
      criticos: crit,
      bajos: baj,
      normales: norm,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalProductos': totalProductos,
    'conteoCriticos': conteoCriticos,
    'conteoBajos': conteoBajos,
    'conteoNormales': conteoNormales,
    'requiereAtencion': requiereAtencion,
    'criticos': criticos.map((e) => e.toJson()).toList(),
    'bajos': bajos.map((e) => e.toJson()).toList(),
    'normales': normales.map((e) => e.toJson()).toList(),
  };
}

/// DTO de ventas totales (`VentasTotalesDTO.java`).
class VentasTotalesModel {
  final double totalVentas;
  final String totalVentasFormateado;
  final int cantidadVentas;
  final int totalItemsVendidos;
  final double ventasHoy;
  final String ventasHoyFormateado;
  final int cantidadVentasHoy;

  const VentasTotalesModel({
    required this.totalVentas,
    required this.totalVentasFormateado,
    required this.cantidadVentas,
    required this.totalItemsVendidos,
    required this.ventasHoy,
    required this.ventasHoyFormateado,
    required this.cantidadVentasHoy,
  });

  int get totalTransacciones => cantidadVentas;

  factory VentasTotalesModel.fromJson(Map<String, dynamic> json) {
    final total = _toDouble(json['totalVentas']);
    final hoy = _toDouble(json['ventasHoy']);
    return VentasTotalesModel(
      totalVentas: total,
      totalVentasFormateado: _toStr(
        json['totalVentasFormateado'],
        fmtCop(total),
      ),
      cantidadVentas: _toInt(
        json['cantidadVentas'] ?? json['totalTransacciones'],
      ),
      totalItemsVendidos: _toInt(json['totalItemsVendidos']),
      ventasHoy: hoy,
      ventasHoyFormateado: _toStr(json['ventasHoyFormateado'], fmtCop(hoy)),
      cantidadVentasHoy: _toInt(json['cantidadVentasHoy']),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalVentas': totalVentas,
    'totalVentasFormateado': totalVentasFormateado,
    'cantidadVentas': cantidadVentas,
    'totalItemsVendidos': totalItemsVendidos,
    'ventasHoy': ventasHoy,
    'ventasHoyFormateado': ventasHoyFormateado,
    'cantidadVentasHoy': cantidadVentasHoy,
  };
}

/// Punto real de la serie (`VentaSerieDTO.java`).
class VentaSerieModel {
  final DateTime timestamp;
  final double monto;

  const VentaSerieModel({required this.timestamp, required this.monto});

  factory VentaSerieModel.fromJson(Map<String, dynamic> json) {
    final timestamp = _toDateTime(json['timestamp']);
    final rawMonto = json['monto'];
    if (timestamp == null || (rawMonto is! num && rawMonto is! String)) {
      throw const FormatException('Punto de serie de ventas inválido');
    }
    return VentaSerieModel(timestamp: timestamp, monto: _toDouble(rawMonto));
  }
}

/// DTO de ticket promedio de ventas (`PromedioVentasDTO.java`).
class PromedioVentasModel {
  final double promedioVenta;
  final String promedioVentaFormateado;
  final double promedioVentasHoy;
  final String promedioVentasHoyFormateado;
  final double totalVentas;
  final int cantidadVentas;

  const PromedioVentasModel({
    required this.promedioVenta,
    required this.promedioVentaFormateado,
    required this.promedioVentasHoy,
    required this.promedioVentasHoyFormateado,
    required this.totalVentas,
    required this.cantidadVentas,
  });

  int get totalTransacciones => cantidadVentas;

  factory PromedioVentasModel.fromJson(Map<String, dynamic> json) {
    final prom = _toDouble(json['promedioVenta']);
    final promHoy = _toDouble(json['promedioVentasHoy']);
    return PromedioVentasModel(
      promedioVenta: prom,
      promedioVentaFormateado: _toStr(
        json['promedioVentaFormateado'],
        fmtCop(prom),
      ),
      promedioVentasHoy: promHoy,
      promedioVentasHoyFormateado: _toStr(
        json['promedioVentasHoyFormateado'],
        fmtCop(promHoy),
      ),
      totalVentas: _toDouble(json['totalVentas']),
      cantidadVentas: _toInt(
        json['cantidadVentas'] ?? json['totalTransacciones'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'promedioVenta': promedioVenta,
    'promedioVentaFormateado': promedioVentaFormateado,
    'promedioVentasHoy': promedioVentasHoy,
    'promedioVentasHoyFormateado': promedioVentasHoyFormateado,
    'totalVentas': totalVentas,
    'cantidadVentas': cantidadVentas,
  };
}

/// Ítem individual dentro de `MejorVentaDTO`.
class ItemVentaModel {
  final String nombre;
  final int cantidad;
  final double precio;
  final double subtotal;

  const ItemVentaModel({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory ItemVentaModel.fromJson(Map<String, dynamic> json) {
    final cant = _toInt(json['cantidad'], 1);
    final sub = _toDouble(json['subtotal']);
    final rawPrice = _toDouble(json['precio']);
    final price = rawPrice > 0 ? rawPrice : (cant > 0 ? sub / cant : 0.0);
    final resolvedSub = sub > 0 ? sub : (cant * price);
    return ItemVentaModel(
      nombre: _toStr(json['nombre'] ?? json['name'], 'Platillo'),
      cantidad: cant,
      precio: price,
      subtotal: resolvedSub,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'cantidad': cantidad,
    'precio': precio,
    'subtotal': subtotal,
  };
}

/// DTO de mejor venta registrada (`MejorVentaDTO.java`).
class MejorVentaModel {
  final String facturaId;
  final String pedidoId;
  final double monto;
  final String montoFormateado;
  final DateTime? fecha;
  final String fechaFormateada;
  final String mesa;
  final String mesero;
  final int totalItems;
  final List<ItemVentaModel> items;

  const MejorVentaModel({
    required this.facturaId,
    required this.pedidoId,
    required this.monto,
    required this.montoFormateado,
    this.fecha,
    required this.fechaFormateada,
    required this.mesa,
    required this.mesero,
    required this.totalItems,
    required this.items,
  });

  bool get hasValidSale => monto > 0;
  double get total => monto;
  String get ordenId =>
      pedidoId.isNotEmpty && pedidoId != '0' ? pedidoId : facturaId;

  factory MejorVentaModel.fromJson(Map<String, dynamic> json) {
    final montoVal = _toDouble(json['monto'] ?? json['total']);
    final rawItems = json['items'];
    final parsedItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => ItemVentaModel.fromJson(e.cast<String, dynamic>()))
              .toList()
        : const <ItemVentaModel>[];
    final dt = _toDateTime(json['fecha']);
    final pedidoVal = _toStr(json['pedidoId'] ?? json['ordenId'], '0');
    final factVal = _toStr(json['facturaId'] ?? json['ordenId'], '0');

    return MejorVentaModel(
      facturaId: factVal,
      pedidoId: pedidoVal,
      monto: montoVal,
      montoFormateado: _toStr(json['montoFormateado'], fmtCop(montoVal)),
      fecha: dt,
      fechaFormateada: _toStr(
        json['fechaFormateada'],
        dt != null ? fmtDate(dt) : 'Sin fecha',
      ),
      mesa: _toStr(json['mesa'], 'N/A'),
      mesero: _toStr(json['mesero'], 'No especificado'),
      totalItems: _toInt(
        json['totalItems'],
        parsedItems.fold<int>(0, (a, b) => a + b.cantidad),
      ),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'facturaId': facturaId,
    'pedidoId': pedidoId,
    'monto': monto,
    'montoFormateado': montoFormateado,
    'fecha': fecha?.toIso8601String(),
    'fechaFormateada': fechaFormateada,
    'mesa': mesa,
    'mesero': mesero,
    'totalItems': totalItems,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// DTO de ranking de platillo (`PlatilloRankingDTO.java`).
class PlatilloRankingModel {
  final int posicion;
  final String nombre;
  final int unidadesVendidas;
  final double precioUnitario;
  final double ingresosTotales;
  final String ingresosTotalesFormateado;
  final double porcentajeTotal;
  final String categoria;
  final int? stockDisponible;
  final StockLevel stockLevel;

  const PlatilloRankingModel({
    required this.posicion,
    required this.nombre,
    required this.unidadesVendidas,
    required this.precioUnitario,
    required this.ingresosTotales,
    required this.ingresosTotalesFormateado,
    required this.porcentajeTotal,
    this.categoria = 'Platos fuertes',
    this.stockDisponible,
    this.stockLevel = StockLevel.normal,
  });

  String get imageKey => normalizeImageKey(nombre);
  int get cantidadVendida => unidadesVendidas;
  double get totalVentas => ingresosTotales;
  double get porcentaje => porcentajeTotal;
  String get platilloId => posicion.toString();

  Product toProduct() => Product(
    name: nombre,
    category: categoria,
    price: precioUnitario,
    sold: unidadesVendidas,
    stock: stockLevel,
    stockUnits: stockDisponible,
    imageKey: imageKey,
  );

  ProductRanking toProductRanking() => ProductRanking(
    product: toProduct(),
    units: unidadesVendidas,
    revenue: ingresosTotales,
    share: porcentajeTotal,
    position: posicion,
  );

  factory PlatilloRankingModel.fromJson(Map<String, dynamic> json) {
    final nameVal = _toStr(json['nombre'] ?? json['name'], 'Platillo');
    final uds = _toInt(json['unidadesVendidas'] ?? json['cantidadVendida']);
    final ingresos = _toDouble(json['ingresosTotales'] ?? json['totalVentas']);
    final precio = _toDouble(
      json['precioUnitario'],
      uds > 0 ? ingresos / uds : 0.0,
    );
    final stockDisp = json['stockDisponible'] != null
        ? _toInt(json['stockDisponible'])
        : null;
    final resolvedLevel = stockDisp != null
        ? (stockDisp <= ProductoInventarioModel.umbralCritico
              ? StockLevel.critico
              : (stockDisp <= ProductoInventarioModel.umbralBajo
                    ? StockLevel.bajo
                    : StockLevel.normal))
        : StockLevel.normal;

    return PlatilloRankingModel(
      posicion: _toInt(json['posicion'] ?? json['platilloId'], 1),
      nombre: nameVal,
      unidadesVendidas: uds,
      precioUnitario: precio,
      ingresosTotales: ingresos,
      ingresosTotalesFormateado: _toStr(
        json['ingresosTotalesFormateado'],
        fmtCop(ingresos),
      ),
      porcentajeTotal: _toDouble(json['porcentajeTotal'] ?? json['porcentaje']),
      categoria: _toStr(json['categoria'], inferCategory(nameVal)),
      stockDisponible: stockDisp,
      stockLevel: resolvedLevel,
    );
  }

  Map<String, dynamic> toJson() => {
    'posicion': posicion,
    'nombre': nombre,
    'unidadesVendidas': unidadesVendidas,
    'precioUnitario': precioUnitario,
    'ingresosTotales': ingresosTotales,
    'ingresosTotalesFormateado': ingresosTotalesFormateado,
    'porcentajeTotal': porcentajeTotal,
    'categoria': categoria,
    if (stockDisponible != null) 'stockDisponible': stockDisponible,
  };
}

/// Respuesta del endpoint `GET /api/mobile/platillos/mas-vendidos`.
class RankingPlatillosResponse {
  final int totalPlatillosVendidos;
  final int totalPlatillosEnRanking;
  final List<PlatilloRankingModel> ranking;

  const RankingPlatillosResponse({
    required this.totalPlatillosVendidos,
    required this.totalPlatillosEnRanking,
    required this.ranking,
  });

  factory RankingPlatillosResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['ranking'];
    final list = rawList is List
        ? rawList
              .whereType<Map>()
              .map(
                (e) => PlatilloRankingModel.fromJson(e.cast<String, dynamic>()),
              )
              .toList()
        : const <PlatilloRankingModel>[];
    final totalUds = _toInt(
      json['totalPlatillosVendidos'],
      list.fold<int>(0, (a, b) => a + b.unidadesVendidas),
    );
    return RankingPlatillosResponse(
      totalPlatillosVendidos: totalUds,
      totalPlatillosEnRanking: _toInt(
        json['totalPlatillosEnRanking'],
        list.length,
      ),
      ranking: list,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPlatillosVendidos': totalPlatillosVendidos,
    'totalPlatillosEnRanking': totalPlatillosEnRanking,
    'ranking': ranking.map((e) => e.toJson()).toList(),
  };
}

/// Información resumida del restaurante incluida en `MobileDashboardDTO`.
class RestauranteInfoModel {
  final int id;
  final String nombre;
  final String correo;
  final bool activo;

  const RestauranteInfoModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.activo = true,
  });

  factory RestauranteInfoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RestauranteInfoModel(
        id: 1,
        nombre: 'SR Kitchen',
        correo: 'admin@rskitchen.com',
      );
    }
    return RestauranteInfoModel(
      id: _toInt(json['id'], 1),
      nombre: _toStr(json['nombre'], 'SR Kitchen'),
      correo: _toStr(json['correo'] ?? json['email'], 'admin@rskitchen.com'),
      activo: _toBool(json['activo'], true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'activo': activo,
  };
}

/// DTO unificado de `GET /api/mobile/dashboard` (`MobileDashboardDTO.java`).
class MobileDashboardModel {
  final RestauranteInfoModel restaurante;
  final VentasTotalesModel ventasTotales;
  final PromedioVentasModel promedioVentas;
  final MejorVentaModel mejorVenta;
  final PlatilloRankingModel? platilloMasVendido;
  final List<PlatilloRankingModel> topPlatillos;
  final InventarioNivelesModel resumenInventario;

  const MobileDashboardModel({
    required this.restaurante,
    required this.ventasTotales,
    required this.promedioVentas,
    required this.mejorVenta,
    this.platilloMasVendido,
    required this.topPlatillos,
    required this.resumenInventario,
  });

  String get restauranteId => restaurante.id.toString();
  InventarioNivelesModel get inventarioNiveles => resumenInventario;

  factory MobileDashboardModel.fromJson(Map<String, dynamic> json) {
    final restMap = json['restaurante'] is Map
        ? (json['restaurante'] as Map).cast<String, dynamic>()
        : (json['restauranteId'] != null
              ? <String, dynamic>{'id': json['restauranteId']}
              : null);
    final ventasMap = json['ventasTotales'] is Map
        ? (json['ventasTotales'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final promMap = json['promedioVentas'] is Map
        ? (json['promedioVentas'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final mejorMap = json['mejorVenta'] is Map
        ? (json['mejorVenta'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final invMap =
        (json['resumenInventario'] ?? json['inventarioNiveles']) is Map
        ? ((json['resumenInventario'] ?? json['inventarioNiveles']) as Map)
              .cast<String, dynamic>()
        : <String, dynamic>{};

    final rawTop = json['topPlatillos'];
    final topList = rawTop is List
        ? rawTop
              .whereType<Map>()
              .map(
                (e) => PlatilloRankingModel.fromJson(e.cast<String, dynamic>()),
              )
              .toList()
        : const <PlatilloRankingModel>[];

    PlatilloRankingModel? topOne;
    if (json['platilloMasVendido'] is Map) {
      final m = (json['platilloMasVendido'] as Map).cast<String, dynamic>();
      if (_toInt(m['unidadesVendidas']) > 0 || m['nombre'] != null) {
        topOne = PlatilloRankingModel.fromJson(m);
      }
    } else if (topList.isNotEmpty) {
      topOne = topList.first;
    }

    return MobileDashboardModel(
      restaurante: RestauranteInfoModel.fromJson(restMap),
      ventasTotales: VentasTotalesModel.fromJson(ventasMap),
      promedioVentas: PromedioVentasModel.fromJson(promMap),
      mejorVenta: MejorVentaModel.fromJson(mejorMap),
      platilloMasVendido: topOne,
      topPlatillos: topList,
      resumenInventario: InventarioNivelesModel.fromJson(invMap),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurante': restaurante.toJson(),
    'ventasTotales': ventasTotales.toJson(),
    'promedioVentas': promedioVentas.toJson(),
    'mejorVenta': mejorVenta.toJson(),
    'platilloMasVendido': platilloMasVendido?.toJson(),
    'topPlatillos': topPlatillos.map((e) => e.toJson()).toList(),
    'resumenInventario': resumenInventario.toJson(),
  };
}
