// Tipografi tasarım token'ları ve özel metin stilleri.

import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextStyle countdown(TextTheme base) {
    final style = base.displayMedium ?? const TextStyle();
    return style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
