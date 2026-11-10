import '../models/api_models.dart';
import '../models/app_models.dart';
import '../models/chart_models.dart';
import '../services/app_exception.dart';
import 'demo_chart_data.dart';

/// Fuente de datos simulada independiente (`MockBackendSource`) que implementa
/// exactamente los mismos contratos DTO de `MobileApiController.java`.
///
/// Garantiza coherencia matemática completa entre:
/// - Inventario (18 productos/insumos clasificados bajo reglas oficiales:
///   CRÍTICO <= 5, BAJO 6..15, NORMAL > 15).
/// - Ranking de 10 platillos (unidades, precios, ingresos y porcentajes que
///   suman el 100 % del ranking).
/// - Ventas totales, transacciones, ticket promedio y mejor venta con desglose
///   de mesa, mesero e ítems.
class MockBackendSource {
  MockBackendSource._();
  static final MockBackendSource instance = MockBackendSource._();

  static List<ProductoInventarioModel> obtenerInventario({
    StockLevel? nivel,
    String? buscar,
    bool? soloActivos,
  }) {
    return instance.getInventario(
      nivel: nivel,
      buscar: buscar,
      soloActivos: soloActivos ?? false,
    );
  }

  static InventarioNivelesModel obtenerNivelesInventario() {
    return instance.getInventarioNiveles();
  }

  static VentasTotalesModel obtenerVentasTotales() {
    return instance.getVentasTotales();
  }

  static PromedioVentasModel obtenerPromedioVentas() {
    return instance.getPromedioVentas();
  }

  static MejorVentaModel obtenerMejorVenta() {
    return instance.getMejorVenta();
  }

  static List<PlatilloRankingModel> obtenerTopPlatillos({int limite = 5}) {
    return buildRanking(limite: limite);
  }

  static PlatilloRankingModel obtenerPlatilloMasVendido() {
    return instance.getPlatilloMasVendido();
  }

  static MobileDashboardModel obtenerDashboard() {
    return instance.getDashboard();
  }

  static const int defaultRestaurantId = 1;
  static const String defaultRestaurantName = 'La Mesa · SR Kitchen';
  static const String defaultAdminEmail = 'admin@rskitchen.com';

  /// Autenticación simulada que respeta las reglas de negocio y rol ADMIN.
  Future<AuthSessionModel> login(String emailOrUser, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));

    final cleanUser = emailOrUser.trim().toLowerCase();
    if (cleanUser.isEmpty || password.isEmpty) {
      throw AppException.fromHttpStatus(
        400,
        backendErrorMessage: 'El correo y la contraseña son requeridos',
        isLoginAttempt: true,
      );
    }

    // Simulación de rechazo a perfiles no administrativos (ej. mesero@rskitchen.com)
    if (cleanUser.contains('mesero') || cleanUser.contains('empleado')) {
      throw AppException.nonAdminRole('MESERO');
    }

    // Simulación de credenciales inválidas cuando se prueba explícitamente
    if (password == 'clave_incorrecta' || password == 'wrongpass') {
      throw AppException.fromHttpStatus(
        401,
        backendErrorMessage:
            'Credenciales inválidas. Verifique correo y contraseña.',
        isLoginAttempt: true,
      );
    }

    final now = DateTime.now();
    return AuthSessionModel(
      token: 'mock_jwt_sr_kitchen_admin_${now.millisecondsSinceEpoch}',
      type: 'Bearer',
      restaurantId: defaultRestaurantId,
      nombre: defaultRestaurantName,
      email: cleanUser.contains('@') ? cleanUser : defaultAdminEmail,
      role: 'ADMIN',
      mensaje: 'Inicio de sesión exitoso (Modo Demo)',
      issuedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      isMockSession: true,
    );
  }

  /// Catálogo completo de 18 productos e insumos del restaurante con niveles:
  /// - 4 Críticos (stock <= 5)
  /// - 5 Bajos (6 <= stock <= 15)
  /// - 9 Normales (stock > 15)
  static final List<ProductoInventarioModel> catalog = [
    // CRÍTICOS (<= 5)
    const ProductoInventarioModel(
      id: 101,
      name: 'Queso mozzarella',
      descripcion: 'Bloque doble crema madurado para horno de piedra',
      uMedida: 'kg',
      price: 28000,
      stock: 2,
      activo: true,
      nivelStock: 'CRITICO',
      colorNivel: 'danger',
      categoria: 'Insumos y cocina',
      unidadesVendidas: 42,
    ),
    const ProductoInventarioModel(
      id: 102,
      name: 'Limonada Natural',
      descripcion: 'Bebida refrescante de limón Tahití recién exprimido',
      uMedida: 'unidad',
      price: 6500,
      stock: 3,
      activo: true,
      nivelStock: 'CRITICO',
      colorNivel: 'danger',
      categoria: 'Bebidas',
      unidadesVendidas: 35,
    ),
    const ProductoInventarioModel(
      id: 103,
      name: 'Salsa Pomodoro Artesanal',
      descripcion: 'Base de tomates San Marzano, albahaca fresca y oliva',
      uMedida: 'litro',
      price: 18500,
      stock: 4,
      activo: true,
      nivelStock: 'CRITICO',
      colorNivel: 'danger',
      categoria: 'Insumos y cocina',
      unidadesVendidas: 28,
    ),
    const ProductoInventarioModel(
      id: 104,
      name: 'Perro Caliente Especial',
      descripcion: 'Salchicha tipo Frankfurt, pan brioche y tocineta ahumada',
      uMedida: 'unidad',
      price: 16000,
      stock: 5,
      activo: true,
      nivelStock: 'CRITICO',
      colorNivel: 'danger',
      categoria: 'Comida rápida',
      unidadesVendidas: 25,
    ),

    // BAJOS (6..15)
    const ProductoInventarioModel(
      id: 105,
      name: 'Tortillas de Trigo',
      descripcion: 'Paquete de tortillas artesanales de 30 cm para wraps',
      uMedida: 'paquete',
      price: 12000,
      stock: 6,
      activo: true,
      nivelStock: 'BAJO',
      colorNivel: 'warning',
      categoria: 'Insumos y cocina',
      unidadesVendidas: 19,
    ),
    const ProductoInventarioModel(
      id: 106,
      name: 'Hamburguesa Clásica',
      descripcion: 'Carne Certified Angus 180g, queso cheddar y vegetales',
      uMedida: 'unidad',
      price: 24000,
      stock: 8,
      activo: true,
      nivelStock: 'BAJO',
      colorNivel: 'warning',
      categoria: 'Hamburguesas',
      unidadesVendidas: 45,
    ),
    const ProductoInventarioModel(
      id: 107,
      name: 'Aceite de Oliva Extra Virgen',
      descripcion: 'Prensado en frío para aderezos y finalización de pizzas',
      uMedida: 'litro',
      price: 42000,
      stock: 9,
      activo: true,
      nivelStock: 'BAJO',
      colorNivel: 'warning',
      categoria: 'Insumos y cocina',
      unidadesVendidas: 14,
    ),
    const ProductoInventarioModel(
      id: 108,
      name: 'Lomo Fino de Res',
      descripcion: 'Corte madurado seleccionado para parrilla y salteados',
      uMedida: 'kg',
      price: 54000,
      stock: 11,
      activo: true,
      nivelStock: 'BAJO',
      colorNivel: 'warning',
      categoria: 'Platos fuertes',
      unidadesVendidas: 32,
    ),
    const ProductoInventarioModel(
      id: 109,
      name: 'Tiramisú de la Casa',
      descripcion: 'Postre italiano con mascarpone y café expreso',
      uMedida: 'porción',
      price: 15000,
      stock: 14,
      activo: true,
      nivelStock: 'BAJO',
      colorNivel: 'warning',
      categoria: 'Postres',
      unidadesVendidas: 22,
    ),

    // NORMALES (> 15)
    const ProductoInventarioModel(
      id: 110,
      name: 'Pizza de Pollo y Champiñones',
      descripcion: 'Pechuga grillada, champiñones Portobello y mozzarella',
      uMedida: 'unidad',
      price: 32000,
      stock: 18,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Pizzas',
      unidadesVendidas: 40,
    ),
    const ProductoInventarioModel(
      id: 111,
      name: 'Alitas BBQ Ahumadas (x8)',
      descripcion: 'Alitas crocantes bañadas en reducción artesanal BBQ',
      uMedida: 'porción',
      price: 26000,
      stock: 21,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Comida rápida',
      unidadesVendidas: 29,
    ),
    const ProductoInventarioModel(
      id: 112,
      name: 'Pizza Especial SR Kitchen',
      descripcion: 'Pepperoni importado, jamón serrano, aceitunas y orégano',
      uMedida: 'unidad',
      price: 35000,
      stock: 24,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Pizzas',
      unidadesVendidas: 60,
    ),
    const ProductoInventarioModel(
      id: 113,
      name: 'Jugo de Frutos Rojos',
      descripcion: 'Mora, fresa y arándanos naturales sin azúcar añadida',
      uMedida: 'unidad',
      price: 8500,
      stock: 27,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Bebidas',
      unidadesVendidas: 31,
    ),
    const ProductoInventarioModel(
      id: 114,
      name: 'Hamburguesa Doble Tocineta',
      descripcion: 'Doble carne 300g, doble cheddar, cebolla caramelizada',
      uMedida: 'unidad',
      price: 31000,
      stock: 30,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Hamburguesas',
      unidadesVendidas: 34,
    ),
    const ProductoInventarioModel(
      id: 115,
      name: 'Papas Rústicas con Parmesano',
      descripcion: 'Cascos de papa criolla y sabanera con hierbas finas',
      uMedida: 'porción',
      price: 13000,
      stock: 36,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Comida rápida',
      unidadesVendidas: 38,
    ),
    const ProductoInventarioModel(
      id: 116,
      name: 'Harina de Trigo Fuerza 00',
      descripcion: 'Harina italiana de fermentación larga para masa madre',
      uMedida: 'kg',
      price: 9500,
      stock: 42,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Insumos y cocina',
      unidadesVendidas: 15,
    ),
    const ProductoInventarioModel(
      id: 117,
      name: 'Limonada de Coco Cremosa',
      descripcion: 'Leche de coco natural batida con zumo de limón fresco',
      uMedida: 'unidad',
      price: 11000,
      stock: 48,
      activo: true,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Bebidas',
      unidadesVendidas: 27,
    ),
    const ProductoInventarioModel(
      id: 118,
      name: 'Menú Degustación Temporada (Inactivo)',
      descripcion: 'Edición especial fuera de carta actual',
      uMedida: 'unidad',
      price: 45000,
      stock: 19,
      activo: false,
      nivelStock: 'NORMAL',
      colorNivel: 'success',
      categoria: 'Platos fuertes',
      unidadesVendidas: 6,
    ),
  ];

  /// Ranking de los 10 platillos más vendidos del restaurante con porcentajes
  /// y recaudación matemáticamente coherentes.
  static List<PlatilloRankingModel> buildRanking({
    int limite = 10,
    SalesPeriod period = SalesPeriod.week,
  }) {
    final factor = switch (period) {
      SalesPeriod.today => 0.18,
      SalesPeriod.week => 1.0,
      SalesPeriod.month => 4.15,
    };

    final rawDishes = <({
      String name,
      int baseUnits,
      double price,
      String category,
      int stock,
    })>[
      (
        name: 'Pizza Especial',
        baseUnits: 60,
        price: 12000,
        category: 'Pizzas',
        stock: 24,
      ),
      (
        name: 'Hamburguesa Clásica',
        baseUnits: 45,
        price: 10000,
        category: 'Hamburguesas',
        stock: 8,
      ),
      (
        name: 'Pizza de Pollo',
        baseUnits: 40,
        price: 13000,
        category: 'Pizzas',
        stock: 18,
      ),
      (
        name: 'Papas Rústicas con Parmesano',
        baseUnits: 38,
        price: 13000,
        category: 'Comida rápida',
        stock: 36,
      ),
      (
        name: 'Limonada',
        baseUnits: 35,
        price: 3000,
        category: 'Bebidas',
        stock: 3,
      ),
      (
        name: 'Hamburguesa Doble Tocineta',
        baseUnits: 34,
        price: 31000,
        category: 'Hamburguesas',
        stock: 30,
      ),
      (
        name: 'Lomo Fino a la Parrilla',
        baseUnits: 32,
        price: 38000,
        category: 'Platos fuertes',
        stock: 11,
      ),
      (
        name: 'Jugo de Frutos Rojos',
        baseUnits: 31,
        price: 8500,
        category: 'Bebidas',
        stock: 27,
      ),
      (
        name: 'Alitas BBQ Ahumadas (x8)',
        baseUnits: 29,
        price: 26000,
        category: 'Comida rápida',
        stock: 21,
      ),
      (
        name: 'Perro Caliente',
        baseUnits: 25,
        price: 6000,
        category: 'Comida rápida',
        stock: 5,
      ),
    ];

    final scaled = [
      for (final d in rawDishes)
        (
          name: d.name,
          units: (d.baseUnits * factor).round().clamp(1, 100000),
          price: d.price,
          category: d.category,
          stock: d.stock,
        ),
    ]..sort((a, b) => b.units.compareTo(a.units));

    final totalUnitsAll = scaled.fold<int>(0, (a, b) => a + b.units);
    final selected = scaled.take(limite > 0 ? limite : 10).toList();

    return [
      for (var i = 0; i < selected.length; i++)
        PlatilloRankingModel(
          posicion: i + 1,
          nombre: selected[i].name,
          unidadesVendidas: selected[i].units,
          precioUnitario: selected[i].price,
          ingresosTotales: selected[i].units * selected[i].price,
          ingresosTotalesFormateado: fmtCop(
            selected[i].units * selected[i].price,
          ),
          porcentajeTotal: totalUnitsAll > 0
              ? double.parse(
                  (selected[i].units / totalUnitsAll * 100).toStringAsFixed(2),
                )
              : 0.0,
          categoria: selected[i].category,
          stockDisponible: selected[i].stock,
          stockLevel: selected[i].stock <= ProductoInventarioModel.umbralCritico
              ? StockLevel.critico
              : (selected[i].stock <= ProductoInventarioModel.umbralBajo
                    ? StockLevel.bajo
                    : StockLevel.normal),
        ),
    ];
  }

  /// Obtiene el inventario filtrado según los parámetros del endpoint.
  List<ProductoInventarioModel> getInventario({
    StockLevel? nivel,
    String? query,
    String? buscar,
    bool soloActivos = false,
  }) {
    var list = soloActivos
        ? catalog.where((p) => p.activo).toList()
        : [...catalog];

    if (nivel != null) {
      list = list.where((p) => p.stockLevel == nivel).toList();
    }

    final term = (query ?? buscar)?.trim().toLowerCase();
    if (term != null && term.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(term) ||
                p.descripcion.toLowerCase().contains(term) ||
                p.categoria.toLowerCase().contains(term),
          )
          .toList();
    }
    return list;
  }

  PlatilloRankingModel getPlatilloMasVendido({
    SalesPeriod period = SalesPeriod.week,
  }) {
    final list = buildRanking(limite: 1, period: period);
    return list.first;
  }

  /// Obtiene la clasificación oficial de niveles de inventario.
  InventarioNivelesModel getInventarioNiveles() =>
      InventarioNivelesModel.fromProducts(catalog);

  /// Calcula las ventas totales coherentes con `DemoSales`.
  VentasTotalesModel getVentasTotales({SalesPeriod period = SalesPeriod.week}) {
    final weekTotal = DemoSales.forPeriod(SalesPeriod.week).total; // 3.029.000
    final todayTotal = DemoSales.forPeriod(SalesPeriod.today).total; // 489.000
    final monthTotal = DemoSales.forPeriod(SalesPeriod.month).total; // 11.494.000

    final selectedTotal = switch (period) {
      SalesPeriod.today => todayTotal,
      SalesPeriod.week => weekTotal,
      SalesPeriod.month => monthTotal,
    };

    final txCount = switch (period) {
      SalesPeriod.today => 18,
      SalesPeriod.week => 96,
      SalesPeriod.month => 384,
    };

    final itemsSold = buildRanking(
      limite: 10,
      period: period,
    ).fold<int>(0, (a, b) => a + b.unidadesVendidas);

    return VentasTotalesModel(
      totalVentas: selectedTotal,
      totalVentasFormateado: fmtCop(selectedTotal),
      cantidadVentas: txCount,
      totalItemsVendidos: itemsSold,
      ventasHoy: todayTotal,
      ventasHoyFormateado: fmtCop(todayTotal),
      cantidadVentasHoy: 18,
    );
  }

  /// Calcula el promedio de ventas coherente con `getVentasTotales`.
  PromedioVentasModel getPromedioVentas({
    SalesPeriod period = SalesPeriod.week,
  }) {
    final totales = getVentasTotales(period: period);
    final prom = totales.cantidadVentas > 0
        ? totales.totalVentas / totales.cantidadVentas
        : 0.0;
    final promHoy = totales.cantidadVentasHoy > 0
        ? totales.ventasHoy / totales.cantidadVentasHoy
        : 0.0;

    return PromedioVentasModel(
      promedioVenta: double.parse(prom.toStringAsFixed(2)),
      promedioVentaFormateado: fmtCop(prom),
      promedioVentasHoy: double.parse(promHoy.toStringAsFixed(2)),
      promedioVentasHoyFormateado: fmtCop(promHoy),
      totalVentas: totales.totalVentas,
      cantidadVentas: totales.cantidadVentas,
    );
  }

  /// Retorna la mejor venta registrada con detalle de mesa, mesero, fecha e ítems.
  MejorVentaModel getMejorVenta() {
    const items = [
      ItemVentaModel(
        nombre: 'Pizza Especial SR Kitchen',
        cantidad: 3,
        precio: 35000,
        subtotal: 105000,
      ),
      ItemVentaModel(
        nombre: 'Lomo Fino a la Parrilla',
        cantidad: 2,
        precio: 38000,
        subtotal: 76000,
      ),
      ItemVentaModel(
        nombre: 'Hamburguesa Doble Tocineta',
        cantidad: 2,
        precio: 31000,
        subtotal: 62000,
      ),
      ItemVentaModel(
        nombre: 'Alitas BBQ Ahumadas (x8)',
        cantidad: 1,
        precio: 26000,
        subtotal: 26000,
      ),
      ItemVentaModel(
        nombre: 'Limonada de Coco Cremosa',
        cantidad: 4,
        precio: 11000,
        subtotal: 44000,
      ),
      ItemVentaModel(
        nombre: 'Tiramisú de la Casa',
        cantidad: 2,
        precio: 15000,
        subtotal: 30000,
      ),
    ];
    final total = items.fold<double>(0, (a, b) => a + b.subtotal); // 343.000 COP
    final count = items.fold<int>(0, (a, b) => a + b.cantidad); // 14 uds

    return MejorVentaModel(
      facturaId: 'FAC-2026-0842',
      pedidoId: 'PED-1094',
      monto: total,
      montoFormateado: fmtCop(total),
      fecha: DateTime(2026, 10, 3, 20, 45),
      fechaFormateada: '03/10/2026 20:45',
      mesa: 'Mesa 5 · Terraza Principal',
      mesero: 'Carlos Mendoza',
      totalItems: count,
      items: items,
    );
  }

  /// Construye el `MobileDashboardModel` unificado completo.
  MobileDashboardModel getDashboard({SalesPeriod period = SalesPeriod.week}) {
    final ranking = buildRanking(limite: 10, period: period);
    return MobileDashboardModel(
      restaurante: const RestauranteInfoModel(
        id: defaultRestaurantId,
        nombre: defaultRestaurantName,
        correo: defaultAdminEmail,
        activo: true,
      ),
      ventasTotales: getVentasTotales(period: period),
      promedioVentas: getPromedioVentas(period: period),
      mejorVenta: getMejorVenta(),
      platilloMasVendido: ranking.isNotEmpty ? ranking.first : null,
      topPlatillos: ranking,
      resumenInventario: getInventarioNiveles(),
    );
  }
}

