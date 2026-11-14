import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/mock_backend_source.dart';
import '../models/api_models.dart';
import 'api_service.dart';
import 'app_exception.dart';
import 'biometric_service.dart';
import 'environment_config.dart';

abstract class AuthRepository {
  Future<AuthSessionModel> login(String userOrEmail, String password);
}

/// Servicio centralizado de autenticación administrativa, gestión de sesión JWT
/// y desbloqueo biométrico seguro (`flutter_secure_storage` + `local_auth`).
///
/// Reglas de seguridad aplicadas:
/// - Nunca almacena contraseñas en texto plano.
/// - Solo permite acceso a usuarios con rol `ADMIN` (`ROLE_ADMIN`).
/// - Respeta la fecha de expiración del JWT.
/// - La huella digital solo desbloquea una sesión administrativa previamente
///   autenticada y vigente; nunca sustituye la autorización del backend.
class AuthService extends ChangeNotifier implements AuthRepository {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storageKeySession = 'sr_kitchen_secure_session_v1';
  static const _storageKeyBiometricEnabled = 'sr_kitchen_biometric_enabled_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Almacenamiento en memoria de respaldo para entornos de prueba (flutter test)
  /// donde los canales nativos de Keystore no están activos.
  final Map<String, String> _memoryFallback = {};

  AuthSessionModel? _currentSession;
  AuthSessionModel? _storedSessionForBiometrics;
  bool _biometricEnabled = false;
  bool _initialized = false;

  AuthSessionModel? get currentSession => _currentSession;
  AuthSessionModel? get storedSession =>
      _currentSession ?? _storedSessionForBiometrics;
  AuthSessionModel? get session => storedSession;
  bool get isAuthenticated =>
      _currentSession != null &&
      _currentSession!.isAdmin &&
      !_currentSession!.isExpired;

  bool get biometricEnabled => _biometricEnabled;
  bool get isBiometricEnabled => _biometricEnabled;

  /// Indica si existe una sesión administrativa guardada y vigente que puede
  /// desbloquearse con huella digital.
  bool get canUnlockWithBiometrics =>
      _biometricEnabled &&
      _storedSessionForBiometrics != null &&
      _storedSessionForBiometrics!.isAdmin &&
      !_storedSessionForBiometrics!.isExpired;

  String get displayName =>
      storedSession?.nombre ?? MockBackendSource.defaultRestaurantName;
  String get displayEmail =>
      storedSession?.email ?? MockBackendSource.defaultAdminEmail;
  int get currentRestaurantId =>
      storedSession?.restaurantId ?? MockBackendSource.defaultRestaurantId;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    ApiService.instance.onSessionExpired = handleSessionExpired;

    try {
      final rawBio = await _readSecure(_storageKeyBiometricEnabled);
      _biometricEnabled = rawBio == 'true';

      final rawSession = await _readSecure(_storageKeySession);
      if (rawSession != null && rawSession.isNotEmpty) {
        final map = jsonDecode(rawSession) as Map<String, dynamic>;
        final saved = AuthSessionModel.fromJson(map);
        if (saved.isAdmin && !saved.isExpired) {
          _storedSessionForBiometrics = saved;
        } else {
          await _deleteSecure(_storageKeySession);
        }
      }
    } catch (_) {
      _storedSessionForBiometrics = null;
    }
    notifyListeners();
  }

  /// Inicia sesión con correo y contraseña validando rol ADMIN.
  @override
  Future<AuthSessionModel> login(String userOrEmail, String password) async {
    final mode = EnvironmentConfig.instance.mode;
    AuthSessionModel session;

    if (mode == DataSourceMode.mock) {
      session = await MockBackendSource.instance.login(userOrEmail, password);
    } else if (mode == DataSourceMode.api) {
      session = await ApiService.instance.login(userOrEmail, password);
    } else {
      // Modo Híbrido: intenta primero el backend real; si no está desplegado o
      // es inaccesible, utiliza la fuente simulada coherente.
      // Si el backend responde 401/403 (credenciales inválidas o rol no ADMIN),
      // se propaga inmediatamente el error sin usar el mock.
      try {
        session = await ApiService.instance.login(userOrEmail, password);
      } on AppException catch (e) {
        if (e.isNetworkRelated) {
          session = await MockBackendSource.instance.login(
            userOrEmail,
            password,
          );
        } else {
          rethrow;
        }
      }
    }

    if (!session.isAdmin) {
      throw AppException.nonAdminRole(session.role);
    }
    if (session.isExpired) {
      throw AppException.sessionExpired();
    }

    _currentSession = session;
    _storedSessionForBiometrics = session;
    ApiService.instance.setAuthToken(session.token);

    await _writeSecure(_storageKeySession, jsonEncode(session.toJson()));
    notifyListeners();
    return session;
  }

  /// Habilita o deshabilita el desbloqueo biométrico tras verificar el hardware
  /// y solicitar confirmación de huella al administrador.
  Future<void> setBiometricEnabled(
    bool enable, {
    bool verifyBiometricNow = true,
  }) async {
    if (!enable) {
      _biometricEnabled = false;
      await _writeSecure(_storageKeyBiometricEnabled, 'false');
      notifyListeners();
      return;
    }

    final activeSession = _currentSession ?? _storedSessionForBiometrics;
    if (activeSession == null || !activeSession.isAdmin) {
      throw AppException.biometric(
        'Debes iniciar sesión como Administrador antes de activar la huella digital.',
      );
    }

    final availability = await BiometricService.instance.checkAvailability();
    if (!availability.isReady) {
      throw AppException.biometric(availability.statusLabel);
    }

    if (verifyBiometricNow) {
      final confirmed = await BiometricService.instance.authenticate(
        reason:
            'Confirma tu huella digital para habilitar el acceso rápido en SR Kitchen',
      );
      if (!confirmed) {
        throw AppException.biometric(
          'No se confirmó la huella digital. La biometría permanece desactivada.',
        );
      }
    }

    _biometricEnabled = true;
    await _writeSecure(_storageKeyBiometricEnabled, 'true');
    await _writeSecure(_storageKeySession, jsonEncode(activeSession.toJson()));
    notifyListeners();
  }

  /// Desbloquea la sesión administrativa previamente almacenada usando huella digital.
  /// Funciona también sin conexión a internet para consultar datos en caché local.
  Future<AuthSessionModel> unlockWithBiometrics() async {
    await init();

    final saved = _storedSessionForBiometrics;
    if (saved == null) {
      throw AppException.biometric(
        'Primero inicia sesión con tu correo y contraseña de Administrador para vincular tu huella digital.',
      );
    }

    if (!saved.isAdmin) {
      await clearAllSessionData();
      throw AppException.nonAdminRole(saved.role);
    }

    if (saved.isExpired) {
      await clearAllSessionData();
      throw AppException.sessionExpired();
    }

    if (!_biometricEnabled) {
      throw AppException.biometric(
        'La autenticación biométrica está desactivada. Actívala en tu Perfil después de iniciar sesión.',
      );
    }

    final authenticated = await BiometricService.instance.authenticate(
      reason: 'Desbloquea tu sesión de ${saved.nombre} con huella digital',
    );
    if (!authenticated) {
      throw AppException.biometric(
        'Verificación biométrica cancelada o no reconocida.',
      );
    }

    _currentSession = saved;
    ApiService.instance.setAuthToken(saved.token);
    notifyListeners();
    return saved;
  }

  /// Bloquea la sesión activa en pantalla pero conserva el token cifrado si
  /// la biometría está activa para permitir reingreso con huella.
  Future<void> lockSession() async {
    _currentSession = null;
    ApiService.instance.setAuthToken(null);
    notifyListeners();
  }

  /// Cierra la sesión. Si `keepBiometricCredential` es true y la biometría está
  /// activa, conserva el token cifrado para el próximo desbloqueo por huella;
  /// si es false, elimina por completo el token del almacenamiento seguro.
  Future<void> logout({bool keepBiometricCredential = true}) async {
    _currentSession = null;
    ApiService.instance.setAuthToken(null);
    if (!keepBiometricCredential || !_biometricEnabled) {
      _storedSessionForBiometrics = null;
      await _deleteSecure(_storageKeySession);
    }
    notifyListeners();
  }

  Future<void> clearAllSessionData() async {
    _currentSession = null;
    _storedSessionForBiometrics = null;
    _biometricEnabled = false;
    ApiService.instance.setAuthToken(null);
    await _deleteSecure(_storageKeySession);
    await _writeSecure(_storageKeyBiometricEnabled, 'false');
    notifyListeners();
  }

  void handleSessionExpired() {
    _currentSession = null;
    _storedSessionForBiometrics = null;
    ApiService.instance.setAuthToken(null);
    _deleteSecure(_storageKeySession);
    notifyListeners();
  }

  @visibleForTesting
  Future<void> seedSessionForTesting(
    AuthSessionModel session, {
    bool enableBiometric = false,
  }) async {
    _currentSession = session;
    _storedSessionForBiometrics = session;
    _biometricEnabled = enableBiometric;
    ApiService.instance.setAuthToken(session.token);
    await _writeSecure(_storageKeySession, jsonEncode(session.toJson()));
    await _writeSecure(
      _storageKeyBiometricEnabled,
      enableBiometric ? 'true' : 'false',
    );
    notifyListeners();
  }

  Future<String?> _readSecure(String key) async {
    if (_memoryFallback.containsKey(key)) return _memoryFallback[key];
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> _deleteSecure(String key) async {
    _memoryFallback.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }
}

final AuthRepository authRepository = AuthService.instance;
