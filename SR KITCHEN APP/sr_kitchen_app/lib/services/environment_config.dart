import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modos de operación de la fuente de datos.
enum DataSourceMode {
  /// Utiliza exclusivamente la fuente de datos simulada coherente (`MockBackendSource`),
  /// ideal cuando el backend y la base de datos no están desplegados.
  mock,

  /// Consume exclusivamente la API REST real de Spring Boot (`/api/mobile/**`),
  /// utilizando la caché local persistente cuando se pierde la conexión.
  api,

  /// Intenta consumir la API REST real; si el servidor local no está levantado,
  /// utiliza la caché persistente o los datos simulados identificando el origen.
  hybrid,
}

typedef DataMode = DataSourceMode;

extension DataSourceModeX on DataSourceMode {
  String get label => switch (this) {
    DataSourceMode.mock => 'Modo Demo (Mock)',
    DataSourceMode.api => 'Modo API Real',
    DataSourceMode.hybrid => 'Híbrido (API + Demo)',
  };

  String get shortBadge => switch (this) {
    DataSourceMode.mock => 'DEMO · MOCK',
    DataSourceMode.api => 'API REST',
    DataSourceMode.hybrid => 'AUTO',
  };
}

/// Escenarios visuales simulables para validar estados de UI según el Complemento.
enum SimulatedVisualState {
  none,
  loading,
  error,
  empty,
  offline,
}

extension SimulatedVisualStateX on SimulatedVisualState {
  String get label => switch (this) {
    SimulatedVisualState.none => 'Operación normal',
    SimulatedVisualState.loading => 'Cargando (Skeletons)',
    SimulatedVisualState.error => 'Error de servidor (HTTP 500)',
    SimulatedVisualState.empty => 'Sin registros (Vacío)',
    SimulatedVisualState.offline => 'Sin conexión (Caché Offline)',
  };
}

/// Configuración centralizada de entorno, URL del backend y modo de datos.
/// Recuerda que en Android físico/emulador `localhost` apunta al propio teléfono;
/// en emulador Android se usa `10.0.2.2` por defecto.
class EnvironmentConfig extends ChangeNotifier {
  EnvironmentConfig._();
  static final EnvironmentConfig instance = EnvironmentConfig._();

  static const _prefKeyBaseUrl = 'sr_kitchen_base_url';
  static const _prefKeyMode = 'sr_kitchen_data_mode';
  static const _prefKeyLockOnResume = 'sr_kitchen_lock_on_resume';
  static const _prefKeyInactivityMinutes = 'sr_kitchen_inactivity_min';

  /// URL por defecto según plataforma (10.0.2.2 para emulador Android).
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  String _baseUrl = defaultBaseUrl;
  DataSourceMode _mode = DataSourceMode.hybrid;
  SimulatedVisualState _simulatedState = SimulatedVisualState.none;
  bool _lockOnResume = true;
  int _inactivityMinutes = 15;

  String get baseUrl => _baseUrl;
  String get mobileApiBaseUrl => '$_baseUrl/api/mobile';
  DataSourceMode get mode => _mode;
  SimulatedVisualState get simulatedState => _simulatedState;
  bool get lockOnResume => _lockOnResume;
  int get inactivityMinutes => _inactivityMinutes;

  bool get isUsingMockOnly => _mode == DataSourceMode.mock;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKeyBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = _normalizeUrl(savedUrl);
      }
      final savedMode = prefs.getString(_prefKeyMode);
      if (savedMode != null) {
        _mode = DataSourceMode.values.firstWhere(
          (e) => e.name == savedMode,
          orElse: () => DataSourceMode.hybrid,
        );
      }
      _lockOnResume = prefs.getBool(_prefKeyLockOnResume) ?? true;
      _inactivityMinutes = prefs.getInt(_prefKeyInactivityMinutes) ?? 15;
      notifyListeners();
    } catch (_) {
      // Mantiene valores por defecto si SharedPreferences no está listo en un test aislado
    }
  }

  Future<void> setBaseUrl(String url) async {
    final clean = _normalizeUrl(url);
    if (clean.isEmpty || clean == _baseUrl) return;
    _baseUrl = clean;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBaseUrl, _baseUrl);
    } catch (_) {}
  }

  Future<void> setMode(DataSourceMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyMode, newMode.name);
    } catch (_) {}
  }

  void setSimulatedState(SimulatedVisualState state) {
    if (_simulatedState == state) return;
    _simulatedState = state;
    notifyListeners();
  }

  Future<void> setLockOnResume(bool value) async {
    _lockOnResume = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyLockOnResume, value);
    } catch (_) {}
  }

  Future<void> setInactivityMinutes(int minutes) async {
    _inactivityMinutes = minutes;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyInactivityMinutes, minutes);
    } catch (_) {}
  }

  static String _normalizeUrl(String raw) {
    var trimmed = raw.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api/mobile')) {
      trimmed = trimmed.substring(0, trimmed.length - '/api/mobile'.length);
    }
    return trimmed;
  }
}

