import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sr_kitchen_app/models/api_models.dart';
import 'package:sr_kitchen_app/models/chart_models.dart';
import 'package:sr_kitchen_app/services/api_service.dart';
import 'package:sr_kitchen_app/services/connectivity_service.dart';
import 'package:sr_kitchen_app/services/environment_config.dart';
import 'package:sr_kitchen_app/services/kitchen_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ConnectivityService.instance.online.value = true;
    await EnvironmentConfig.instance.setMode(DataSourceMode.api);
  });

  test('el modelo de serie convierte timestamps y montos del JSON', () {
    final point = VentaSerieModel.fromJson({
      'timestamp': '2026-11-10T10:00:00',
      'monto': 180000,
    });

    expect(point.timestamp, DateTime(2026, 11, 10, 10));
    expect(point.monto, 180000);
  });

  test('ApiService consulta período y anterior y deserializa puntos', () async {
    final requestedUris = <Uri>[];
    final service = ApiService(
      client: MockClient((request) async {
        requestedUris.add(request.url);
        final anterior = request.url.queryParameters['anterior'] == 'true';
        return http.Response(
          jsonEncode([
            {
              'timestamp': anterior
                  ? '2026-11-03T00:00:00'
                  : '2026-11-10T00:00:00',
              'monto': anterior ? 50 : 180000,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final actual = await service.getVentasSerie(SalesPeriod.week);
    final anterior = await service.getVentasSerie(
      SalesPeriod.week,
      anterior: true,
    );

    expect(requestedUris, hasLength(2));
    expect(
      requestedUris.every((uri) => uri.path.endsWith('/ventas/serie')),
      isTrue,
    );
    expect(
      requestedUris.map((uri) => uri.queryParameters['periodo']),
      everyElement('semana'),
    );
    expect(actual.single.monto, 180000);
    expect(anterior.single.monto, 50);
  });

  test(
    'KitchenDataService usa la respuesta API y reserva DemoSales para MOCK',
    () async {
      final apiService = ApiService.instance;
      apiService.httpClient = MockClient((request) async {
        final anterior = request.url.queryParameters['anterior'] == 'true';
        if (request.url.queryParameters['periodo'] == 'mes') {
          return http.Response('[]', 200);
        }
        return http.Response(
          jsonEncode([
            {
              'timestamp': anterior
                  ? '2026-11-03T00:00:00'
                  : '2026-11-10T00:00:00',
              'monto': anterior ? 40 : 321000,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = KitchenDataService.instance;
      await service.loadSalesSeries(SalesPeriod.week);
      final apiSeries = service.salesSeriesForPeriod(SalesPeriod.week);

      expect(apiSeries.current.single.value, 321000);
      expect(apiSeries.previous!.single.value, 40);
      expect(service.ventasForPeriod(SalesPeriod.week).totalVentas, 0);
      expect(service.rankingModelsForPeriod(SalesPeriod.week), isEmpty);

      await service.loadSalesSeries(SalesPeriod.month);
      expect(service.salesSeriesForPeriod(SalesPeriod.month).isEmpty, isTrue);

      await EnvironmentConfig.instance.setMode(DataSourceMode.mock);
      final mockSeries = service.salesSeriesForPeriod(SalesPeriod.week);
      expect(mockSeries.total, greaterThan(0));
      expect(mockSeries.total, isNot(321000));
      expect(
        service.ventasForPeriod(SalesPeriod.week).totalVentas,
        greaterThan(0),
      );
    },
  );
}
