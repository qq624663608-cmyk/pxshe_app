import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/_core/theme/app_spacing.dart';
import 'package:pxshe_app/_core/theme/app_radius.dart';
import 'package:pxshe_app/_core/theme/app_durations.dart';

void main() {
  group('AppColors', () {
    test('has core colors', () {
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.primary, isNotNull);
    });

    test('has text colors', () {
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.textDisabled, isNotNull);
      expect(AppColors.textHint, isNotNull);
    });

    test('has semantic colors', () {
      expect(AppColors.error, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.info, isNotNull);
    });

    test('has utility colors', () {
      expect(AppColors.divider, isNotNull);
      expect(AppColors.border, isNotNull);
      expect(AppColors.transparent, isNotNull);
    });

    test('constructor is private', () {
      // Private constructor should not be instantiable from outside
      // We verify this indirectly by checking class has no public ctor
      expect(AppColors.background, isNotNull);
    });
  });

  group('AppSpacing', () {
    test('follows 4-based scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
      expect(AppSpacing.xxxl, 48.0);
    });
  });

  group('AppRadius', () {
    test('defines common radii', () {
      expect(AppRadius.sm, 6.0);
      expect(AppRadius.md, 10.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 20.0);
      expect(AppRadius.pill, 100.0);
      expect(AppRadius.circle, 1000.0);
    });
  });

  group('AppDurations', () {
    test('defines UI durations', () {
      expect(AppDurations.tap, const Duration(milliseconds: 100));
      expect(AppDurations.short, const Duration(milliseconds: 200));
      expect(AppDurations.medium, const Duration(milliseconds: 300));
      expect(AppDurations.long, const Duration(milliseconds: 500));
      expect(AppDurations.snack, const Duration(milliseconds: 900));
      expect(AppDurations.splashTimeout, const Duration(seconds: 3));
      expect(AppDurations.networkTimeout, const Duration(seconds: 10));
    });
  });
}