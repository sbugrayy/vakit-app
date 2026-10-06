// SettingsCubit birim testleri.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/settings/cubit/settings_cubit.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/repository/settings_store.dart';

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockNotificationBridge extends Mock implements NotificationBridge {}

void main() {
  setUpAll(() => registerFallbackValue(const AppSettings()));

  late _MockSettingsStore store;
  late _MockNotificationBridge notificationBridge;

  setUp(() {
    store = _MockSettingsStore();
    notificationBridge = _MockNotificationBridge();

    when(
      () => notificationBridge.setEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
  });

  group('SettingsCubit', () {
    test('başlangıç durumu varsayılan ayarlardır', () {
      final cubit = SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      );

      expect(cubit.state, equals(const AppSettings()));
      expect(cubit.state.themePreference, equals(ThemePreference.system));
      expect(cubit.state.notificationEnabled, isTrue);
    });

    blocTest<SettingsCubit, AppSettings>(
      'load kayıtlı değeri yayar',
      setUp: () {
        when(() => store.load()).thenAnswer(
          (_) async => const AppSettings(
            themePreference: ThemePreference.dark,
            notificationEnabled: false,
          ),
        );
      },
      build: () => SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      ),
      act: (cubit) => cubit.load(),
      expect: () => const [
        AppSettings(
          themePreference: ThemePreference.dark,
          notificationEnabled: false,
        ),
      ],
    );

    blocTest<SettingsCubit, AppSettings>(
      'setThemePreference tercihi kaydeder ve yayar',
      setUp: () {
        when(() => store.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      ),
      act: (cubit) => cubit.setThemePreference(ThemePreference.light),
      expect: () => const [
        AppSettings(themePreference: ThemePreference.light),
      ],
      verify: (_) {
        verify(
          () => store.save(
            const AppSettings(themePreference: ThemePreference.light),
          ),
        ).called(1);
        verifyZeroInteractions(notificationBridge);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setNotificationEnabled(false) kaydeder, yayar ve köprüyü çağırır',
      setUp: () {
        when(() => store.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      ),
      act: (cubit) => cubit.setNotificationEnabled(enabled: false),
      expect: () => const [
        AppSettings(notificationEnabled: false),
      ],
      verify: (_) {
        verify(
          () => store.save(const AppSettings(notificationEnabled: false)),
        ).called(1);
        verify(
          () => notificationBridge.setEnabled(enabled: false),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'köprü PlatformException fırlatsa bile tercih kaydedilir ve yayılır',
      setUp: () {
        when(() => store.save(any())).thenAnswer((_) async {});
        when(
          () => notificationBridge.setEnabled(enabled: any(named: 'enabled')),
        ).thenThrow(PlatformException(code: 'UNAVAILABLE'));
      },
      build: () => SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      ),
      act: (cubit) => cubit.setNotificationEnabled(enabled: false),
      expect: () => const [
        AppSettings(notificationEnabled: false),
      ],
      verify: (_) {
        verify(
          () => store.save(const AppSettings(notificationEnabled: false)),
        ).called(1);
        verify(
          () => notificationBridge.setEnabled(enabled: false),
        ).called(1);
      },
    );

    test('isClosed iken load emit etmez', () async {
      when(() => store.load()).thenAnswer((_) async {
        return const AppSettings(themePreference: ThemePreference.dark);
      });

      final cubit = SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      );
      await cubit.close();

      await cubit.load();
      expect(cubit.isClosed, isTrue);
      expect(cubit.state, equals(const AppSettings()));
      verify(() => store.load()).called(1);
    });

    test('isClosed iken setThemePreference emit etmez', () async {
      when(() => store.save(any())).thenAnswer((_) async {});

      final cubit = SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      );
      await cubit.close();

      await cubit.setThemePreference(ThemePreference.dark);
      expect(cubit.isClosed, isTrue);
      expect(cubit.state, equals(const AppSettings()));
      verify(
        () => store.save(
          const AppSettings(themePreference: ThemePreference.dark),
        ),
      ).called(1);
    });

    test('isClosed iken setNotificationEnabled emit etmez', () async {
      when(() => store.save(any())).thenAnswer((_) async {});

      final cubit = SettingsCubit(
        store: store,
        notificationBridge: notificationBridge,
      );
      await cubit.close();

      await cubit.setNotificationEnabled(enabled: false);
      expect(cubit.isClosed, isTrue);
      expect(cubit.state, equals(const AppSettings()));
      verify(
        () => store.save(const AppSettings(notificationEnabled: false)),
      ).called(1);
      verifyZeroInteractions(notificationBridge);
    });
  });
}
