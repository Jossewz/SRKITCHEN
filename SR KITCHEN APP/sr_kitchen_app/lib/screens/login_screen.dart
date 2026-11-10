import 'package:flutter/material.dart';

import '../main.dart';
import '../models/app_models.dart';
import '../services/app_exception.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/environment_config.dart';
import '../services/kitchen_data_service.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  AppException? _authError;

  @override
  void initState() {
    super.initState();
    AuthService.instance.init();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateUser(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu correo o usuario';
    if (value.contains('@') &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePass(String? v) =>
      (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      await AuthService.instance.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;

      // Precargar datos del restaurante tras autenticar
      unawaited(KitchenDataService.instance.refreshAll());

      // Paso 6 del flujo biométrico: ofrecer habilitar huella si el dispositivo
      // es compatible y aún no está activada.
      if (!AuthService.instance.biometricEnabled) {
        final availability = await BiometricService.instance
            .checkAvailability();
        if (mounted && availability.isReady) {
          await _promptEnableBiometrics();
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _authError = e);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _authError = const AppException(
          kind: AppErrorKind.unknown,
          title: 'Error de autenticación',
          userMessage: 'No fue posible iniciar sesión. Inténtalo de nuevo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promptEnableBiometrics() async {
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Habilitar huella digital'),
        content: const Text(
          '¿Deseas activar el desbloqueo biométrico para ingresar más rápido en tus próximas consultas administrativas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Activar huella'),
          ),
        ],
      ),
    );
    if (accept == true && mounted) {
      try {
        await AuthService.instance.setBiometricEnabled(true);
      } on AppException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    }
  }

  Future<void> _biometric() async {
    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      await AuthService.instance.unlockWithBiometrics();
      if (!mounted) return;
      unawaited(KitchenDataService.instance.refreshAll());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _authError = e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showServerConfigDialog() async {
    final cfg = EnvironmentConfig.instance;
    final urlCtrl = TextEditingController(text: cfg.baseUrl);
    var selectedMode = cfg.mode;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(
            'Conexión y Modo de Datos',
            style: ts(17, AppColors.navy, weight: bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuente de datos',
                  style: ts(12, AppColors.grey, weight: semi),
                ),
                const SizedBox(height: 6),
                RadioGroup<DataSourceMode>(
                  groupValue: selectedMode,
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedMode = val);
                  },
                  child: Column(
                    children: [
                      for (final m in DataSourceMode.values)
                        RadioListTile<DataSourceMode>(
                          value: m,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          title: Text(m.label, style: ts(13, AppColors.text)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'URL del Backend Spring Boot',
                  style: ts(12, AppColors.grey, weight: semi),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: urlCtrl,
                  decoration: appInputDecoration('http://10.0.2.2:8080'),
                  style: ts(13, AppColors.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'En emulador Android usa http://10.0.2.2:8080. En dispositivo físico usa la IP LAN de tu equipo (ej. http://192.168.1.15:8080).',
                  style: ts(11, AppColors.grey, height: 1.3),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await cfg.setMode(selectedMode);
                await cfg.setBaseUrl(urlCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: ts(13, AppColors.text, height: 1.4));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            AuthService.instance,
            EnvironmentConfig.instance,
          ]),
          builder: (context, _) {
            final auth = AuthService.instance;
            final cfg = EnvironmentConfig.instance;
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Barra superior de entorno y configuración
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Acceso Exclusivo ADMIN · ${cfg.mode.shortBadge}',
                                        style: ts(
                                          11,
                                          AppColors.primary,
                                          weight: semi,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _showServerConfigDialog,
                                  tooltip: 'Configurar servidor y modo',
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Marca
                            Center(
                              child: SizedBox(
                                width: 200,
                                height: 120,
                                child: Image.asset(
                                  'assets/images/logo_sr_kitchen.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) =>
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: AppColors.primarySoft,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Icon(
                                                Icons.restaurant_menu_rounded,
                                                size: 26,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Sr. Kitchen',
                                              style: ts(
                                                22,
                                                AppColors.primary,
                                                weight: bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tu restaurante, en un vistazo.',
                              textAlign: TextAlign.center,
                              style: ts(22, AppColors.navy, height: 1.4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ventas, productos e inventario.',
                              textAlign: TextAlign.center,
                              style: ts(14, AppColors.grey, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            if (_authError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _authError!.title,
                                            style: ts(
                                              13,
                                              AppColors.danger,
                                              weight: bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _authError!.userMessage,
                                            style: ts(
                                              12,
                                              AppColors.text,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            // Formulario
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _label('Correo o usuario'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _userCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    style: ts(14, AppColors.text, height: 1.4),
                                    decoration: appInputDecoration(
                                      'Escribe tu correo o usuario',
                                    ),
                                    validator: _validateUser,
                                  ),
                                  const SizedBox(height: 16),
                                  _label('Contraseña'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    style: ts(14, AppColors.text, height: 1.4),
                                    decoration: appInputDecoration(
                                      '••••••••••',
                                      suffix: IconButton(
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ),
                                    validator: _validatePass,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors
                                            .primary
                                            .withValues(alpha: 0.6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Iniciar sesión',
                                              style: ts(
                                                14,
                                                Colors.white,
                                                weight: semi,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _loading ? null : _biometric,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.fingerprint,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        auth.canUnlockWithBiometrics
                                            ? 'Desbloquear con huella (${auth.displayName})'
                                            : 'Ingresar con huella digital',
                                        style: ts(
                                          13.5,
                                          AppColors.primary,
                                          weight: semi,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Acceso rápido de autocompletado de credenciales autorizadas
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    children: [
                                      ActionChip(
                                        visualDensity: VisualDensity.compact,
                                        avatar: const Icon(
                                          Icons.verified_user_outlined,
                                          size: 15,
                                          color: AppColors.primary,
                                        ),
                                        label: Text(
                                          'Usar Admin Demo',
                                          style: ts(11.5, AppColors.primary),
                                        ),
                                        onPressed: () {
                                          _userCtrl.text =
                                              'admin@rskitchen.com';
                                          _passCtrl.text = 'admin123';
                                        },
                                      ),
                                      ActionChip(
                                        visualDensity: VisualDensity.compact,
                                        avatar: const Icon(
                                          Icons.block_outlined,
                                          size: 15,
                                          color: AppColors.danger,
                                        ),
                                        label: Text(
                                          'Probar Rol Mesero (Bloqueado)',
                                          style: ts(11.5, AppColors.danger),
                                        ),
                                        onPressed: () {
                                          _userCtrl.text =
                                              'mesero@rskitchen.com';
                                          _passCtrl.text = 'mesero123';
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Pie
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            '¿No puedes entrar? Contacta al administrador.',
                            textAlign: TextAlign.center,
                            style: ts(13, AppColors.grey, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
