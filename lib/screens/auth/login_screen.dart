import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/resource.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/language_selector.dart';
import '../main_navigation.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../providers/login_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/utils/custom_snackbar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogin(BuildContext context, LoginProvider loginProvider) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.login(loginProvider.emailController.text.trim(), loginProvider.passwordController.text.trim());

    if (context.mounted) {
      final resource = authProvider.loginResource;
      if (resource is Success) {
        Provider.of<NavigationProvider>(context, listen: false).reset();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } else if (resource is Error) {
        CustomSnackbar.show(context, message: resource.failure?.message ?? 'login.login_failed'.tr());
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final loginProvider = context.watch<LoginProvider>();
    final isLoading = authProvider.loginResource is Loading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Center(
              child: ConstrainedBox(
                // Keep the form a comfortable width; it fills the screen on
                // phones but stays a centred column on tablets / large screens.
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              SizedBox(height: 40.h),
              Align(
                alignment: Alignment.centerRight,
                child: const LanguagePill(),
              ),
              SizedBox(height: 44.h),
              FadeIn(
                duration: const Duration(milliseconds: 1000),
                child: Center(
                  child: Image.asset(
                    'assets/images/billji_wordmark.png',
                    height: 120.h,
                  ),
                ),
              ),
              20.verticalSpace,
              FadeIn(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'login.email'.tr(),
                      hint: 'login.email_hint'.tr(),
                      prefixIcon: Icons.email_outlined,
                      controller: loginProvider.emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 24.h),
                    CustomTextField(
                      label: 'login.password'.tr(),
                      hint: 'login.password_hint'.tr(),
                      prefixIcon: Icons.lock_outline,
                      isPassword: loginProvider.isObscure,
                      controller: loginProvider.passwordController,
                      suffixIcon: IconButton(
                        icon: Icon(
                          loginProvider.isObscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.grey,
                          size: 20.sp,
                        ),
                        onPressed: () => loginProvider.toggleVisibility(),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    PrimaryButton(
                      label: 'login.login'.tr(),
                      isLoading: isLoading,
                      onPressed: () => _handleLogin(context, loginProvider),
                      gradient: AppColors.primaryGradient,
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
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
            child: Text('common.no'.tr(), style: const TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              'common.yes'.tr(),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
