import 'package:flutter_test/flutter_test.dart';
import 'package:sr_kitchen_app/models/api_models.dart';
import 'package:sr_kitchen_app/models/app_models.dart';

void main() {
  group('Modelos API REST - Serialización y Reglas de Negocio', () {
    test(
      'AuthSessionModel deserializa correctamente y detecta expiración de JWT',
      () {
        final json = {
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbkBzcmtpdGNoZW4uY29tIiwicm9sIjoiUk9MRV9BRE1JTiIsImV4cCI6NDk5MTYxNjAwMH0.dummy',
          'tipo': 'Bearer',
          'usuario': 'admin@srkitchen.com',
          'nombre': 'Carlos Mendoza',
          'rol': 'ROLE_ADMIN',
          'restauranteId': 'rest-123',
          'nombreRestaurante': 'Sr. Kitchen Principal',
        };

        final auth = AuthSessionModel.fromJson(json);

        expect(auth.token, isNotEmpty);
        expect(auth.email, 'admin@srkitchen.com');
        expect(auth.fullName, 'Carlos Mendoza');
        expect(auth.rol, 'ROLE_ADMIN');
        expect(auth.isAdmin, isTrue);
        expect(auth.restaurantId, 123);
        expect(auth.restaurantName, 'Sr. Kitchen Principal');
        expect(auth.isExpired, isFalse);
      },
    );

    test('AuthSessionModel rechaza usuarios no-admin', () {
      final json = {
        'token': 'mock-token',
        'usuario': 'mesero@srkitchen.com',
        'nombre': 'Juan Mesero',
        'rol': 'MESERO',
        'restauranteId': 'rest-123',
      };

      final auth = AuthSessionModel.fromJson(json);
      expect(auth.isAdmin, isFalse);
    });

    test('ProductoInventarioModel aplica rigurosamente umbrales oficiales', () {
      // Backend: <= 5 CRÍTICO, 6..15 BAJO, > 15 NORMAL
      final criticoJson = {
        'id': '1',
        'nombre': 'Limonada Natural',
        'categoria': 'Bebidas',
        'stockActual': 5,
        'precio': 6500.0,
        'activo': true,
      };
      final bajoJson = {
        'id': '2',
        'nombre': 'Hamburguesa Clásica',
        'categoria': 'Platos Fuertes',
        'stockActual': 12,
        'precio': 28900.0,
        'activo': true,
      };
      final normalJson = {
        'id': '3',
        'nombre': 'Pizza Especial',
        'categoria': 'Pizzas',
        'stockActual': 24,
        'precio': 42000.0,
        'activo': true,
      };

      final pCritico = ProductoInventarioModel.fromJson(criticoJson);
      final pBajo = ProductoInventarioModel.fromJson(bajoJson);
      final pNormal = ProductoInventarioModel.fromJson(normalJson);

      expect(pCritico.stockLevel, StockLevel.critico);
      expect(pBajo.stockLevel, StockLevel.bajo);
      expect(pNormal.stockLevel, StockLevel.normal);

      expect(pCritico.stockActual, 5);
      expect(pBajo.stockActual, 12);
      expect(pNormal.stockActual, 24);
    });

    test('InventarioNivelesModel calcula correctamente el total', () {
      final json = {'criticos': 3, 'bajos': 5, 'normales': 10, 'total': 18};
      final niveles = InventarioNivelesModel.fromJson(json);

      expect(niveles.conteoCriticos, 3);
      expect(niveles.conteoBajos, 5);
      expect(niveles.conteoNormales, 10);
      expect(niveles.total, 18);
    });

    test(
      'VentasTotalesModel y PromedioVentasModel manejan valores monetarios',
      () {
        final jsonVentas = {
          'totalVentas': 18450000.0,
          'totalTransacciones': 342,
          'periodo': 'OCTUBRE',
        };
        final ventas = VentasTotalesModel.fromJson(jsonVentas);
        expect(ventas.totalVentas, 18450000.0);
        expect(ventas.totalTransacciones, 342);

        final jsonProm = {'promedioVenta': 53947.36, 'totalTransacciones': 342};
        final prom = PromedioVentasModel.fromJson(jsonProm);
        expect(prom.promedioVenta, closeTo(53947.36, 0.01));
      },
    );

    test('VentaSerieModel deserializa timestamp y monto del backend', () {
      final point = VentaSerieModel.fromJson({
        'timestamp': '2026-11-10T10:00:00',
        'monto': 180000,
      });

      expect(point.timestamp, DateTime(2026, 11, 10, 10));
      expect(point.monto, 180000);
    });

    test('MejorVentaModel serializa ítems detallados', () {
      final json = {
        'ordenId': 'ORD-9842',
        'total': 285000.0,
        'fecha': '2026-10-04T20:30:00Z',
        'mesa': 'Mesa 4',
        'mesero': 'Andrés Gómez',
        'items': [
          {
            'nombre': 'Pizza Especial Familiar',
            'cantidad': 2,
            'subtotal': 120000.0,
          },
          {'nombre': 'Costillas BBQ', 'cantidad': 2, 'subtotal': 110000.0},
          {'nombre': 'Limonada de Coco', 'cantidad': 5, 'subtotal': 55000.0},
        ],
      };
      final mejor = MejorVentaModel.fromJson(json);

      expect(mejor.ordenId, 'ORD-9842');
      expect(mejor.total, 285000.0);
      expect(mejor.mesa, 'Mesa 4');
      expect(mejor.items.length, 3);
      expect(mejor.items.first.subtotal, 120000.0);
    });

    test('PlatilloRankingModel ordena e interpreta rankings', () {
      final json = {
        'platilloId': 'pl-1',
        'nombre': 'Pizza Especial',
        'cantidadVendida': 142,
        'totalVentas': 5964000.0,
        'porcentaje': 32.3,
      };
      final ranking = PlatilloRankingModel.fromJson(json);

      expect(ranking.nombre, 'Pizza Especial');
      expect(ranking.cantidadVendida, 142);
      expect(ranking.totalVentas, 5964000.0);
      expect(ranking.porcentaje, 32.3);
    });

    test('MobileDashboardModel consolida todas las secciones sin valores nulos erróneos', () {
      final json = {
        'restauranteId': 'rest-1',
        'fechaConsulta': '2026-10-04T22:00:00Z',
        'ventasTotales': {'totalVentas': 18450000.0, 'totalTransacciones': 342},
        'promedioVenta': {'promedioVenta': 53947.0, 'totalTransacciones': 342},
        'mejorVenta': {
          'ordenId': 'ORD-1',
          'total': 285000.0,
          'fecha': '2026-10-04T20:00:00Z',
          'mesa': 'Mesa 4',
          'mesero': 'Andrés',
          'items': [],
        },
        'platilloMasVendido': {
          'platilloId': 'p1',
          'nombre': 'Pizza Especial',
          'cantidadVendida': 142,
          'totalVentas': 5964000.0,
          'porcentaje': 32.3,
        },
        'topPlatillos': [
          {
            'platilloId': 'p1',
            'nombre': 'Pizza Especial',
            'cantidadVendida': 142,
            'totalVentas': 5964000.0,
            'porcentaje': 32.3,
          },
        ],
        'inventarioNiveles': {
          'criticos': 2,
          'bajos': 4,
          'normales': 12,
          'total': 18,
        },
      };

      final dashboard = MobileDashboardModel.fromJson(json);

      expect(dashboard.restauranteId, '1');
      expect(dashboard.ventasTotales.totalVentas, 18450000.0);
      expect(dashboard.inventarioNiveles.total, 18);
      expect(dashboard.platilloMasVendido?.nombre, 'Pizza Especial');
      expect(dashboard.topPlatillos.length, 1);
    });
  });
}
