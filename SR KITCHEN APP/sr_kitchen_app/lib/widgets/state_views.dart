import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/connectivity_service.dart';
import '../services/kitchen_data_service.dart';
import 'motion.dart';

enum StateKind { empty, offline, error, notFound }

/// Vista a pantalla/tarjeta completa para estados vacíos y de error.
class StateView extends StatelessWidget {
  final StateKind kind;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const StateView({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  const StateView.empty({
    super.key,
    this.title = 'Sin datos para mostrar',
    this.message = 'No hay información en el período o filtro seleccionado.',
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : kind = StateKind.empty;

  const StateView.offline({
    super.key,
    this.title = 'Sin conexión a Internet',
    this.message =
        'Revisa tu red e inténtalo de nuevo. Los datos locales siguen disponibles.',
    this.actionLabel = 'Reintentar',
    this.onAction,
    this.compact = false,
  }) : kind = StateKind.offline;

  const StateView.error({
    super.key,
    this.title = 'Algo salió mal',
    this.message =
        'No pudimos mostrar esta información. Inténtalo de nuevo.',
    this.actionLabel = 'Reintentar',
    this.onAction,
    this.compact = false,
  }) : kind = StateKind.error;

  const StateView.notFound({
    super.key,
    this.title = 'No encontramos lo que buscas',
    this.message = 'El elemento no existe o ya no está disponible.',
    this.actionLabel = 'Volver',
    this.onAction,
    this.compact = false,
  }) : kind = StateKind.notFound;

  IconData get _icon => switch (kind) {
    StateKind.empty => Icons.bar_chart_rounded,
    StateKind.offline => Icons.wifi_off_rounded,
    StateKind.error => Icons.error_outline_rounded,
    StateKind.notFound => Icons.search_off_rounded,
  };

  Color get _color => switch (kind) {
    StateKind.empty => AppColors.primary,
    StateKind.offline => AppColors.warning,
    StateKind.error => AppColors.danger,
    StateKind.notFound => AppColors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 64.0;
    return Semantics(
      container: true,
      label: '${title ?? ''}. ${message ?? ''}',
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: compact ? 16 : 40,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, s, child) => Opacity(
              opacity: s.clamp(0, 1),
              child: Transform.scale(scale: s, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size + 20,
                  height: size + 20,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: size * 0.55, color: _color),
                ),
                SizedBox(height: compact ? 10 : 16),
                Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: ts(
                    compact ? 14 : 17,
                    AppColors.navy,
                    weight: semi,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message ?? '',
                  textAlign: TextAlign.center,
                  style: ts(13, AppColors.grey, height: 1.4),
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: Icon(
                      kind == StateKind.notFound
                          ? Icons.arrow_back
                          : Icons.refresh,
                      size: 18,
                    ),
                    label: Text(actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(140, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso animado que aparece cuando se pierde la conexión a internet.
/// Informa cuándo se obtuvieron los últimos datos almacenados en caché local.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = ConnectivityService.instance;
    final dataSvc = KitchenDataService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([conn.online, dataSvc]),
      builder: (context, _) {
        final isOffline =
            !conn.online.value || dataSvc.origin == DataOrigin.localCache;
        return AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !isOffline
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: const Color(0xFFFFF4E0),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Estás consultando información almacenada localmente. '
                              'Última actualización: ${dataSvc.relativeAgeLabel}. '
                              'Los datos pueden no reflejar el estado actual del restaurante.',
                              style: ts(11.5, AppColors.text, height: 1.3),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (conn.simulatedOffline) {
                                conn.setSimulatedOffline(false);
                              }
                              await conn.check();
                              await dataSvc.refreshAll();
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 36),
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(
                              'Reintentar',
                              style: ts(12, AppColors.primary, weight: semi),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Barra de estado de sincronización y origen de datos (API Real vs Modo Demo vs Caché Offline).
class SyncStatusBanner extends StatelessWidget {
  final VoidCallback? onRefresh;
  const SyncStatusBanner({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final svc = KitchenDataService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final origin = svc.origin;
        final (bgColor, borderColor, textColor, icon) = switch (origin) {
          DataOrigin.liveApi => (
            const Color(0xFFEAF7EE),
            AppColors.success.withValues(alpha: 0.35),
            AppColors.success,
            Icons.cloud_done_outlined,
          ),
          DataOrigin.mockDemo => (
            AppColors.primarySoft,
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primary,
            Icons.science_outlined,
          ),
          DataOrigin.localCache => (
            const Color(0xFFFFF4E0),
            AppColors.warning.withValues(alpha: 0.45),
            const Color(0xFFB9770E),
            Icons.inventory_2_outlined,
          ),
        };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  origin.badgeLabel,
                  style: ts(9.5, textColor, weight: bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sincr.: ${svc.lastUpdatedTimeLabel} (${svc.relativeAgeLabel})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11, AppColors.grey),
                ),
              ),
              if (onRefresh != null)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: svc.isSyncing ? null : onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: svc.isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Vista de carga mediante Skeletons animados para evitar pantallas vacías o bruscas.
class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Skeleton(height: 36, radius: 10),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Skeleton(height: 88, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: Skeleton(height: 88, radius: 14)),
          ],
        ),
        SizedBox(height: 12),
        Skeleton(height: 240, radius: 16),
        SizedBox(height: 12),
        Skeleton(height: 140, radius: 16),
      ],
    );
  }
}
