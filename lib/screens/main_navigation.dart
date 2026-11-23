import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import 'dashboard/dashboard_screen.dart';
import 'reports/reports_screen.dart';
import 'menu/menu_management_screen.dart';
import 'kds/kds_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/global_order_alert.dart';
import '../providers/navigation_provider.dart';
import '../providers/reports_provider.dart';
import '../presentation/providers/auth_provider.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final bool isKdsEnabled = authProvider.isKdsEnabled;

    // Ensure tab is valid if KDS was just disabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navProvider.ensureValidTab(isKdsEnabled);
    });
    
    final List<Widget> screens = [
      const DashboardScreen(),
      const MenuManagementScreen(),
      if (isKdsEnabled) const KdsScreen(),
      ReportsScreen(key: navProvider.reportsKey),
      const SettingsScreen(),
    ];

    final int selectedIndex = navProvider.getSelectedIndex(isKdsEnabled);

    // Bottom tab bar works fine on phones and on a tablet held in
    // portrait, but on a landscape tablet the wide-and-short screen makes
    // a bottom bar feel cramped and wastes the extra horizontal space. In
    // that one case only, the same tabs are shown as a side rail instead.
    // Phones (always portrait-locked, see main.dart) and portrait tablets
    // are completely untouched — they still hit the exact same
    // `_buildBottomBar` code path as before.
    final bool useSideNav = Responsive.isTablet(context) && Responsive.isLandscape(context);

    return GlobalOrderAlert(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (navProvider.currentTab != NavTab.home) {
            navProvider.setTab(NavTab.home);
          } else {
            _showExitDialog(context);
          }
        },
        child: Scaffold(
          body: useSideNav
              ? Row(
                  children: [
                    _buildSideNav(context, navProvider, isKdsEnabled, selectedIndex),
                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: screens,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: selectedIndex,
                  children: screens,
                ),
          bottomNavigationBar: useSideNav ? null : _buildBottomBar(context, navProvider, isKdsEnabled, selectedIndex),
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context, NavigationProvider navProvider, bool isKdsEnabled, int selectedIndex) {
    return Container(
      width: 240.w,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: SafeArea(

        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
                child: Image.asset(
                  'assets/images/billji_wordmark.png',
                  height: 76.h,
                  fit: BoxFit.contain,
                  // Same asset used on the splash/login screens; this
                  // fallback just guards against a missing/renamed asset so
                  // the side nav still renders cleanly instead of crashing.
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_rounded, color: AppColors.primaryBlue, size: 32.sp),
                      SizedBox(height: 4.h),
                      Text(
                        'BillJi',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildSideNavItem(
                      context, navProvider, NavTab.home, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr(), selectedIndex == 0,
                    ),
                    SizedBox(height: 8.h),
                    _buildSideNavItem(
                      context,
                      navProvider,
                      NavTab.items,
                      Icons.inventory_2_outlined,
                      Icons.inventory_2_rounded,
                      'nav.items'.tr(),
                      selectedIndex == 1,
                    ),
                    if (isKdsEnabled) ...[
                      SizedBox(height: 8.h),
                      _buildSideNavItem(
                        context,
                        navProvider,
                        NavTab.kitchen,
                        Icons.soup_kitchen_outlined,
                        Icons.soup_kitchen_rounded,
                        'nav.kitchen'.tr(),
                        selectedIndex == 2,
                      ),
                    ],
                    SizedBox(height: 8.h),
                    _buildSideNavItem(
                      context,
                      navProvider,
                      NavTab.analytics,
                      Icons.analytics_outlined,
                      Icons.analytics_rounded,
                      'nav.analytics'.tr(),
                      selectedIndex == (isKdsEnabled ? 3 : 2),
                    ),
                    SizedBox(height: 8.h),
                    _buildSideNavItem(
                      context,
                      navProvider,
                      NavTab.settings,
                      Icons.settings_outlined,
                      Icons.settings_rounded,
                      'nav.settings'.tr(),
                      selectedIndex == (isKdsEnabled ? 4 : 3),
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

  Widget _buildSideNavItem(
    BuildContext context,
    NavigationProvider navProvider,
    NavTab tab,
    IconData icon,
    IconData activeIcon,
    String label,
    bool isSelected,
  ) {
    final bool isAnalytics = tab == NavTab.analytics;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          if (isAnalytics && navProvider.currentTab != tab) {
            Provider.of<ReportsProvider>(context, listen: false).resetVerification();
            navProvider.refreshReports();
          }
          navProvider.setTab(tab);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22.sp,
                color: isSelected ? Colors.white : AppColors.grey,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, NavigationProvider navProvider, bool isKdsEnabled, int selectedIndex) {
    return SafeArea(
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, navProvider, NavTab.home, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr(), selectedIndex == 0),
            _buildNavItem(context, navProvider, NavTab.items, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'nav.items'.tr(), selectedIndex == 1),
            if (isKdsEnabled)
              _buildNavItem(context, navProvider, NavTab.kitchen, Icons.soup_kitchen_outlined, Icons.soup_kitchen_rounded, 'nav.kitchen'.tr(), selectedIndex == 2),
            _buildNavItem(
              context, 
              navProvider, 
              NavTab.analytics, 
              Icons.analytics_outlined, 
              Icons.analytics_rounded, 
              'nav.analytics'.tr(), 
              selectedIndex == (isKdsEnabled ? 3 : 2)
            ),
            _buildNavItem(
              context, 
              navProvider, 
              NavTab.settings, 
              Icons.settings_outlined, 
              Icons.settings_rounded, 
              'nav.settings'.tr(), 
              selectedIndex == (isKdsEnabled ? 4 : 3)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavigationProvider navProvider, NavTab tab, IconData icon, IconData activeIcon, String label, bool isSelected) {
    final bool isAnalytics = tab == NavTab.analytics;

    return GestureDetector(
      onTap: () {
        if (isAnalytics && navProvider.currentTab != tab) {
          Provider.of<ReportsProvider>(context, listen: false).resetVerification();
          navProvider.refreshReports();
        }
        navProvider.setTab(tab);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 75.w,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected ? AppColors.primaryBlue : AppColors.grey.withValues(alpha: 0.5),
                    size: isSelected ? 28.sp : 24.sp,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.sp,
                  letterSpacing: 0.1,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryBlue : AppColors.grey.withValues(alpha: 0.6),
                  fontFamily: 'Roboto', // Use default or your theme font
                ),
                child: Text(label),
              ),
              SizedBox(height: 4.h),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSelected ? 20.w : 0,
                height: 3.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              if (!isSelected) SizedBox(height: 3.h), // Maintain layout height
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('login.exit_title'.tr()),
        content: Text('login.exit_message'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.no'.tr(), style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('common.yes'.tr(), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
