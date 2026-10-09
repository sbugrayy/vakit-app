// QiblaCubit birim testleri.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/qibla/cubit/qibla_cubit.dart';
import 'package:vakit/qibla/cubit/qibla_state.dart';
import 'package:vakit/qibla/models/heading_reading.dart';
import 'package:vakit/qibla/models/qibla_math.dart';
import 'package:vakit/qibla/repository/heading_source.dart';

class _MockLocationStore extends Mock implements LocationStore {}

class _MockHeadingSource extends Mock implements HeadingSource {}

void main() {
  const istanbul = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
    latitude: 41.0082,
    longitude: 28.9784,
  );

  const locationWithoutCoords = SelectedLocation(
    cityId: '539',
    cityName: 'İSTANBUL',
    districtId: '9541',
    districtName: 'İSTANBUL',
  );

  final istanbulBearing = qiblaBearing(41.0082, 28.9784);
  final istanbulDistance = distanceToKaabaKm(41.0082, 28.9784);

  late _MockLocationStore locationStore;
  late _MockHeadingSource headingSource;
  late StreamController<HeadingReading> headingController;

  setUp(() {
    locationStore = _MockLocationStore();
    headingSource = _MockHeadingSource();
    headingController = StreamController<HeadingReading>.broadcast();

    when(
      () => headingSource.watch(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) => headingController.stream);
  });

  tearDown(() {
    unawaited(headingController.close());
  });

  group('QiblaCubit', () {
    test('başlangıç durumu QiblaInitial olmalıdır', () {
      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );
      expect(cubit.state, equals(const QiblaInitial()));
      expect(cubit.state.props, isEmpty);
    });

    blocTest<QiblaCubit, QiblaState>(
      'konum bulunamadığında QiblaNeedsCoordinates yayınlar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => null);
      },
      build: () => QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      ),
      act: (cubit) => cubit.start(),
      expect: () => [const QiblaNeedsCoordinates()],
    );

    blocTest<QiblaCubit, QiblaState>(
      'konum koordinatsız olduğunda QiblaNeedsCoordinates yayınlar',
      setUp: () {
        when(
          () => locationStore.load(),
        ).thenAnswer((_) async => locationWithoutCoords);
      },
      build: () => QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      ),
      act: (cubit) => cubit.start(),
      expect: () => [const QiblaNeedsCoordinates()],
    );

    blocTest<QiblaCubit, QiblaState>(
      'İstanbul için bearing ≈ 151.62 ve distance ≈ 2405.1 hesaplar',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      },
      build: () => QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        predicate<QiblaReady>((state) {
          return (state.bearing - 151.62).abs() < 0.1 &&
              (state.distanceKm - 2405.1).abs() < 1 &&
              state.reading == null &&
              state.turn == null &&
              !state.aligned;
        }),
      ],
    );

    blocTest<QiblaCubit, QiblaState>(
      'okuma heading 151.0 -> aligned: true; heading 100 -> aligned: false',
      setUp: () {
        when(() => locationStore.load()).thenAnswer((_) async => istanbul);
      },
      build: () => QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      ),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        headingController.add(
          const HeadingReading(
            heading: 151,
            accuracy: HeadingAccuracy.high,
            trueNorth: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        headingController.add(
          const HeadingReading(
            heading: 100,
            accuracy: HeadingAccuracy.medium,
            trueNorth: true,
          ),
        );
      },
      expect: () => [
        isA<QiblaReady>()
            .having((state) => state.reading, 'reading', isNull)
            .having((state) => state.aligned, 'aligned', isFalse),
        isA<QiblaReady>()
            .having((state) => state.aligned, 'aligned', isTrue)
            .having(
              (state) => state.reading,
              'reading',
              const HeadingReading(
                heading: 151,
                accuracy: HeadingAccuracy.high,
                trueNorth: true,
              ),
            )
            .having((state) => state.turn, 'turn', isNotNull),
        isA<QiblaReady>()
            .having((state) => state.aligned, 'aligned', isFalse)
            .having(
              (state) => state.reading,
              'reading',
              const HeadingReading(
                heading: 100,
                accuracy: HeadingAccuracy.medium,
                trueNorth: true,
              ),
            )
            .having((state) => state.turn, 'turn', closeTo(51.62, 0.1)),
      ],
    );

    test('HeadingUnavailableException akış hatası -> Unavailable', () async {
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);

      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );

      final states = <QiblaState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.start();
      headingController.addError(
        const HeadingUnavailableException('Sensör yok'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(
        states[1],
        equals(
          const QiblaUnavailable('Bu cihazda pusula sensörü bulunamadı.'),
        ),
      );

      await subscription.cancel();
      await cubit.close();
    });

    test('Bilinmeyen akış hatası -> Unavailable', () async {
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);

      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );

      final states = <QiblaState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.start();
      headingController.addError(Exception('Genel hata'));
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(
        states[1],
        equals(
          const QiblaUnavailable('Bu cihazda pusula sensörü bulunamadı.'),
        ),
      );

      await subscription.cancel();
      await cubit.close();
    });

    test('close() sonrası denetleyicinin dinleyicisi kalmamış', () async {
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);

      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );

      await cubit.start();
      expect(headingController.hasListener, isTrue);

      await cubit.close();
      expect(headingController.hasListener, isFalse);
    });

    test('cubit kapandıktan sonra load dönerse durum yayınlanmaz', () async {
      final completer = Completer<SelectedLocation?>();
      when(() => locationStore.load()).thenAnswer((_) => completer.future);

      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );

      final startFuture = cubit.start();
      await cubit.close();
      completer.complete(istanbul);
      await startFuture;

      expect(cubit.state, equals(const QiblaInitial()));
    });

    test('cubit kapandıktan sonra akış olayları durumu etkilemez', () async {
      when(() => locationStore.load()).thenAnswer((_) async => istanbul);

      final cubit = QiblaCubit(
        locationStore: locationStore,
        headingSource: headingSource,
      );

      await cubit.start();
      await cubit.close();

      headingController
        ..add(
          const HeadingReading(
            heading: 151,
            accuracy: HeadingAccuracy.high,
            trueNorth: true,
          ),
        )
        ..addError(const HeadingUnavailableException());
      await Future<void>.delayed(Duration.zero);
    });

    test('QiblaReady copyWith tüm alanları doğru günceller', () {
      final ready = QiblaReady(
        bearing: istanbulBearing,
        distanceKm: istanbulDistance,
      );
      expect(ready.props, [
        istanbulBearing,
        istanbulDistance,
        null,
        null,
        false,
      ]);

      const reading = HeadingReading(
        heading: 151,
        accuracy: HeadingAccuracy.high,
        trueNorth: true,
      );
      final updated = ready.copyWith(
        bearing: 160,
        distanceKm: 2100,
        reading: reading,
        turn: 9,
        aligned: true,
      );

      expect(updated.bearing, equals(160));
      expect(updated.distanceKm, equals(2100));
      expect(updated.reading, equals(reading));
      expect(updated.turn, equals(9));
      expect(updated.aligned, isTrue);

      final untouched = ready.copyWith();
      expect(untouched, equals(ready));
    });

    test('QiblaUnavailable ve QiblaNeedsCoordinates props kontrolü', () {
      const unavailable = QiblaUnavailable('Hata');
      expect(unavailable.props, equals(['Hata']));

      const needsCoords = QiblaNeedsCoordinates();
      expect(needsCoords.props, isEmpty);
    });
  });
}
