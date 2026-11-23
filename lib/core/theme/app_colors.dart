import 'package:flutter/material.dart';

class AppColors {
  // --- BillJi brand palette (extracted from the logo) ---
  // Primary brand = orange from the "B"/"Ji"; secondary = navy from "Bill".
  static const Color brandOrange = Color(0xFFFE701A);
  static const Color brandOrangeDark = Color(0xFFE55806); // receipt-roll edge
  static const Color brandOrangeLight = Color(0xFFFF8A3D);
  static const Color brandNavy = Color(0xFF081F48);


  // NOTE: `primaryBlue` is the app's primary-accent identifier used across 25+
  // files. It now holds the BillJi brand orange (kept the name to avoid a risky
  // rename). `statusBlue` preserves the original blue used for ORDER-STATUS
  // indicators (running/dispatched) so staff-facing status colors don't change.
  static const Color primaryBlue = brandOrange;
  static const Color statusBlue = Color(0xFF0A5BFF);
  static const Color deepNavy = brandNavy;
  static const Color primaryGreen = Color(0xFF22D67B);
  static const Color softGreen = Color(0xFF7CF2C2);
  static const Color background = Color(0xFFF5F8FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFE5E7EB);
  static const Color errorRed = Color(0xFFEF4444);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkCard = Color(0xFF1E293B);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrange, brandOrangeDark],
  );

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
