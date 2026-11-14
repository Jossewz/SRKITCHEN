import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import '../models/chart_models.dart';
import 'app_exception.dart';
import 'environment_config.dart';

/// Cliente HTTP centralizado para consumir el controlador `MobileApiController`
/// del backend Spring Boot en `/api/mobile/**`.
///
/// Características:
/// - Inyección automática del encabezado `Authorization: Bearer <token>`.
/// - Control de tiempos de espera (`timeout`).
/// - Deduplicación de solicitudes GET concurrentes hacia el mismo recurso.
/// - Detección automática de sesión expirada (HTTP 401).
/// - Traducción centralizada de errores técnicos a `AppException`.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static final ApiService instance = ApiService();

  http.Client _client;
  String? _jwtToken;
  VoidCallback? onSessionExpired;

  static const Duration defaultTimeout = Duration(seconds: 7);

  /// Mapa de solicitudes GET en curso para evitar peticiones duplicadas simultáneas.
  final Map<String, Future<dynamic>> _inFlightGets = {};

  @visibleForTesting
  set httpClient(http.Client client) => _client = client;

  void setAuthToken(String? token) {
    _jwtToken = (token != null && token.trim().isNotEmpty)
        ? token.trim()
        : null;
  }

  String? get authToken => _jwtToken;

  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (includeAuth && _jwtToken != null && _jwtToken!.isNotEmpty) {
      final tokenValue = _jwtToken!.startsWith('Bearer ')
          ? _jwtToken!
          : 'Bearer $_jwtToken';
      headers['Authorization'] = tokenValue;
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = EnvironmentConfig.instance.mobileApiBaseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final rawUrl = '$base$cleanEndpoint';
    final uri = Uri.parse(rawUrl);
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(queryParameters: queryParams);
  }

  // ===========================================================================
  // 1. AUTENTICACIÓN (`POST /api/mobile/login`)
  // ===========================================================================

  Future<AuthSessionModel> login(String correo, String password) async {
    final uri = _buildUri('/login');
    final body = jsonEncode({
      'correo': correo.trim(),
      'mail': correo.trim(),
      'contraseña': password,
      'password': password,
    });

    final decoded = await _sendRequest(
      () => _client.post(
        uri,
        headers: _buildHeaders(includeAuth: false),
        body: body,
      ),
      isLoginAttempt: true,
    );

    if (decoded is! Map<String, dynamic>) {
      throw AppException.serialization();
    }

    final session = AuthSessionModel.fromJson(decoded, isMock: false);
    if (session.token.isEmpty) {
      throw AppException.serialization();
    }
    if (!session.isAdmin) {
      throw AppException.nonAdminRole(session.role);
    }

    setAuthToken(session.token);
    return session;
  }

  // ===========================================================================
  // 2. DASHBOARD UNIFICADO (`GET /api/mobile/dashboard`)
  // ===========================================================================

  Future<MobileDashboardModel> getDashboard() async {
    final decoded = await _getDeduplicated('/dashboard');
    if (decoded is! Map<String, dynamic>) {
      throw AppException.serialization();
    }
    return MobileDashboardModel.fromJson(decoded);
  }

  // ===========================================================================
  // 3. INVENTARIO (`GET /api/mobile/inventario/**`)
  // ===========================================================================

  Future<List<ProductoInventarioModel>> getInventario({
    String? buscar,
    bool soloActivos = false,
  }) async {
    final params = <String, String>{};
    if (buscar != null && buscar.trim().isNotEmpty) {
      params['buscar'] = buscar.trim();
    }
    if (soloActivos) {
      params['soloActivos'] = 'true';
    }
    final decoded = await _getDeduplicated('/inventario', params);
    if (decoded is! List) {
      throw AppException.serialization();
    }
    return decoded
        .whereType<Map>()
        .map((e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<ProductoInventarioModel> getProductoPorId(int id) async {
    final decoded = await _getDeduplicated('/inventario/$id');
    if (decoded is! Map<String, dynamic>) {
      throw AppException.serialization();
    }
    return ProductoInventarioModel.fromJson(decoded);
  }

  Future<InventarioNivelesModel> getInventarioNiveles() async {
    final decoded = await _getDeduplicated('/inventario/niveles');
    if (decoded is! Map<String, dynamic>) {
      throw AppException.serialization();
    }
    return InventarioNivelesModel.fromJson(decoded);
  }

  Future<List<ProductoInventarioModel>> getProductosCriticos() async {
    final decoded = await _getDeduplicated('/inventario/criticos');
    if (decoded is! List) throw AppException.serialization();
    return decoded
        .whereType<Map>()
        .map((e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ProductoInventarioModel>> getProductosBajos() async {
    final decoded = await _getDeduplicated('/inventario/bajos');
    if (decoded is! List) throw AppException.serialization();
    return decoded
        .whereType<Map>()
        .map((e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ProductoInventarioModel>> getProductosNormales() async {
    final decoded = await _getDeduplicated('/inventario/normales');
    if (decoded is! List) throw AppException.serialization();
    return decoded
        .whereType<Map>()
        .map((e) => ProductoInventarioModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // ===========================================================================
  // 4. VENTAS (`GET /api/mobile/ventas/**`)
  // ===========================================================================

  Future<VentasTotalesModel> getVentasTotales() async {
    final decoded = await _getDeduplicated('/ventas/totales');
    if (decoded is! Map<String, dynamic>) throw AppException.serialization();
    return VentasTotalesModel.fromJson(decoded);
  }

  Future<List<VentaSerieModel>> getVentasSerie(
    SalesPeriod periodo, {
    bool anterior = false,
  }) async {
    final decoded = await _getDeduplicated('/ventas/serie', {
      'periodo': switch (periodo) {
        SalesPeriod.today => 'hoy',
        SalesPeriod.week => 'semana',
        SalesPeriod.month => 'mes',
      },
      if (anterior) 'anterior': 'true',
    });
    if (decoded is! List) throw AppException.serialization();
    try {
      return decoded.map((point) {
        if (point is! Map<String, dynamic>) {
          throw const FormatException('Punto de serie de ventas inválido');
        }
        return VentaSerieModel.fromJson(point);
      }).toList();
    } on FormatException {
      throw AppException.serialization();
    }
  }

  Future<PromedioVentasModel> getPromedioVentas() async {
    final decoded = await _getDeduplicated('/ventas/promedio');
    if (decoded is! Map<String, dynamic>) throw AppException.serialization();
    return PromedioVentasModel.fromJson(decoded);
  }

  Future<MejorVentaModel> getMejorVenta() async {
    final decoded = await _getDeduplicated('/ventas/mejor');
    if (decoded is! Map<String, dynamic>) throw AppException.serialization();
    return MejorVentaModel.fromJson(decoded);
  }

  // ===========================================================================
  // 5. PLATILLOS (`GET /api/mobile/platillos/**`)
  // ===========================================================================

  Future<PlatilloRankingModel?> getPlatilloMasVendido() async {
    final decoded = await _getDeduplicated('/platillos/mas-vendido');
    if (decoded is! Map<String, dynamic>) throw AppException.serialization();
    if (decoded['unidadesVendidas'] == 0 &&
        decoded['nombre'] == 'Sin registros') {
      return null;
    }
    return PlatilloRankingModel.fromJson(decoded);
  }

  Future<RankingPlatillosResponse> getMasPlatillosVendidos({
    int limite = 10,
  }) async {
    final decoded = await _getDeduplicated('/platillos/mas-vendidos', {
      'limite': '$limite',
    });
    if (decoded is! Map<String, dynamic>) throw AppException.serialization();
    return RankingPlatillosResponse.fromJson(decoded);
  }

  /// Comprueba rápidamente si el servidor Spring Boot responde.
  Future<bool> probeBackendReachable() async {
    try {
      final uri = _buildUri('/login');
      final response = await _client
          .post(uri, headers: _buildHeaders(includeAuth: false), body: '{}')
          .timeout(const Duration(seconds: 3));
      // Un 400 Bad Request de /api/mobile/login confirma que el servidor está vivo
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // INFRAESTRUCTURA INTERNA DE PETICIONES Y DEDUPLICACIÓN
  // ===========================================================================

  Future<dynamic> _getDeduplicated(
    String endpoint, [
    Map<String, String>? queryParams,
  ]) {
    final uri = _buildUri(endpoint, queryParams);
    final key = uri.toString();
    final existing = _inFlightGets[key];
    if (existing != null) return existing;

    final future =
        _sendRequest(() => _client.get(uri, headers: _buildHeaders()))
            .whenComplete(() {
              _inFlightGets.remove(key);
            });

    _inFlightGets[key] = future;
    return future;
  }

  Future<dynamic> _sendRequest(
    Future<http.Response> Function() requestFn, {
    bool isLoginAttempt = false,
  }) async {
    http.Response response;
    try {
      response = await requestFn().timeout(defaultTimeout);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('connection refused') ||
          msg.contains('reset') ||
          msg.contains('unreachable')) {
        throw AppException.serverUnreachable(
          EnvironmentConfig.instance.baseUrl,
        );
      }
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnreachable(EnvironmentConfig.instance.baseUrl);
    } catch (_) {
      throw AppException.serverUnreachable(EnvironmentConfig.instance.baseUrl);
    }

    final rawBody = utf8.decode(response.bodyBytes);
    dynamic decodedJson;
    if (rawBody.trim().isNotEmpty) {
      try {
        decodedJson = jsonDecode(rawBody);
      } catch (_) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw AppException.serialization();
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedJson == null) {
        throw AppException.serialization();
      }
      return decodedJson;
    }

    String? backendError;
    if (decodedJson is Map) {
      backendError =
          (decodedJson['error'] ??
                  decodedJson['mensaje'] ??
                  decodedJson['message'])
              ?.toString();
    }

    final ex = AppException.fromHttpStatus(
      response.statusCode,
      backendErrorMessage: backendError,
      isLoginAttempt: isLoginAttempt,
    );

    if (!isLoginAttempt && response.statusCode == 401) {
      onSessionExpired?.call();
    }

    throw ex;
  }
}
