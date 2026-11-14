import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/app_models.dart';
import 'widgets/app_widgets.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/products_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/environment_config.dart';
import 'widgets/state_views.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentConfig.instance.init();
  await AuthService.instance.init();
  ConnectivityService.instance.start();
  // Vista de error amigable (en vez de la pantalla roja) si un widget falla.
  ErrorWidget.builder = (details) {
    FlutterError.presentError(details);
    return const Material(
      color: AppColors.bg,
      child: StateView.error(compact: true),
    );
  };
  runApp(const SrKitchenApp());
}

class SrKitchenApp extends StatelessWidget {
  const SrKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sr. Kitchen Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.bg,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>()!;

  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  static const tabHome = 0,
      tabSales = 1,
      tabInventory = 2,
      tabProducts = 3,
      tabProfile = 4;

  int _index = 0;
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void selectTab(int i) {
    if (i == _index) {
      _keys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  void pushOnTab(int i, Widget page) {
    setState(() => _index = i);
    _keys[i].currentState?.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _root(int i) => switch (i) {
    tabHome => const HomeScreen(),
    tabSales => const SalesScreen(),
    tabInventory => const InventoryScreen(),
    tabProducts => const ProductsScreen(),
    _ => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < 5; i++)
                    Navigator(
                      key: _keys[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => _root(i)),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(selected: _index, onTap: selectTab),
      ),
    );
  }
}
