import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/cache_service.dart';
import '../services/environment_config.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _biometric;

  @override
  void initState() {
    super.initState();
    _biometric = AuthService.instance.isBiometricEnabled;
  }

  String get _displayName {
    final session = AuthService.instance.session;
    if (session != null && session.fullName.trim().isNotEmpty) {
      return session.fullName;
    }
    return DemoData.userName;
  }

  String get _displayEmail {
    final session = AuthService.instance.session;
    if (session != null && session.email.trim().isNotEmpty) {
      return session.email;
    }
    return DemoData.userEmail;
  }

  String get _displayRestaurant {
    final session = AuthService.instance.session;
    if (session != null && session.restaurantName.trim().isNotEmpty) {
      return session.restaurantName;
    }
    return DemoData.restaurant;
  }

  String get _displayRole {
    final session = AuthService.instance.session;
    return session?.rol ?? 'ADMIN';
  }

  String get _initials {
    final parts = _displayName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SK';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable) {
      final canCheck = await BiometricService.instance.canCheckBiometrics();
      final enrolled = await BiometricService.instance.isEnrolled();
      if (!canCheck || !enrolled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este dispositivo no tiene biometría configurada o activa.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _biometric = false);
        return;
      }
    }

    await AuthService.instance.setBiometricEnabled(enable);
    setState(() => _biometric = enable);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Desbloqueo biométrico habilitado.'
                : 'Desbloqueo biométrico deshabilitado.',
          ),
          backgroundColor: enable ? AppColors.primary : AppColors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showServerConfigDialog() async {
    final urlController = TextEditingController(
      text: EnvironmentConfig.instance.baseUrl,
    );
    var selectedMode = EnvironmentConfig.instance.mode;
    var selectedSim = EnvironmentConfig.instance.simulatedState;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Entorno y Origen de Datos',
                style: ts(18, AppColors.navy, weight: bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo de Datos', style: ts(12, AppColors.grey, weight: semi)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<DataSourceMode>(
                      initialValue: selectedMode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: DataSourceMode.mock,
                          child: Text('Mock local (Sin backend activo)'),
                        ),
                        DropdownMenuItem(
                          value: DataSourceMode.api,
                          child: Text('API REST Spring Boot'),
                        ),
                        DropdownMenuItem(
                          value: DataSourceMode.hybrid,
                          child: Text('Híbrido (API con respaldo Mock)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedMode = v);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('URL Base Backend', style: ts(12, AppColors.grey, weight: semi)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlController,
                      style: ts(13, AppColors.navy),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bg,
                        hintText: 'http://10.0.2.2:8080',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Simulación Visual (QA / Auditoría)', style: ts(12, AppColors.grey, weight: semi)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<SimulatedVisualState>(
                      initialValue: selectedSim,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SimulatedVisualState.none,
                          child: Text('Normal (Sin simulación)'),
                        ),
                        DropdownMenuItem(
                          value: SimulatedVisualState.loading,
                          child: Text('Cargando (Skeleton)'),
                        ),
                        DropdownMenuItem(
                          value: SimulatedVisualState.error,
                          child: Text('Error visual'),
                        ),
                        DropdownMenuItem(
                          value: SimulatedVisualState.empty,
                          child: Text('Estado Vacío'),
                        ),
                        DropdownMenuItem(
                          value: SimulatedVisualState.offline,
                          child: Text('Sin conexión (Offline)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedSim = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: ts(14, AppColors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await EnvironmentConfig.instance.setMode(selectedMode);
                    await EnvironmentConfig.instance.setBaseUrl(urlController.text.trim());
                    EnvironmentConfig.instance.setSimulatedState(selectedSim);
                    if (dialogCtx.mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                      KitchenDataService.instance.refreshAll();
                    }
                  },
                  child: Text('Guardar', style: ts(14, Colors.white, weight: semi)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await AuthService.instance.logout();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Perfil',
            subtitle: '$_displayName · $_displayRestaurant',
            subtitleSize: 13,
            showBell: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _initials,
                            style: ts(18, AppColors.primary, weight: bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _displayName,
                                      style: ts(18, AppColors.text, height: 1.4),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _displayRole,
                                      style: ts(11, AppColors.primary, weight: bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayEmail,
                                style: ts(13, AppColors.grey, height: 1.4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayRestaurant,
                                style: ts(13, AppColors.grey, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          size: 24,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Autenticación biométrica',
                                style: ts(14, AppColors.text, height: 1.4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _biometric
                                    ? 'Activada en este teléfono'
                                    : 'Desactivada en este teléfono',
                                style: ts(
                                  13,
                                  _biometric
                                      ? AppColors.primary
                                      : AppColors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSwitch(
                          value: _biometric,
                          onChanged: _toggleBiometrics,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: EnvironmentConfig.instance,
                    builder: (context, _) {
                      final env = EnvironmentConfig.instance;
                      final modeLabel = switch (env.mode) {
                        DataSourceMode.mock => 'Mock local (Sin backend activo)',
                        DataSourceMode.api => 'API REST Spring Boot',
                        DataSourceMode.hybrid => 'Híbrido (API con Mock fallback)',
                      };
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Entorno y Origen de Datos',
                                    style: ts(14, AppColors.text, weight: bold),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showServerConfigDialog,
                                  child: Text(
                                    'Configurar',
                                    style: ts(12, AppColors.primary, weight: semi),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Modo activo:', style: ts(13, AppColors.grey)),
                                Text(
                                  modeLabel,
                                  style: ts(13, AppColors.navy, weight: semi),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Servidor base:', style: ts(13, AppColors.grey)),
                                Flexible(
                                  child: Text(
                                    env.baseUrl,
                                    overflow: TextOverflow.ellipsis,
                                    style: ts(12, AppColors.navy),
                                  ),
                                ),
                              ],
                            ),
                            if (env.simulatedState != SimulatedVisualState.none) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Simulación QA:', style: ts(13, AppColors.danger)),
                                  Text(
                                    env.simulatedState.name.toUpperCase(),
                                    style: ts(12, AppColors.danger, weight: bold),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await KitchenDataService.instance.refreshAll();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Datos sincronizados con éxito.'),
                                            backgroundColor: AppColors.primary,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.navy),
                                    label: Text('Sincronizar', style: ts(12, AppColors.navy)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await CacheService.instance.clear();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Caché local limpiada.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.grey),
                                    label: Text('Limpiar caché', style: ts(12, AppColors.grey)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de sesión',
                          style: ts(14, AppColors.text, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bloqueo al volver a la app',
                                style: ts(13, AppColors.text, height: 1.4),
                              ),
                            ),
                            Text('Activado', style: ts(13, AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tiempo de inactividad',
                                style: ts(13, AppColors.text, height: 1.4),
                              ),
                            ),
                            Text('15 min ▾', style: ts(13, AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.navy,
                      ),
                      label: Text(
                        'Cerrar sesión',
                        style: ts(14, AppColors.navy, weight: semi),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sr. Kitchen Mobile · Versión ${DemoData.appVersion}',
                    textAlign: TextAlign.center,
                    style: ts(11, AppColors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}