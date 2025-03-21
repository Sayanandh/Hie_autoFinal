import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1976D2);
  static const primaryDark = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const accent = Color(0xFFFF4081);
  static const accentDark = Color(0xFFF50057);
  static const accentLight = Color(0xFFFF80AB);
  
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFB00020);
  
  static const onPrimary = Colors.white;
  static const onAccent = Colors.white;
  static const onBackground = Colors.black87;
  static const onSurface = Colors.black87;
  static const onError = Colors.white;
  
  static const divider = Color(0xFFBDBDBD);
  static const disabled = Color(0xFF9E9E9E);
  
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const info = Color(0xFF2196F3);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );
  
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );
} 