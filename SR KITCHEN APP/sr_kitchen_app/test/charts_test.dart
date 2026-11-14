import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sr_kitchen_app/data/demo_chart_data.dart';
import 'package:sr_kitchen_app/models/app_models.dart';
import 'package:sr_kitchen_app/models/chart_models.dart';
import 'package:sr_kitchen_app/widgets/charts/sales_line_chart.dart';
import 'package:sr_kitchen_app/widgets/charts/share_donut_chart.dart';
import 'package:sr_kitchen_app/widgets/charts/stock_bar_chart.dart';
import 'package:sr_kitchen_app/widgets/charts/top_products_bar_chart.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  group('datos de demostración', () {
    test('la semana coincide con DemoData.salesSeries', () {
      final week = DemoSales.weekDaily.map((e) => e.value).toList();
      expect(week, DemoData.salesSeries);
      expect(
        DemoSales.todayHourly.fold(0.0, (a, p) => a + p.value),
        DemoData.salesSeries.last,
      );
      expect(
        DemoSales.previousWeekDaily.fold(0.0, (a, p) => a + p.value),
        DemoData.previousWeekSales,
      );
    });

    test('unidades semanales por producto == Product.sold', () {
      for (final p in DemoData.products) {
        expect(
          DemoProductStats.units(p, SalesPeriod.week),
          p.sold,
          reason: p.name,
        );
      }
    });

    test('ranking descendente y participación <= 100 %', () {
      for (final period in SalesPeriod.values) {
        final r = DemoProductStats.ranking(period);
        for (var i = 1; i < r.length; i++) {
          expect(r[i - 1].units >= r[i].units, isTrue);
        }
        expect(r.fold(0.0, (a, e) => a + e.share) <= 100, isTrue);
      }
    });

    test('niveles de stock derivados de umbrales', () {
      final byName = {for (final s in DemoStock.items) s.name: s.level};
      expect(byName['Limonada'], StockLevel.critico);
      expect(byName['Hamburguesa Clásica'], StockLevel.bajo);
      expect(byName['Pizza Especial'], StockLevel.normal);
    });

    test('rango sin datos devuelve serie vacía', () {
      final s = DemoSales.forRange(
        DateTimeRange(start: DateTime(2020), end: DateTime(2020, 1, 5)),
      );
      expect(s.isEmpty, isTrue);
    });

    test('formato COP', () {
      expect(fmtCop(1234000), '\$ 1.234.000');
      expect(fmtCopCompact(310000), '\$310 mil');
      expect(fmtCopCompact(1200000), '\$1,2 M');
    });
  });

  group('render de gráficos', () {
    testWidgets('línea con zoom y comparación', (tester) async {
      await tester.pumpWidget(
        _host(
          SalesLineChart(
            series: DemoSales.forPeriod(SalesPeriod.week),
            zoomable: true,
            showComparison: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(SalesLineChart)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('línea vacía muestra estado vacío', (tester) async {
      await tester.pumpWidget(
        _host(
          const SalesLineChart(series: SalesSeries(current: [], hourly: false)),
        ),
      );
      expect(find.text('Sin ventas en este período'), findsOneWidget);
    });

    testWidgets('top 5 selecciona al tocar', (tester) async {
      int? picked;
      await tester.pumpWidget(
        _host(
          TopProductsBarChart(
            items: DemoProductStats.ranking(SalesPeriod.week),
            selectedIndex: null,
            onSelect: (i) => picked = i,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(TopProductsBarChart));
      await tester.tapAt(Offset(rect.left + 200, rect.top + 30));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(picked, isNotNull);
    });

    testWidgets('stock y dona renderizan', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              StockBarChart(
                items: DemoStock.items,
                selected: null,
                onSelect: (_) {},
              ),
              const ShareDonutChart(
                productName: 'Pizza Especial',
                productRevenue: 720000,
                totalSales: 3029000,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
