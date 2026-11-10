import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../models/chart_models.dart';

/// DATOS FICTICIOS DE DEMOSTRACIÓN (estáticos y reproducibles).
///
/// Todo se deriva de listas constantes: no hay valores aleatorios, así que
/// las gráficas muestran lo mismo en cada reconstrucción. Para pasar a la API
/// real basta con reemplazar estas fuentes por respuestas del backend que
/// devuelvan los mismos modelos de `chart_models.dart`.
///
/// Coherencia entre pantallas:
///  * Semana = últimos 7 días del mes = [DemoData.salesSeries].
///  * Hoy (4 oct) por hora suma lo mismo que el último día de la semana.
///  * Las unidades semanales por producto suman [Product.sold].
class DemoSales {
  /// "Hoy" de los datos de demostración (coincide con DemoData.periodLabel).
  static final DateTime today = DateTime(2026, 10, 4);

  // Ventas diarias en miles de COP: 5 sep – 27 sep (ficticias) y la semana
  // 28 sep – 4 oct (las mismas de DemoData.salesSeries).
  static const _earlyMonthK = <double>[
    260, 285, 300, 330, 520, 610, 290, //
    275, 305, 320, 345, 480, 590, 300, //
    280, 310, 335, 350, 460, 600, 320, //
    290, 315,
  ];

  // Ventas por hora de hoy (10:00–21:00), miles de COP. Suman 489.
  static const _todayHourlyK = <double>[
    18, 26, 52, 61, 28, 22, 24, 46, 58, 63, 48, 43, //
  ];

  // Ventas por hora de ayer (3 oct), miles de COP. Suman 452.
  static const _yesterdayHourlyK = <double>[
    15, 24, 47, 58, 30, 20, 22, 41, 52, 55, 45, 43, //
  ];

  // Semana anterior (21–27 sep), miles de COP. Suman 2.735.
  static const _previousWeekK = <double>[275, 300, 320, 360, 390, 560, 530];

  static List<SalesPoint> get monthDaily {
    final week = DemoData.salesSeries;
    final values = [..._earlyMonthK.map((e) => e * 1000), ...week];
    return [
      for (var i = 0; i < values.length; i++)
        SalesPoint(DateTime(2026, 9, 5 + i), values[i]),
    ];
  }

  static List<SalesPoint> get weekDaily {
    final all = monthDaily;
    return all.sublist(all.length - 7);
  }

  static List<SalesPoint> get todayHourly => [
    for (var i = 0; i < _todayHourlyK.length; i++)
      SalesPoint(DateTime(2026, 10, 4, 10 + i), _todayHourlyK[i] * 1000),
  ];

  static List<SalesPoint> get yesterdayHourly => [
    for (var i = 0; i < _yesterdayHourlyK.length; i++)
      SalesPoint(DateTime(2026, 10, 3, 10 + i), _yesterdayHourlyK[i] * 1000),
  ];

  static List<SalesPoint> get previousWeekDaily => [
    for (var i = 0; i < _previousWeekK.length; i++)
      SalesPoint(DateTime(2026, 9, 21 + i), _previousWeekK[i] * 1000),
  ];

  /// Serie por período. El mes no tiene comparación (no hay mes anterior).
  static SalesSeries forPeriod(SalesPeriod p) => switch (p) {
    SalesPeriod.today => SalesSeries(
      current: todayHourly,
      previous: yesterdayHourly,
      hourly: true,
    ),
    SalesPeriod.week => SalesSeries(
      current: weekDaily,
      previous: previousWeekDaily,
      hourly: false,
    ),
    SalesPeriod.month => SalesSeries(current: monthDaily, hourly: false),
  };

  /// Rango personalizado: filtra los días del mes que caen en [range].
  /// Devuelve una serie vacía si no hay datos en el rango.
  static SalesSeries forRange(DateTimeRange range) {
    DateTime d(DateTime t) => DateTime(t.year, t.month, t.day);
    final start = d(range.start);
    final end = d(range.end);
    final pts = monthDaily
        .where((p) => !d(p.time).isBefore(start) && !d(p.time).isAfter(end))
        .toList();
    return SalesSeries(current: pts, hourly: false);
  }

  /// Total de ventas del período (para participación de productos).
  static double totalFor(SalesPeriod p) => forPeriod(p).total;
}

class DemoProductStats {
  // Unidades por día de la semana (28 sep – 4 oct) por producto.
  // Cada lista suma exactamente Product.sold.
  static const _weekUnits = <String, List<int>>{
    'pizza_especial': [7, 8, 9, 8, 10, 12, 6], // 60
    'hamburguesa_clasica': [5, 6, 6, 7, 7, 9, 5], // 45
    'pizza_de_pollo': [4, 5, 5, 6, 6, 8, 6], // 40
    'limonada': [3, 4, 5, 4, 6, 8, 5], // 35
    'perro_caliente': [3, 3, 4, 3, 4, 5, 3], // 25
  };

  /// Unidades vendidas por punto de tiempo del período.
  /// Semana: dato directo. Mes: los 23 días previos se reparten en proporción
  /// a las ventas del día. Hoy: el último día se reparte por hora.
  /// (Valores derivados de forma determinista; son datos ficticios.)
  static List<SalesPoint> unitsSeries(Product p, SalesPeriod period) {
    final weekSales = DemoSales.weekDaily;
    final weekTotalSales = weekSales.fold(0.0, (a, s) => a + s.value);
    final week =
        _weekUnits[p.imageKey] ??
        [
          for (var i = 0; i < 7; i++)
            (p.sold * weekSales[i].value / weekTotalSales).round().clamp(1, 999),
        ];
    final weekTotalUnits = week.fold(0, (a, b) => a + b);

    switch (period) {
      case SalesPeriod.week:
        return [
          for (var i = 0; i < 7; i++)
            SalesPoint(weekSales[i].time, week[i].toDouble()),
        ];
      case SalesPeriod.month:
        final month = DemoSales.monthDaily;
        final early = month.length - 7;
        return [
          for (var i = 0; i < early; i++)
            SalesPoint(
              month[i].time,
              (weekTotalUnits * month[i].value / weekTotalSales)
                  .roundToDouble(),
            ),
          for (var i = 0; i < 7; i++)
            SalesPoint(weekSales[i].time, week[i].toDouble()),
        ];
      case SalesPeriod.today:
        final hourly = DemoSales.todayHourly;
        final dayUnits = week.last;
        final daySales = hourly.fold(0.0, (a, s) => a + s.value);
        return [
          for (final h in hourly)
            SalesPoint(h.time, (dayUnits * h.value / daySales).roundToDouble()),
        ];
    }
  }

  static int units(Product p, SalesPeriod period) =>
      unitsSeries(p, period).fold(0, (a, s) => a + s.value.round());

  /// Ranking descendente por unidades del período (empate: por nombre).
  static List<ProductRanking> ranking(SalesPeriod period) {
    final total = DemoSales.totalFor(period);
    final rows =
        [
          for (final p in DemoData.products)
            (p, units(p, period), units(p, period) * p.price),
        ]..sort((a, b) {
          final c = b.$2.compareTo(a.$2);
          return c != 0 ? c : a.$1.name.compareTo(b.$1.name);
        });
    return [
      for (var i = 0; i < rows.length; i++)
        ProductRanking(
          product: rows[i].$1,
          units: rows[i].$2,
          revenue: rows[i].$3,
          share: total == 0 ? 0 : rows[i].$3 / total * 100,
          position: i + 1,
        ),
    ].take(5).toList();
  }

  /// Ingresos (COP) por punto de tiempo: unidades × precio unitario.
  static List<SalesPoint> revenueSeries(Product p, SalesPeriod period) => [
    for (final s in unitsSeries(p, period))
      SalesPoint(s.time, s.value * p.price),
  ];

  static ProductRanking? statsFor(Product p, SalesPeriod period) {
    final r = ranking(period);
    final i = r.indexWhere((e) => e.product.name == p.name);
    if (i >= 0) return r[i];
    final total = DemoSales.totalFor(period);
    final u = units(p, period);
    return ProductRanking(
      product: p,
      units: u,
      revenue: u * p.price,
      share: total == 0 ? 0 : u * p.price / total * 100,
      position: 0,
    );
  }
}

class DemoStock {
  /// Selección manejable de ítems de inventario.
  ///
  /// SUPUESTO: el modelo del proyecto mezcla productos (Limonada, Hamburguesa,
  /// Perro Caliente) con insumos (Queso mozzarella, Tortillas, Salsa de
  /// tomate) en `DemoData.attention`; se usan tal cual. "Pizza de Pollo" (18)
  /// es un valor añadido de demostración. Los umbrales son ficticios.
  static const items = <StockItem>[
    StockItem(
      name: 'Pizza Especial',
      units: 24,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Pizza de Pollo',
      units: 18,
      lowThreshold: 15,
      criticalThreshold: 5,
      isDemoExtra: true,
    ),
    StockItem(
      name: 'Hamburguesa Clásica',
      units: 8,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Perro Caliente',
      units: 5,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Tortillas',
      units: 6,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Salsa de tomate',
      units: 4,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Limonada',
      units: 3,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
    StockItem(
      name: 'Queso mozzarella',
      units: 2,
      lowThreshold: 15,
      criticalThreshold: 5,
    ),
  ];
}
