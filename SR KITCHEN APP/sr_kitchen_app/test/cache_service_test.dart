import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sr_kitchen_app/data/mock_backend_source.dart';
import 'package:sr_kitchen_app/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group(
    'CacheService - Aislamiento por Restaurante y Persistencia Offline',
    () {
      test(
        'Guarda y recupera el Dashboard aislado por restauranteId',
        () async {
          final cache = CacheService.instance;
          final dashboardRest1 = MockBackendSource.obtenerDashboard();

          await cache.saveDashboard('rest-001', dashboardRest1);

          final cached1 = await cache.getDashboard('rest-001');
          expect(cached1, isNotNull);
          expect(cached1!.data.restauranteId, dashboardRest1.restauranteId);
          expect(
            cached1.data.ventasTotales.totalVentas,
            dashboardRest1.ventasTotales.totalVentas,
          );

          // Verificamos aislamiento: rest-002 no debe ver los datos de rest-001
          final cached2 = await cache.getDashboard('rest-002');
          expect(cached2, isNull);
        },
      );

      test('Guarda y recupera la lista de inventario', () async {
        final cache = CacheService.instance;
        final inventario = MockBackendSource.obtenerInventario();

        await cache.saveInventory('rest-001', inventario);

        final cachedInv = await cache.getInventory('rest-001');
        expect(cachedInv, isNotNull);
        expect(cachedInv!.length, 18);
        expect(cachedInv.first.nombre, inventario.first.nombre);
      });

      test('Limpia la caché correctamente', () async {
        final cache = CacheService.instance;
        await cache.saveDashboard(
          'rest-001',
          MockBackendSource.obtenerDashboard(),
        );
        expect(await cache.getDashboard('rest-001'), isNotNull);

        await cache.clear();
        expect(await cache.getDashboard('rest-001'), isNull);
      });
    },
  );
}
