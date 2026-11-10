import 'app_models.dart';

/// Período de análisis usado por Inicio, Ventas, Top 5 y Detalle de producto.
/// El índice coincide con [PeriodFilter.labels] (Hoy, Esta semana, Este mes).
enum SalesPeriod { today, week, month }

extension SalesPeriodX on SalesPeriod {
  static SalesPeriod fromIndex(int i) => SalesPeriod.values[i];

  String get title => switch (this) {
    SalesPeriod.today => 'Ventas de hoy',
    SalesPeriod.week => 'Ventas de la semana',
    SalesPeriod.month => 'Ventas del mes',
  };

  String get rangeLabel => switch (this) {
    SalesPeriod.today => '4 oct 2026 · por hora',
    SalesPeriod.week => '28 sep – 4 oct 2026',
    SalesPeriod.month => '5 sep – 4 oct 2026',
  };

  /// Hoy se representa por hora; el resto por día.
  bool get isHourly => this == SalesPeriod.today;
}

/// Un punto de una serie temporal (hora o día) con un valor numérico.
class SalesPoint {
  final DateTime time;
  final double value;
  const SalesPoint(this.time, this.value);
}

/// Serie de ventas del período + serie opcional del período anterior
/// (alineada por posición) para comparar.
class SalesSeries {
  final List<SalesPoint> current;
  final List<SalesPoint>? previous;
  final bool hourly;
  const SalesSeries({
    required this.current,
    this.previous,
    required this.hourly,
  });

  bool get isEmpty => current.isEmpty;
  double get total => current.fold(0.0, (a, p) => a + p.value);
  double? get previousTotal =>
      previous?.fold<double>(0.0, (a, p) => a + p.value);

  SalesPoint get best => current.reduce((a, b) => b.value > a.value ? b : a);
}

/// Producto con sus unidades vendidas en un período.
class ProductRanking {
  final Product product;
  final int units;
  final double revenue;
  final double share; // % de los ingresos totales del período
  final int position; // 1 = más vendido
  const ProductRanking({
    required this.product,
    required this.units,
    required this.revenue,
    required this.share,
    required this.position,
  });
}

/// Ítem de inventario con umbrales explícitos.
/// El nivel se deriva de las unidades y los umbrales, no se define a mano.
class StockItem {
  final String name;
  final int units;

  /// Se considera "bajo" cuando units <= lowThreshold.
  final int lowThreshold;

  /// Se considera "crítico" cuando units <= criticalThreshold.
  final int criticalThreshold;

  /// true si es un valor añadido solo para demostración.
  final bool isDemoExtra;

  const StockItem({
    required this.name,
    required this.units,
    required this.lowThreshold,
    required this.criticalThreshold,
    this.isDemoExtra = false,
  });

  StockLevel get level {
    if (units <= criticalThreshold) return StockLevel.critico;
    if (units <= lowThreshold) return StockLevel.bajo;
    return StockLevel.normal;
  }
}
