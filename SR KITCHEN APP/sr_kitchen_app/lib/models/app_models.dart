import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF8F9FA);
  static const navy = Color(0xFF002244);
  static const text = Color(0xFF2E2E2E);
  static const grey = Color(0xFF666666);
  static const greyLight = Color(0xFF999999);
  static const border = Color(0xFFE3E8EE);
  static const primary = Color(0xFF00509E);
  static const primarySoft = Color(0xFFEDF5FF);
  static const barSoft = Color(0xFF5AA9E6);
  static const track = Color(0xFFE9EFF5);
  static const danger = Color(0xFFE74C3C);
  static const success = Color(0xFF28A745);
  static const toggle = Color(0xFF007BFF);
  static const warning = Color(0xFFF39C12);
}

TextStyle ts(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double? height,
}) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

const semi = FontWeight.w600;
const bold = FontWeight.w700;

String fmtNumber(double v, {int decimals = 2}) {
  final parts = v.toStringAsFixed(decimals).split('.');
  final integerPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return decimals == 0 ? integerPart : '$integerPart,${parts[1]}';
}

String fmtUsd(double v) => '${fmtNumber(v)} USD';

/// Pesos colombianos sin decimales: "$ 1.234.000".
String fmtCop(double v) => '\$ ${fmtNumber(v, decimals: 0)}';

/// Versión compacta para ejes: "$310 mil", "$1,2 M".
String fmtCopCompact(double v) {
  final a = v.abs();
  if (a >= 1000000) {
    final m = v / 1000000;
    final s = m == m.roundToDouble()
        ? m.toStringAsFixed(0)
        : m.toStringAsFixed(1).replaceAll('.', ',');
    return '\$$s M';
  }
  if (a >= 1000) return '\$${(v / 1000).round()} mil';
  return '\$${v.round()}';
}

String fmtPct(double v) => '${fmtNumber(v, decimals: 1)} %';

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

enum StockLevel { normal, bajo, critico }

extension StockLevelX on StockLevel {
  String get label => switch (this) {
    StockLevel.normal => 'Normal',
    StockLevel.bajo => 'Bajo',
    StockLevel.critico => 'Crítico',
  };

  Color get color => switch (this) {
    StockLevel.normal => AppColors.success,
    StockLevel.bajo => AppColors.warning,
    StockLevel.critico => AppColors.danger,
  };
}

class Product {
  final String name;
  final String category;
  final double price;
  final int sold;
  final StockLevel stock;
  final int? stockUnits;
  final String imageKey;

  const Product({
    required this.name,
    required this.category,
    required this.price,
    required this.sold,
    required this.stock,
    required this.imageKey,
    this.stockUnits,
  });
}

class InventoryItem {
  final String name;
  final int units;
  final StockLevel? level;
  const InventoryItem(this.name, this.units, {this.level});
}

class DemoData {
  static const userName = 'Alex Rivera';
  static const userEmail = 'alex@lamesa.example';
  static const restaurant = 'La Mesa';
  static const appVersion = '1.0';
  static const periodLabel = '28 sep – 4 oct 2026';
  static const salesDays = [
    '28 sep',
    '29 sep',
    '30 sep',
    '1 oct',
    '2 oct',
    '3 oct',
    '4 oct',
  ];
  // Valores en COP (datos ficticios de demostración, ver DemoSales).
  static const salesSeries = <double>[
    310000,
    355000,
    372000,
    408000,
    455000,
    640000,
    489000,
  ];
  static const previousWeekSales = 2735000.0;
  static const productUnitsSeries = <double>[6.5, 7.5, 8, 9.5, 11.5, 15, 11.5];
  static double get weekSales => salesSeries.fold(0.0, (a, b) => a + b);
  static const productsTotal = 24;
  static const inventoryNormal = 18;
  static const inventoryLow = 4;
  static const inventoryCritical = 2;
  static const inventoryTotal = 24;
  static const inventoryUpdated = 'Actualizado: 4 oct 2026, 22:00';
  static const products = <Product>[
    Product(
      name: 'Pizza Especial',
      category: 'Pizzas',
      price: 12000,
      sold: 60,
      stock: StockLevel.normal,
      stockUnits: 24,
      imageKey: 'pizza_especial',
    ),
    Product(
      name: 'Hamburguesa Clásica',
      category: 'Hamburguesas',
      price: 10000,
      sold: 45,
      stock: StockLevel.bajo,
      stockUnits: 8,
      imageKey: 'hamburguesa_clasica',
    ),
    Product(
      name: 'Pizza de Pollo',
      category: 'Pizzas',
      price: 13000,
      sold: 40,
      stock: StockLevel.normal,
      imageKey: 'pizza_de_pollo',
    ),
    Product(
      name: 'Limonada',
      category: 'Bebidas',
      price: 3000,
      sold: 35,
      stock: StockLevel.critico,
      stockUnits: 3,
      imageKey: 'limonada',
    ),
    Product(
      name: 'Perro Caliente',
      category: 'Comida rápida',
      price: 6000,
      sold: 25,
      stock: StockLevel.bajo,
      stockUnits: 5,
      imageKey: 'perro_caliente',
    ),
  ];
  static List<Product> get top5 {
    final list = [...products]..sort((a, b) => b.sold.compareTo(a.sold));
    return list.take(5).toList();
  }

  static const attention = <InventoryItem>[
    InventoryItem('Limonada', 3),
    InventoryItem('Queso mozzarella', 2),
    InventoryItem('Hamburguesa Clásica', 8),
    InventoryItem('Perro Caliente', 5),
    InventoryItem('Tortillas', 6),
    InventoryItem('Salsa de tomate', 4),
  ];
  static const homeAttention = <InventoryItem>[
    InventoryItem('Limonada', 3, level: StockLevel.critico),
    InventoryItem('Hamburguesa Clásica', 8, level: StockLevel.bajo),
  ];
}
