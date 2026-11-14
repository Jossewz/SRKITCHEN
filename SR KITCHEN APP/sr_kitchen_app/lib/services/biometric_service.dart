import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'app_exception.dart';

/// Estado de disponibilidad del hardware biométrico del dispositivo.
enum BiometricAvailability {
  available, // Dispositivo compatible y con huella/biometría registrada
  noHardware, // El teléfono no dispone de sensor biométrico compatible
  notEnrolled, // Tiene sensor, pero el usuario no ha registrado ninguna huella
  unsupported, // Plataforma no soportada
}

extension BiometricAvailabilityX on BiometricAvailability {
  bool get isReady => this == BiometricAvailability.available;

  String get statusLabel => switch (this) {
    BiometricAvailability.available => 'Sensor biométrico disponible y configurado',
    BiometricAvailability.noHardware =>
      'Este dispositivo no cuenta con lector biométrico compatible',
    BiometricAvailability.notEnrolled =>
      'No hay huellas digitales registradas en la configuración de Android',
    BiometricAvailability.unsupported =>
      'Autenticación biométrica no disponible en esta plataforma',
  };
}

/// Servicio real de autenticación biométrica Android basado en `local_auth`.
/// No almacena ni procesa imágenes de huellas; delega exclusivamente en el
/// keystore y prompt biométrico del sistema operativo Android.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
    : _auth = localAuth ?? LocalAuthentication();

  static final BiometricService instance = BiometricService();

  LocalAuthentication _auth;

  @visibleForTesting
  BiometricAvailability? testAvailabilityOverride;

  @visibleForTesting
  bool? testAuthenticateResultOverride;

  @visibleForTesting
  set localAuth(LocalAuthentication auth) => _auth = auth;

  /// Verifica el soporte físico del dispositivo y si existen huellas enroladas.
  Future<BiometricAvailability> checkAvailability() async {
    if (testAvailabilityOverride != null) {
      return testAvailabilityOverride!;
    }
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheck) {
        return BiometricAvailability.noHardware;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }
      return BiometricAvailability.available;
    } on PlatformException {
      return BiometricAvailability.unsupported;
    } catch (_) {
      return BiometricAvailability.unsupported;
    }
  }

  Future<bool> canCheckBiometrics() async {
    final a = await checkAvailability();
    return a != BiometricAvailability.noHardware && a != BiometricAvailability.unsupported;
  }

  Future<bool> isEnrolled() async {
    final a = await checkAvailability();
    return a == BiometricAvailability.available;
  }

  /// Solicita autenticación biométrica nativa al administrador.
  /// Lanza [AppException] con mensaje comprensible si no es compatible o falla.
  Future<bool> authenticate({
    String reason =
        'Confirma tu identidad con huella digital para acceder a SR Kitchen Mobile',
  }) async {
    final availability = await checkAvailability();
    if (!availability.isReady) {
      throw AppException.biometric(availability.statusLabel);
    }

    if (testAuthenticateResultOverride != null) {
      return testAuthenticateResultOverride!;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('notenrolled') || code.contains('not_enrolled')) {
        throw AppException.biometric(
          'No tienes huellas registradas en este dispositivo Android.',
        );
      }
      if (code.contains('notavailable') || code.contains('not_available')) {
        throw AppException.biometric(
          'El lector de huella digital no está disponible en este dispositivo.',
        );
      }
      if (code.contains('lockedout') || code.contains('locked_out')) {
        throw AppException.biometric(
          'El sensor biométrico se bloqueó temporalmente por demasiados intentos. Usa tu correo y contraseña.',
        );
      }
      throw AppException.biometric(
        'No se pudo completar la verificación biométrica. Puedes ingresar con tu contraseña.',
      );
    } catch (_) {
      throw AppException.biometric(
        'Ocurrió un inconveniente al verificar la huella digital.',
      );
    }
  }
}

