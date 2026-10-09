// GEÇİCİ: Faz 1'de Stitch DESIGN.md token'larıyla değişecek.

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color seed = Color(0xFF00695C);

  static ColorScheme light() {
    return ColorScheme.fromSeed(seedColor: seed);
  }

  static ColorScheme dark() {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
  }
}
