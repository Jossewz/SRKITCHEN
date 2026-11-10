/// Tipos de error normalizados en toda la aplicación SR Kitchen Mobile.
enum AppErrorKind {
  badRequest, // HTTP 400
  unauthorized, // HTTP 401
  forbidden, // HTTP 403 / No es ADMIN / Restaurante desactivado
  notFound, // HTTP 404
  serverError, // HTTP 500+
  serialization, // JSON inválido o respuesta vacía
  noInternet, // Sin salida a internet
  serverUnreachable, // Internet activo pero backend Spring Boot apagado/inaccesible
  timeout, // Tiempo de espera agotado
  sessionExpired, // JWT vencido
  biometricError, // Fallo o indisponibilidad biométrica
  storageError, // Fallo de almacenamiento local / caché
  unknown,
}

/// Excepción centralizada con mensajes amigables para el administrador del restaurante.
/// Nunca expone trazas internas, tokens ni credenciales en la interfaz.
class AppException implements Exception {
  final AppErrorKind kind;
  final String title;
  final String userMessage;
  final int? statusCode;
  final bool canRetry;

  const AppException({
    required this.kind,
    required this.title,
    required this.userMessage,
    this.statusCode,
    this.canRetry = true,
  });

  bool get isAuthFatal =>
      kind == AppErrorKind.unauthorized ||
      kind == AppErrorKind.forbidden ||
      kind == AppErrorKind.sessionExpired;

  bool get isNetworkRelated =>
      kind == AppErrorKind.noInternet ||
      kind == AppErrorKind.serverUnreachable ||
      kind == AppErrorKind.timeout;

  factory AppException.fromHttpStatus(
    int statusCode, {
    String? backendErrorMessage,
    bool isLoginAttempt = false,
  }) {
    final cleanMsg = _sanitizeBackendMessage(backendErrorMessage);
    switch (statusCode) {
      case 400:
        return AppException(
          kind: AppErrorKind.badRequest,
          statusCode: 400,
          title: 'Datos incompletos',
          userMessage:
              cleanMsg ??
              'Verifica los datos ingresados e inténtalo nuevamente.',
          canRetry: false,
        );
      case 401:
        if (isLoginAttempt) {
          return AppException(
            kind: AppErrorKind.unauthorized,
            statusCode: 401,
            title: 'Credenciales incorrectas',
            userMessage:
                cleanMsg ??
                'El correo o la contraseña no son correctos. Verifica tus datos.',
            canRetry: false,
          );
        }
        return const AppException(
          kind: AppErrorKind.sessionExpired,
          statusCode: 401,
          title: 'Sesión expirada',
          userMessage:
              'Tu sesión administrativa ha expirado por seguridad. Inicia sesión nuevamente.',
          canRetry: false,
        );
      case 403:
        return AppException(
          kind: AppErrorKind.forbidden,
          statusCode: 403,
          title: 'Acceso restringido',
          userMessage:
              cleanMsg ??
              'Esta herramienta es exclusiva para el administrador autorizado del restaurante.',
          canRetry: false,
        );
      case 404:
        return AppException(
          kind: AppErrorKind.notFound,
          statusCode: 404,
          title: 'Información no encontrada',
          userMessage:
              cleanMsg ??
              'El recurso consultado ya no está disponible en el restaurante.',
          canRetry: false,
        );
      default:
        if (statusCode >= 500) {
          return const AppException(
            kind: AppErrorKind.serverError,
            statusCode: 500,
            title: 'Servidor temporalmente no disponible',
            userMessage:
                'El servidor de SR Kitchen presentó un inconveniente al procesar la solicitud. Intenta de nuevo en unos momentos.',
            canRetry: true,
          );
        }
        return AppException(
          kind: AppErrorKind.unknown,
          statusCode: statusCode,
          title: 'No se pudo completar la consulta',
          userMessage:
              cleanMsg ??
              'Ocurrió un problema inesperado al comunicarnos con el servidor.',
          canRetry: true,
        );
    }
  }

  factory AppException.nonAdminRole(String role) => const AppException(
    kind: AppErrorKind.forbidden,
    statusCode: 403,
    title: 'Acceso exclusivo para Administradores',
    userMessage:
        'Tu cuenta no cuenta con permisos de Administrador (ADMIN). SR Kitchen Mobile no permite el ingreso a perfiles operativos o de meseros.',
    canRetry: false,
  );

  factory AppException.noInternet() => const AppException(
    kind: AppErrorKind.noInternet,
    title: 'Sin conexión a Internet',
    userMessage:
        'No se detectó salida a Internet en el dispositivo. Revisa tu conexión Wi-Fi o datos móviles.',
    canRetry: true,
  );

  factory AppException.serverUnreachable([String? host]) => const AppException(
    kind: AppErrorKind.serverUnreachable,
    title: 'Servidor SR Kitchen inaccesible',
    userMessage:
        'El dispositivo tiene red, pero no fue posible conectar con el servidor del restaurante. Verifica que el backend esté en ejecución o usa la información almacenada.',
    canRetry: true,
  );

  factory AppException.timeout() => const AppException(
    kind: AppErrorKind.timeout,
    title: 'Tiempo de espera agotado',
    userMessage:
        'El servidor tardó demasiado en responder. Comprueba la estabilidad de tu conexión e inténtalo de nuevo.',
    canRetry: true,
  );

  factory AppException.serialization() => const AppException(
    kind: AppErrorKind.serialization,
    title: 'Respuesta de datos incompleta',
    userMessage:
        'La información recibida del servidor no tiene el formato esperado.',
    canRetry: true,
  );

  factory AppException.sessionExpired() => const AppException(
    kind: AppErrorKind.sessionExpired,
    statusCode: 401,
    title: 'Sesión finalizada',
    userMessage:
        'Tu sesión ha vencido. Ingresa nuevamente tus credenciales administrativas.',
    canRetry: false,
  );

  factory AppException.biometric(String message) => AppException(
    kind: AppErrorKind.biometricError,
    title: 'Autenticación biométrica',
    userMessage: message,
    canRetry: false,
  );

  static String? _sanitizeBackendMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();
    // Evitar mostrar trazas de Java o detalles internos de SQL/Hibernate
    if (text.contains('Exception') ||
        text.contains('org.springframework') ||
        text.contains('java.') ||
        text.contains('JDBC') ||
        text.length > 180) {
      return null;
    }
    return text;
  }

  @override
  String toString() => '$title: $userMessage';
}

