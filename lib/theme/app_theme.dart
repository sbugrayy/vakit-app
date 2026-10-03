// Açık ve koyu tema yapılandırmalarını sağlayan tema fabrikası.

import 'package:flutter/material.dart';
import 'package:vakit/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.light(),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.dark(),
    );
  }
}
