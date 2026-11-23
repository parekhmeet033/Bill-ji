import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/api_constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  void _startTimer() {
    // Changed duration from 2 hours to 3 seconds for a standard splash experience
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    final tokenBox = Hive.box(CacheConstants.tokenBox);
    final String? token = tokenBox.get(CacheConstants.authToken);

    Widget nextScreen = const LoginScreen();
    if (token != null && token.isNotEmpty) {
      nextScreen = const MainNavigation();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(microseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            // cover (not fill) preserves the image's aspect ratio so it isn't
            // stretched when the tablet is in landscape orientation.
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  AppColors.background.withOpacity(0.9),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 1200),
                  child: Pulse(
                    infinite: true,
                    duration: const Duration(seconds: 2),
                    child: Image.asset(
                      'assets/images/billji_wordmark.png',
                      height: 120.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
