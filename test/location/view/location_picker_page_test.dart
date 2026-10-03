// LocationPickerPage ve LocationPickerView widget testleri.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/cubit/location_picker_cubit.dart';
import 'package:vakit/location/cubit/location_picker_state.dart';
import 'package:vakit/location/models/city.dart';
import 'package:vakit/location/models/district.dart';
import 'package:vakit/location/repository/device_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/location/view/location_picker_page.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/theme/app_theme.dart';

class _MockLocationPickerCubit extends MockCubit<LocationPickerState>
    implements LocationPickerCubit {}

class _MockDiyanetApi extends Mock implements DiyanetApi {}

class _MockLocationStore extends Mock implements LocationStore {}

class _MockDeviceLocation extends Mock implements DeviceLocation {}

void main() {
  const adanaCity = City(id: '500', name: 'ADANA');
  const afyonCity = City(id: '502', name: 'AFYONKARAHİSAR');
  const istanbulCity = City(id: '539', name: 'İSTANBUL');
  const marasCity = City(id: '541', name: 'KAHRAMANMARAŞ');

  const istanbulDistrict = District(id: '9541', name: 'İSTANBUL');
  const basaksehirDistrict = District(id: '17866', name: 'BAŞAKŞEHİR');

  late _MockLocationPickerCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(const City(id: '0', name: 'fallback'));
    registerFallbackValue(const District(id: '0', name: 'fallback'));
  });

  setUp(() {
    mockCubit = _MockLocationPickerCubit();
    when(() => mockCubit.loadCities()).thenAnswer((_) async {});
    when(() => mockCubit.selectCity(any())).thenAnswer((_) async {});
    when(() => mockCubit.selectDistrict(any())).thenAnswer((_) async {});
    when(() => mockCubit.locateMe()).thenAnswer((_) async {});
    when(() => mockCubit.search(any())).thenReturn(null);
    when(() => mockCubit.backToCities()).thenReturn(null);
  });

  void configure360dp(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildSubject({
    required LocationPickerState state,
    Brightness brightness = Brightness.light,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: BlocProvider<LocationPickerCubit>.value(
        value: mockCubit,
        child: const LocationPickerView(),
      ),
    );
  }

  group('LocationPickerView', () {
    testWidgets(
      'İl listesi görünür; dokununca selectCity çağrılır '
      '(açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          cities: [adanaCity, istanbulCity],
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text('Konum Seçimi'), findsOneWidget);
          expect(find.text('İl ara'), findsOneWidget);
          expect(find.text('Adana'), findsOneWidget);
          expect(find.text('İstanbul'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('İstanbul'));
          await tester.pump();

          verify(() => mockCubit.selectCity(istanbulCity)).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '"Konumumu bul" butonu görünür ve dokununca locateMe çağrılır '
      '(açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          cities: [adanaCity, istanbulCity],
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text('Konumumu bul'), findsOneWidget);
          expect(find.byIcon(Icons.my_location), findsOneWidget);
          expect(
            find.text(
              'İliniz ve ilçeniz otomatik bulunur. '
              'Koordinatlarınız hiçbir sunucuya gönderilmez.',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Konumumu bul'));
          await tester.pump();

          verify(() => mockCubit.locateMe()).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'İlçe adımında "Konumumu bul" butonu görünmez',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          districts: [istanbulDistrict],
        );

        await tester.pumpWidget(buildSubject(state: state));
        await tester.pump();

        expect(find.text('Konumumu bul'), findsNothing);
        expect(find.byIcon(Icons.my_location), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'locating iken düğme devre dışı ve ilerleme göstergesi görünür '
      '(açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          cities: [adanaCity, istanbulCity],
          locating: true,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konumumu bul'),
          );
          expect(button.onPressed, isNull);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'İlçe adımında (merkez) eki görünür ve dokununca selectDistrict '
      'çağrılır (açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          districts: [istanbulDistrict, basaksehirDistrict],
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text('İstanbul'), findsOneWidget);
          expect(find.text('İlçe ara'), findsOneWidget);
          expect(find.text('İstanbul (merkez)'), findsOneWidget);
          expect(find.text('Başakşehir'), findsOneWidget);
          expect(find.textContaining('(merkez)'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Başakşehir'));
          await tester.pump();

          verify(
            () => mockCubit.selectDistrict(basaksehirDistrict),
          ).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'İl hata durumunda Tekrar dene görünür ve tıklanınca loadCities '
      'çağrılır (açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const errorMessage =
            'İller alınamadı. İnternet bağlantınızı kontrol edin.';
        const state = LocationPickerState(
          errorMessage: errorMessage,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text(errorMessage), findsOneWidget);
          expect(find.text('Tekrar dene'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Tekrar dene'));
          await tester.pump();

          verify(() => mockCubit.loadCities()).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'İlçe hata durumunda Tekrar dene görünür ve tıklanınca selectCity '
      'çağrılır (açık ve koyu tema, 360 dp)',
      (tester) async {
        configure360dp(tester);

        const errorMessage =
            'İlçeler alınamadı. İnternet bağlantınızı kontrol edin.';
        const state = LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          errorMessage: errorMessage,
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text(errorMessage), findsOneWidget);
          expect(find.text('Tekrar dene'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Tekrar dene'));
          await tester.pump();

          verify(() => mockCubit.selectCity(istanbulCity)).called(1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Uzun il adları Afyonkarahisar ve Kahramanmaraş 360 dp de taşmaz',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          cities: [afyonCity, marasCity],
        );

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildSubject(state: state, brightness: brightness),
          );
          await tester.pump();

          expect(find.text('Afyonkarahisar'), findsOneWidget);
          expect(find.text('Kahramanmaraş'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Yükleniyor durumunda LinearProgressIndicator gösterilir',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(loading: true);

        await tester.pumpWidget(buildSubject(state: state));
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Arama alanına yazı girilince search çağrılır ve temizle butonu çalışır',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          cities: [adanaCity, istanbulCity],
          query: 'ist',
        );

        await tester.pumpWidget(buildSubject(state: state));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byTooltip('Temizle'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'adan');
        await tester.pump();

        verify(() => mockCubit.search('adan')).called(1);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Temizle'));
        await tester.pump();

        verify(() => mockCubit.search('')).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'İlçe adımında geri ok basılınca backToCities çağrılır',
      (tester) async {
        configure360dp(tester);

        const state = LocationPickerState(
          step: LocationPickerStep.districts,
          selectedCity: istanbulCity,
          districts: [istanbulDistrict],
        );

        await tester.pumpWidget(buildSubject(state: state));
        await tester.pump();

        expect(find.byTooltip('Geri'), findsOneWidget);
        await tester.tap(find.byTooltip('Geri'));
        await tester.pump();

        verify(() => mockCubit.backToCities()).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'saved: true olunca sayfadan pop(true) ile çıkılır',
      (tester) async {
        configure360dp(tester);

        whenListen(
          mockCubit,
          Stream.fromIterable([
            const LocationPickerState(saved: true),
          ]),
          initialState: const LocationPickerState(),
        );

        var poppedResult = false;
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      final result = await context.push<bool>('/konum');
                      poppedResult = result ?? false;
                    },
                    child: const Text('Konuma Git'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) =>
                  BlocProvider<LocationPickerCubit>.value(
                    value: mockCubit,
                    child: const LocationPickerView(),
                  ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        await tester.tap(find.text('Konuma Git'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(poppedResult, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'İl adımında geri ok basılınca sayfadan çıkılır',
      (tester) async {
        configure360dp(tester);

        when(() => mockCubit.state).thenReturn(
          const LocationPickerState(),
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/konum'),
                    child: const Text('Aç'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/konum',
              builder: (context, state) =>
                  BlocProvider<LocationPickerCubit>.value(
                    value: mockCubit,
                    child: const LocationPickerView(),
                  ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();

        await tester.tap(find.text('Aç'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(LocationPickerView), findsOneWidget);

        await tester.tap(find.byTooltip('Geri'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(LocationPickerView), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('LocationPickerPage', () {
    testWidgets(
      'LocationPickerPage RepositoryProvider lardan cubiti kurar ve '
      'loadCities çağırır',
      (tester) async {
        configure360dp(tester);

        final api = _MockDiyanetApi();
        final store = _MockLocationStore();
        final deviceLocation = _MockDeviceLocation();
        when(api.fetchCities).thenAnswer((_) async => []);

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<DiyanetApi>.value(value: api),
              RepositoryProvider<LocationStore>.value(value: store),
              RepositoryProvider<DeviceLocation>.value(value: deviceLocation),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const LocationPickerPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(LocationPickerPage), findsOneWidget);
        expect(find.byType(LocationPickerView), findsOneWidget);
        verify(api.fetchCities).called(1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LocationPickerPage cubit parametresi verildiğinde onu kullanır',
      (tester) async {
        configure360dp(tester);

        when(() => mockCubit.state).thenReturn(
          const LocationPickerState(),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: LocationPickerPage(cubit: mockCubit),
          ),
        );
        await tester.pump();

        expect(find.byType(LocationPickerPage), findsOneWidget);
        expect(find.byType(LocationPickerView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
