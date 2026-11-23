import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/localization/locale_service.dart';
import 'package:lineless/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lineless/core/services/printer_service.dart';
import 'package:lineless/core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection.dart' as di;
import 'presentation/providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/table_provider.dart';
import 'providers/table_order_provider.dart';
import 'providers/table_order_view_provider.dart';
import 'providers/login_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/menu_management_provider.dart';
import 'providers/add_menu_item_provider.dart';
import 'providers/orders_list_provider.dart';
import 'providers/order_details_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/item_analysis_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/tables_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/global_alert_provider.dart';
import 'providers/kds_provider.dart';
import 'splash_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message: ${message.messageId}");
}

/// Shared device-class check used for both:
///  (a) picking ScreenUtil's design size (see `MyApp._designSizeForDevice`)
///  (b) deciding whether to allow landscape orientation (see `main()`)
/// Phones are unaffected either way — only tablets get different values.
bool _isTabletDevice() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final logicalSize = view.physicalSize / view.devicePixelRatio;
  const double tabletBreakpoint = 600; // Material's standard tablet cutoff
  return logicalSize.shortestSide >= tabletBreakpoint;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final Locale startLocale = await LocaleService.loadStartLocale();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  await di.init();
  await PrinterService().init();

  // Landscape is only useful on tablets — phones keep the original
  // portrait-only lock exactly as before (zero behavior change on phone).
  final bool isTablet = _isTabletDevice();
  await SystemChrome.setPreferredOrientations(
    isTablet
        ? const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  runApp(
    EasyLocalization(
      supportedLocales: LocaleService.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: LocaleService.fallbackLocale,
      startLocale: startLocale,
      child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(di.sl(), di.sl(), di.sl(), getShopSettingsUseCase: di.sl(), updateShopSettingsUseCase: di.sl()),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            getOrdersUseCase: di.sl(),
            getDashboardUseCase: di.sl(),
            getOrdersListUseCase: di.sl(),
            getPendingTablesUseCase: di.sl(),
            getReportsAnalyticsUseCase: di.sl(),
            updateOrderStatusUseCase: di.sl(),
            deleteOrdersUseCase: di.sl(),
            forgotPinUseCase: di.sl(),
            authLocalDataSource: di.sl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MenuProvider(
            getMenuUseCase: di.sl(),
            getCategoryUseCase: di.sl(),
            addCategoryUseCase: di.sl(),
            updateCategoryUseCase: di.sl(),
            deleteCategoryUseCase: di.sl(),
            reorderCategoriesUseCase: di.sl(),
            reorderMenuUseCase: di.sl(),
            addMenuItemUseCase: di.sl(),
            updateMenuItemUseCase: di.sl(),
            updateMenuStatusUseCase: di.sl(),
            deleteMenuUseCase: di.sl(),
            getTableProductListUseCase: di.sl(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => TableOrderProvider(saveTableOrderUseCase: di.sl(), createPosOrderUseCase: di.sl(), getPosDraftUseCase: di.sl(), savePosDraftUseCase: di.sl(), clearPosDraftUseCase: di.sl())),
        ChangeNotifierProvider(create: (_) => TableOrderViewProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MenuManagementProvider()),
        ChangeNotifierProvider(create: (_) => AddMenuItemProvider()),
        ChangeNotifierProvider(create: (_) => OrdersListProvider()),
        ChangeNotifierProvider(create: (_) => OrderDetailsProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
        ChangeNotifierProvider(create: (_) => TablesProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => GlobalAlertProvider()),
        ChangeNotifierProvider(create: (_) => ItemAnalysisProvider()),
        ChangeNotifierProxyProvider<OrderProvider, KdsProvider>(
          create: (_) => KdsProvider(),
          update: (_, orderProvider, kdsProvider) {
            return kdsProvider!..updateKds(orderProvider.orders);
          },
        ),
      ],
      child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Picks the ScreenUtil "design size" (reference resolution) based on the
  /// physical device AND its current orientation.
  ///
  /// ScreenUtil computes two *independent* scale factors:
  ///   scaleWidth  = actualScreenWidth  / designSize.width
  ///   scaleHeight = actualScreenHeight / designSize.height
  /// `.w` (and any padding/margin written as `.w`, including when it's
  /// applied vertically via `.all()`/`.symmetric()`) is scaled by
  /// scaleWidth; `.h` is scaled by scaleHeight.
  ///
  /// The bug: this design size was always (800, 1280) — a *portrait*
  /// reference — for tablets, even while the tablet is physically in
  /// landscape. On a landscape tablet the real screen is roughly
  /// (1280, 800), so against the un-rotated design size:
  ///   scaleWidth  = 1280 / 800  = 1.6
  ///   scaleHeight = 800  / 1280 = 0.625
  /// Those two factors are wildly different (2.5x apart) instead of
  /// close to 1:1. Any spot that uses `.w` for vertical spacing (a very
  /// common ScreenUtil idiom — e.g. `EdgeInsets.all(12.w)`) then renders
  /// far taller than the `.h`-scaled container around it was ever going
  /// to allow, which is exactly what produced the "BOTTOM OVERFLOWED BY
  /// N PIXELS" errors seen in landscape (dashboard header, menu cards,
  /// KDS cards, reports rows, etc).
  ///
  /// The fix: swap the design size's width/height for tablets whenever
  /// the device is currently in landscape, so the reference aspect ratio
  /// always matches the device's current aspect ratio and both scale
  /// factors stay close to 1:1 in either orientation.
  ///
  /// Phones keep the original 375x812 portrait-only reference untouched
  /// (they're locked to portrait in `main()` below, so this orientation
  /// branch never even applies to them — zero behavior change).
  static Size _designSizeForDevice(BuildContext context) {
    if (_isTabletDevice()) {
      final bool isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
      // Reference close to a common 10" tablet's logical resolution.
      // Tune this if your target tablets are notably bigger/smaller —
      // raising it shrinks UI further, lowering it grows UI further.
      return isLandscape ? const Size(1280, 800) : const Size(800, 1280);
    }
    return const Size(375, 812);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Reading MediaQuery.orientationOf(context) above makes this widget
      // depend on orientation, so `build` (and therefore this designSize)
      // is automatically recomputed whenever the tablet is rotated.
      designSize: _designSizeForDevice(context),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'BillJi Shop Owner',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: const SplashScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
