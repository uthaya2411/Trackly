import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Dark Theme Colors (AMOLED Premium)
  static const Color darkBackground = Color(0xFF050609);
  static const Color darkSurface = Color(0xFF0F111A);
  static const Color darkCard = Color(0xFF161926);
  static const Color darkBorder = Color(0xFF23273C);

  // Light Theme Colors (Premium Slate)
  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Brand Accents
  static const Color primary = Color(0xFF7C3AED); // Deep Indigo
  static const Color secondary = Color(0xFF06B6D4); // Cyber Cyan
  static const Color accent = Color(0xFFEC4899); // Electric Rose

  // Semantic Financial Colors
  static const Color income = Color(0xFF10B981); // Neon Emerald Mint
  static const Color expense = Color(0xFFEF4444); // Vibrant Coral Red
  static const Color savings = Color(0xFF06B6D4); // Bright Cyan
  static const Color goal = Color(0xFFF59E0B); // Amber Yellow

  // Category Semantic Colors (Premium Neon Chips)
  static const Color categoryFood = Color(0xFFFF4E7B); // Rose Pink
  static const Color categoryTravel = Color(0xFF00E5FF); // Electric Cyan
  static const Color categoryBills = Color(0xFF8B5CF6); // Cyber Purple
  static const Color categoryShopping = Color(0xFFFFB300); // Amber Yellow
  static const Color categorySalary = Color(0xFF00E676); // Spring Green
  static const Color categoryInvestment = Color(0xFFEC4899); // Electric Rose

  // Glassmorphic Helper Colors
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassBlack(double opacity) => Colors.black.withOpacity(opacity);

  // Gradients for Cards and Buttons
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Purple to Rose
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)], // Cyan to Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)], // Deep Green to Mint
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF43F5E)], // Crimson to Rose
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background ambient glow gradient
  static const RadialGradient ambientGlow = RadialGradient(
    colors: [Color(0x1F7C3AED), Colors.transparent],
    radius: 1.2,
    center: Alignment(0.6, -0.5),
  );
}
