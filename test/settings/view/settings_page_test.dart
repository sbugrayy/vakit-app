// SettingsPage ve ayarlar görünümü widget testleri.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/settings/cubit/settings_cubit.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/settings/view/settings_page.dart';
import 'package:vakit/theme/app_theme.dart';

import '../../helpers/in_memory_store.dart';

class _MockSettingsCubit extends MockCubit<AppSettings>
    implements SettingsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(ThemePreference.system);
    registerFallbackValue(const AppSettings());
  });

  const sampleLocation = SelectedLocation(
    cityId: '10',
    cityName: 'Balıkesir',
    districtId: '1182',
    districtName: 'Bigadiç',
    latitude: 39.4,
    longitude: 28.13,
  );

  late InMemoryStore inMemoryStore;
  late LocationStore locationStore;
  late _MockSettingsCubit mockCubit;

  setUp(() {
    inMemoryStore = InMemoryStore();
    locationStore = LocationStore(inMemoryStore);
    mockCubit = _MockSettingsCubit();

    when(
      () => mockCubit.setNotificationEnabled(
        enabled: any(named: 'enabled'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockCubit.setThemePreference(any()),
    ).thenAnswer((_) async {});
  });

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildSubject({
    required AppSettings state,
    Brightness brightness = Brightness.light,
    GoRouter? router,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationStore>.value(value: locationStore),
      ],
      child: BlocProvider<SettingsCubit>.value(
        value: mockCubit,
        child: router != null
            ? MaterialApp.router(
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                routerConfig: router,
              )
            : MaterialApp(
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const SettingsPage(),
              ),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets(
      'açık ve koyu temada dört bölüm başlığı ve metinler görünür, '
      'konum alt metni Bigadiç, Balıkesir',
      (tester) async {
        configure360dp(tester);

        await locationStore.save(sampleLocation);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(
              state: const AppSettings(),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.text('Ayarlar'), findsOneWidget);
          expect(find.text('Bildirim'), findsOneWidget);
          expect(find.text('Kalıcı vakit bildirimi'), findsOneWidget);
          expect(
            find.text(
              'Sıradaki vakti ve geri sayımı bildirim çubuğunda gösterir',
            ),
            findsOneWidget,
          );

          expect(find.text('Görünüm'), findsOneWidget);
          expect(find.text('Tema'), findsOneWidget);
          expect(find.text('Sistem'), findsOneWidget);
          expect(find.text('Açık'), findsOneWidget);
          expect(find.text('Koyu'), findsOneWidget);

          expect(find.text('Konum'), findsNWidgets(2));
          expect(find.text('Bigadiç, Balıkesir'), findsOneWidget);

          expect(find.text('Hakkında'), findsOneWidget);
          expect(find.text('Veri kaynağı'), findsOneWidget);
          expect(
            find.text(
              'Vakitler Diyanet İşleri Başkanlığı verisidir. '
              'İnternet yokken cihazda hesaplanır.',
            ),
            findsOneWidget,
          );
          expect(find.text('Kıble yönü'), findsOneWidget);
          expect(
            find.text(
              'Gerçek kuzeye göre, manyetik sapma düzeltilerek '
              'hesaplanır.',
            ),
            findsOneWidget,
          );

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Switch e dokununca setNotificationEnabled(enabled: false) çağrılır',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(
            state: const AppSettings(),
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(SwitchListTile));
        await tester.pump();

        verify(
          () => mockCubit.setNotificationEnabled(enabled: false),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Switch kapalıyken dokununca setNotificationEnabled(enabled: true) '
      'çağrılır',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(
            state: const AppSettings(notificationEnabled: false),
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(SwitchListTile));
        await tester.pump();

        verify(
          () => mockCubit.setNotificationEnabled(enabled: true),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Koyu segmentine dokununca setThemePreference(ThemePreference.dark) '
      'çağrılır',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(
            state: const AppSettings(),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Koyu'));
        await tester.pump();

        verify(
          () => mockCubit.setThemePreference(ThemePreference.dark),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Açık segmentine dokununca setThemePreference(ThemePreference.light) '
      'çağrılır',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(
            state: const AppSettings(),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Açık'));
        await tester.pump();

        verify(
          () => mockCubit.setThemePreference(ThemePreference.light),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Konum kaydı yokken alt metin Seçilmedi görünür',
      (tester) async {
        configure360dp(tester);

        await tester.pumpWidget(
          buildSubject(state: const AppSettings()),
        );
        await tester.pump();

        expect(find.text('Seçilmedi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Konum satırına dokununca /konum a gidilir ve dönüşte konum güncellenir',
      (tester) async {
        configure360dp(tester);

        when(() => mockCubit.state).thenReturn(const AppSettings());

        final router = GoRouter(
          initialLocation: '/ayarlar',
          routes: [
            GoRoute(
              path: '/ayarlar',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) => const Scaffold(
                body: Text('konum-sayfasi'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildSubject(
            state: const AppSettings(),
            router: router,
          ),
        );
        await tester.pump();

        expect(find.widgetWithText(ListTile, 'Konum'), findsOneWidget);
        await tester.tap(find.widgetWithText(ListTile, 'Konum'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('konum-sayfasi'), findsOneWidget);

        await locationStore.save(sampleLocation);

        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('Bigadiç, Balıkesir'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
