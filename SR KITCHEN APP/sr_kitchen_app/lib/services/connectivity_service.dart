import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'environment_config.dart';

/// Estado detallado de conectividad de red y disponibilidad del backend.
///
/// No considera que estar conectado a Wi-Fi signifique necesariamente tener
/// acceso a internet o al servidor; comprueba salida real y estado del backend.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// `true` = hay salida a Internet (y no está activo el modo offline simulado).
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  /// `true` = el servidor backend Spring Boot respondió recientemente.
  final ValueNotifier<bool> backendReachable = ValueNotifier<bool>(false);

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _simulatedOffline = false;
  bool _checking = false;

  /// Callback invocado automáticamente cuando el dispositivo recupera la
  /// conexión tras haber estado sin red.
  VoidCallback? onConnectionRestored;

  bool get simulatedOffline =>
      _simulatedOffline ||
      EnvironmentConfig.instance.simulatedState == SimulatedVisualState.offline;

  /// Útil para probar las vistas sin desactivar la red física del dispositivo.
  void setSimulatedOffline(bool value) {
    _simulatedOffline = value;
    if (value) {
      EnvironmentConfig.instance.setSimulatedState(
        SimulatedVisualState.offline,
      );
    } else if (EnvironmentConfig.instance.simulatedState ==
        SimulatedVisualState.offline) {
      EnvironmentConfig.instance.setSimulatedState(SimulatedVisualState.none);
    }
    check();
  }

  void start() {
    if (_timer != null) return;
    check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => check());
    try {
      _connSub = Connectivity().onConnectivityChanged.listen((results) {
        final hasInterface = results.any((r) => r != ConnectivityResult.none);
        if (!hasInterface) {
          _updateOnlineState(false, backendOk: false);
        } else {
          check();
        }
      });
    } catch (_) {
      // En entorno de test sin canal nativo de connectivity_plus se ignora el stream
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _connSub?.cancel();
    _connSub = null;
  }

  Future<bool> check() async {
    if (_checking) return online.value;
    _checking = true;
    try {
      if (simulatedOffline) {
        _updateOnlineState(false, backendOk: false);
        return false;
      }

      bool hasNet = false;
      try {
        final r = await InternetAddress.lookup(
          'example.com',
        ).timeout(const Duration(seconds: 3));
        hasNet = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
      } on SocketException {
        hasNet = false;
      } on TimeoutException {
        hasNet = false;
      } catch (_) {
        hasNet = false;
      }

      bool backendOk = false;
      if (EnvironmentConfig.instance.mode != DataSourceMode.mock) {
        backendOk = await ApiService.instance.probeBackendReachable();
        if (backendOk) {
          hasNet = true; // Si el servidor local responde en LAN, hay red operativa
        }
      }

      _updateOnlineState(hasNet, backendOk: backendOk);
    } finally {
      _checking = false;
    }
    return online.value;
  }

  void _updateOnlineState(bool newOnline, {required bool backendOk}) {
    final wasOffline = !online.value;
    final changed =
        online.value != newOnline || backendReachable.value != backendOk;

    online.value = newOnline;
    backendReachable.value = backendOk;

    if (changed) {
      notifyListeners();
    }
    if (wasOffline && newOnline) {
      onConnectionRestored?.call();
    }
  }
}
