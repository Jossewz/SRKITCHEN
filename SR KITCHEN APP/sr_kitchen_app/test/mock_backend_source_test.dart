import 'package:flutter_test/flutter_test.dart';
import 'package:sr_kitchen_app/data/mock_backend_source.dart';
import 'package:sr_kitchen_app/models/app_models.dart';

void main() {
  group('MockBackendSource - Coherencia Matemática y Reglas de Negocio', () {
    test('El inventario contiene 18 productos con stock coherente', () {
      final items = MockBackendSource.obtenerInventario();
      expect(items.length, 18);

      final criticos = items.where((i) => i.stockActual <= 5).toList();
      final bajos = items.where((i) => i.stockActual > 5 && i.stockActual <= 15).toList();
      final normales = items.where((i) => i.stockActual > 15).toList();

      final niveles = MockBackendSource.obtenerNivelesInventario();
      expect(niveles.conteoCriticos, criticos.length);
      expect(niveles.conteoBajos, bajos.length);
      expect(niveles.conteoNormales, normales.length);
      expect(niveles.total, 18);

      // Verificamos que cada nivelStock mapee adecuadamente
      for (final c in criticos) {
        expect(c.stockLevel, StockLevel.critico);
      }
      for (final b in bajos) {
        expect(b.stockLevel, StockLevel.bajo);
      }
      for (final n in normales) {
        expect(n.stockLevel, StockLevel.normal);
      }
    });

    test('Filtros de búsqueda y niveles en inventario funcionan exactamente', () {
      final criticos = MockBackendSource.obtenerInventario(nivel: StockLevel.critico);
      expect(criticos.every((i) => i.stockActual <= 5), isTrue);

      final busquedaPizza = MockBackendSource.obtenerInventario(buscar: 'pizza');
      expect(busquedaPizza.length, greaterThanOrEqualTo(2));
      expect(
        busquedaPizza.every(
          (i) =>
              i.nombre.toLowerCase().contains('pizza') ||
              i.descripcion.toLowerCase().contains('pizza') ||
              i.categoria.toLowerCase().contains('pizza'),
        ),
        isTrue,
      );
    });

    test('Ventas y promedios son matemáticamente exactos', () {
      final ventas = MockBackendSource.obtenerVentasTotales();
      final promedio = MockBackendSource.obtenerPromedioVentas();

      expect(ventas.totalVentas, greaterThan(0));
      expect(ventas.totalTransacciones, greaterThan(0));
      expect(promedio.totalTransacciones, ventas.totalTransacciones);
      expect(promedio.promedioVenta, closeTo(ventas.totalVentas / ventas.totalTransacciones, 0.5));
    });

    test('Mejor venta tiene ordenId, mesa, mesero y suma de ítems coherente', () {
      final mejor = MockBackendSource.obtenerMejorVenta();
      expect(mejor.ordenId, isNotEmpty);
      expect(mejor.mesa, contains('Mesa'));
      expect(mejor.mesero, isNotEmpty);
      expect(mejor.items, isNotEmpty);

      final sumaItems = mejor.items.fold(0.0, (acc, item) => acc + item.subtotal);
      expect(sumaItems, mejor.total);
    });

    test('Rankings de platillos están ordenados descendentemente y respetan el límite', () {
      final top5 = MockBackendSource.obtenerTopPlatillos(limite: 5);
      expect(top5.length, 5);

      for (var i = 1; i < top5.length; i++) {
        expect(top5[i - 1].cantidadVendida >= top5[i].cantidadVendida, isTrue);
      }

      final top10 = MockBackendSource.obtenerTopPlatillos(limite: 10);
      expect(top10.length, 10);
      for (var i = 1; i < top10.length; i++) {
        expect(top10[i - 1].cantidadVendida >= top10[i].cantidadVendida, isTrue);
      }

      final masVendido = MockBackendSource.obtenerPlatilloMasVendido();
      expect(masVendido.platilloId, top5.first.platilloId);
      expect(masVendido.cantidadVendida, top5.first.cantidadVendida);
    });

    test('Dashboard consolidado unifica métricas de forma consistente', () {
      final dash = MockBackendSource.obtenerDashboard();
      expect(dash.restauranteId, '1');
      expect(dash.ventasTotales.totalVentas, greaterThan(0));
      expect(dash.inventarioNiveles.total, 18);
      expect(dash.topPlatillos, isNotEmpty);
      expect(dash.platilloMasVendido?.nombre, dash.topPlatillos.first.nombre);
    });
  });
}
