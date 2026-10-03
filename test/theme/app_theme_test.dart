// Tema token'ları, tipografi ve tema fabrikası birim testleri.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/theme/app_colors.dart';
import 'package:vakit/theme/app_spacing.dart';
import 'package:vakit/theme/app_theme.dart';
import 'package:vakit/theme/app_typography.dart';

void main() {
  group('AppColors', () {
    test('seed rengi petrol yeşili yer tutucu değere eşittir', () {
      expect(AppColors.seed, equals(const Color(0xFF00695C)));
    });

    test('light ve dark şemaları doğru parlaklığa sahiptir', () {
      expect(AppColors.light().brightness, equals(Brightness.light));
      expect(AppColors.dark().brightness, equals(Brightness.dark));
    });
  });

  group('AppSpacing', () {
    test('bütün boşluk sabitleri 4 dp ızgarasının katlarıdır', () {
      const spacings = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];

      for (final s in spacings) {
        expect(s % 4, equals(0));
      }

      expect(AppSpacing.xs, equals(4));
      expect(AppSpacing.sm, equals(8));
      expect(AppSpacing.md, equals(12));
      expect(AppSpacing.lg, equals(16));
      expect(AppSpacing.xl, equals(24));
      expect(AppSpacing.xxl, equals(32));
    });

    test('bütün köşe yarıçapı sabitleri 4 dp ızgarasının katlarıdır', () {
      const radii = [
        AppSpacing.radiusSm,
        AppSpacing.radiusMd,
        AppSpacing.radiusLg,
        AppSpacing.radiusXl,
      ];

      for (final r in radii) {
        expect(r % 4, equals(0));
      }

      expect(AppSpacing.radiusSm, equals(8));
      expect(AppSpacing.radiusMd, equals(12));
      expect(AppSpacing.radiusLg, equals(16));
      expect(AppSpacing.radiusXl, equals(24));
    });
  });

  group('AppTypography', () {
    test('countdown stili tabularFigures font özelliğine sahiptir', () {
      const base = TextTheme(displayMedium: TextStyle(fontSize: 48));
      final style = AppTypography.countdown(base);

      expect(style.fontSize, equals(48));
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('displayMedium null olduğunda da tabularFigures eklenir', () {
      const base = TextTheme();
      final style = AppTypography.countdown(base);

      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('AppTheme', () {
    test('light tema useMaterial3 ve açık renk şeması kullanır', () {
      final theme = AppTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.brightness, equals(Brightness.light));
    });

    test('dark tema useMaterial3 ve koyu renk şeması kullanır', () {
      final theme = AppTheme.dark();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });
  });
}
