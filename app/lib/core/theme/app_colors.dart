import 'package:flutter/material.dart';

abstract final class AppColors {
  // Deep green-black base (tinted toward the logo green)
  static const black = Color(0xFF0A0E0B);
  static const surface = Color(0xFF141B16);
  static const surfaceLight = Color(0xFF1F2922);
  static const card = Color(0xFF1A231D);
  static const border = Color(0xFF2E3B32);
  static const borderStrong = Color(0xFF3E4D42);

  // Green-tinted off-whites and greys
  static const white = Color(0xFFEDF3EC);
  static const muted = Color(0xFF8E9C90);
  static const faint = Color(0xFF5F6E63);

  // Logo green accent (#21BF5B family)
  static const accent = Color(0xFF2BD673);
  static const accentDeep = Color(0xFF16A34A);
  static const accentDim = Color(0xFF3E7C4F);

  // Muted semantic accents that sit well on the dark green palette
  static const green = Color(0xFF86B49A);
  static const orange = Color(0xFFD9A45B);
  static const red = Color(0xFFE0655F);

  /// Fresh green sheen used on primary surfaces (matches the app logo).
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43D17C), Color(0xFF128A44)],
  );

  /// Subtle surface gradient for cards and panels.
  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B2620), Color(0xFF141C17)],
  );

  /// Faint top-down ambience for the scaffold background.
  static const backdropGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E1511), Color(0xFF0A0E0B), Color(0xFF0A0E0B)],
    stops: [0.0, 0.35, 1.0],
  );
}
