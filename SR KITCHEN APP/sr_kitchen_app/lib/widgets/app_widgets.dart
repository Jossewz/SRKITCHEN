import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/kitchen_data_service.dart';

class ScreenScaffold extends StatelessWidget {
  final Widget child;
  const ScreenScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(bottom: false, child: child),
  );
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class AppBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.selected, required this.onTap});

  // Iconos Material como aproximación a los de Lucide del diseño.
  static const _items = [
    _NavItem('Inicio', Icons.home_outlined),
    _NavItem('Ventas', Icons.show_chart),
    _NavItem('Inventario', Icons.inventory_2_outlined),
    _NavItem('Productos', Icons.restaurant_outlined),
    _NavItem('Perfil', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 28,
                            decoration: BoxDecoration(
                              color: i == selected
                                  ? AppColors.primarySoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _items[i].icon,
                              size: 21,
                              color: i == selected
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _items[i].label,
                            style: ts(
                              10,
                              i == selected
                                  ? AppColors.primary
                                  : AppColors.grey,
                              weight: i == selected ? bold : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool showBell;
  final bool boldTitle;
  final double height;
  final double subtitleSize;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBell = false,
    this.boldTitle = false,
    this.height = 74,
    this.subtitleSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (onBack != null) ...[
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: boldTitle
                        ? ts(22, AppColors.navy, weight: bold, height: 1.3)
                        : ts(24, AppColors.navy, height: 1.4),
                  ),
                  SizedBox(height: boldTitle ? 2 : 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(subtitleSize, AppColors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            if (showBell)
              ListenableBuilder(
                listenable: KitchenDataService.instance,
                builder: (context, _) {
                  final inv = KitchenDataService.instance.resumenInventario;
                  final hasAlerts = inv.requiereAtencion;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAdminAlertsSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          if (hasAlerts)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAdminAlertsSheet(BuildContext context) {
    final svc = KitchenDataService.instance;
    final inv = svc.resumenInventario;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alertas operativas del restaurante',
                      style: ts(17, AppColors.navy, weight: bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen de supervisión · ${svc.origin.badgeLabel}',
                style: ts(12, AppColors.grey),
              ),
              const SizedBox(height: 12),
              if (inv.criticos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${inv.conteoCriticos} productos en stock CRÍTICO (≤ 5 uds): '
                          '${inv.criticos.take(3).map((e) => '${e.name} (${e.stock})').join(', ')}',
                          style: ts(12.5, AppColors.text, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              if (inv.bajos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${inv.conteoBajos} productos en stock BAJO (6–15 uds): '
                          '${inv.bajos.take(3).map((e) => '${e.name} (${e.stock})').join(', ')}',
                          style: ts(12.5, AppColors.text, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!inv.requiereAtencion)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Todo el inventario se encuentra en niveles normales.',
                          style: ts(13, AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07002244),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class PeriodFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;
  final double fontSize;

  const PeriodFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    this.height = 38,
    this.fontSize = 13,
  });

  static const labels = ['Hoy', 'Esta semana', 'Este mes'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: i == selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: ts(
                      fontSize,
                      i == selected ? Colors.white : AppColors.grey,
                      weight: semi,
                    ),
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  final TextStyle titleStyle;
  final TextStyle actionStyle;

  const SectionHeader({
    super.key,
    required this.title,
    required this.action,
    required this.onAction,
    required this.titleStyle,
    required this.actionStyle,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: titleStyle)),
      GestureDetector(
        onTap: onAction,
        behavior: HitTestBehavior.opaque,
        child: Text(action, style: actionStyle),
      ),
    ],
  );
}

/// Foto de producto. Carga `assets/images/products/<imageKey>.png` y, si no
/// existe, muestra un marcador (no se usan las URLs temporales de Figma).
class ProductPhoto extends StatelessWidget {
  final Product product;
  final double height;
  final double? width;
  final bool circle;
  final double radius;

  const ProductPhoto({
    super.key,
    required this.product,
    required this.height,
    this.width,
    this.circle = true,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant,
        color: AppColors.primary,
        size: height * 0.4,
      ),
    );
    return SizedBox(
      width: width ?? height,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(circle ? height / 2 : radius),
        child: Image.asset(
          'assets/images/products/${product.imageKey}.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => fallback,
        ),
      ),
    );
  }
}

/// Fila "N · foto · nombre / detalle · chevron" (Inicio, Ventas, Top 5).
class ProductRankRow extends StatelessWidget {
  final int rank;
  final Product product;
  final String subtitle;
  final double photoSize;
  final double rowHeight;
  final double numberSize;
  final double chevronSize;
  final TextStyle nameStyle;
  final VoidCallback onTap;

  const ProductRankRow({
    super.key,
    required this.rank,
    required this.product,
    required this.subtitle,
    required this.photoSize,
    required this.rowHeight,
    required this.numberSize,
    required this.chevronSize,
    required this.nameStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rank',
              style: ts(numberSize, AppColors.primary, weight: bold),
            ),
          ),
          const SizedBox(width: 10),
          ProductPhoto(product: product, height: photoSize),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: ts(12, AppColors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.chevron_right,
            size: chevronSize,
            color: AppColors.primary,
          ),
        ],
      ),
    ),
  );
}

InputDecoration appInputDecoration(
  String hint, {
  Widget? suffix,
  Color? hintColor,
}) {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: ts(14, hintColor ?? AppColors.grey, height: 1.4),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    border: b(AppColors.border),
    enabledBorder: b(AppColors.border),
    focusedBorder: b(AppColors.primary),
    errorBorder: b(AppColors.danger),
    focusedErrorBorder: b(AppColors.danger),
    errorStyle: ts(12, AppColors.danger),
  );
}

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 44,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? AppColors.toggle : const Color(0xFFD0D5DB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GRÁFICA DE LÍNEA (CustomPainter, sin paquetes)
// ─────────────────────────────────────────────────────────────────────────────

class ChartTick {
  final double value;
  final String label;
  const ChartTick(this.value, this.label);
}

class ChartLabel {
  final String text;

  /// Posición X en el diseño original (ancho de referencia 318 px).
  final double left;
  const ChartLabel(this.text, this.left);
}

class LineChartView extends StatelessWidget {
  final List<double> values;
  final double maxY;
  final double minY;
  final List<ChartTick> ticks;
  final List<ChartLabel> xLabels;
  final String? unit;
  final bool axes;
  final bool area;
  final double height;

  const LineChartView({
    super.key,
    required this.values,
    required this.maxY,
    this.minY = 0,
    this.ticks = const [],
    this.xLabels = const [],
    this.unit,
    this.axes = true,
    this.area = true,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: CustomPaint(
      painter: _LineChartPainter(
        values: values,
        maxY: maxY,
        minY: minY,
        ticks: ticks,
        xLabels: xLabels,
        unit: unit,
        axes: axes,
        area: area,
      ),
    ),
  );
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxY;
  final double minY;
  final List<ChartTick> ticks;
  final List<ChartLabel> xLabels;
  final String? unit;
  final bool axes;
  final bool area;

  _LineChartPainter({
    required this.values,
    required this.maxY,
    required this.minY,
    required this.ticks,
    required this.xLabels,
    required this.unit,
    required this.axes,
    required this.area,
  });

  void _text(
    Canvas c,
    String s,
    Offset at, {
    double size = 11,
    bool rightAlign = false,
    bool centerY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: ts(size, AppColors.grey)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = rightAlign ? at.dx - tp.width : at.dx;
    final dy = centerY ? at.dy - tp.height / 2 : at.dy;
    tp.paint(c, Offset(dx, dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final left = axes ? 42.0 : 2.0;
    final right = size.width - (axes ? 16.0 : 2.0);
    final top = axes ? 45.0 : 2.0;
    final bottom = axes ? 185.0 : size.height - 2.0;
    final plotH = bottom - top;
    final range = maxY - minY;

    double yOf(double v) => bottom - ((v - minY) / range) * plotH;

    if (axes) {
      final grid = Paint()
        ..color = AppColors.border
        ..strokeWidth = 1;
      for (final t in ticks) {
        final y = yOf(t.value);
        canvas.drawLine(Offset(left, y), Offset(right, y), grid);
        _text(canvas, t.label, Offset(36, y), rightAlign: true, centerY: true);
      }
      if (unit != null) _text(canvas, unit!, Offset.zero);
      for (final l in xLabels) {
        _text(canvas, l.text, Offset(l.left * size.width / 318, 201), size: 10);
      }
    }

    final dx = (right - left) / (values.length - 1);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(left + dx * i, yOf(values[i])),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    if (area) {
      final fill = Path.from(line)
        ..lineTo(pts.last.dx, bottom)
        ..lineTo(pts.first.dx, bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x2E00509E), Color(0x0000509E)],
          ).createShader(Rect.fromLTRB(left, top, right, bottom)),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => true;
}

const detailXLabels = [
  ChartLabel('28 sep', 21),
  ChartLabel('30 sep', 107.67),
  ChartLabel('2 oct', 194.34),
  ChartLabel('4 oct', 263),
];

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA: LOGIN  (frame "Principal / Inicio de sesión")
// ─────────────────────────────────────────────────────────────────────────────
