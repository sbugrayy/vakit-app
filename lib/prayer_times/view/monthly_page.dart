// Aylık namaz vakitleri sayfası; aylık çizelge listesi ve durum gösterimleri.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_cubit.dart';
import 'package:vakit/prayer_times/cubit/monthly_times_state.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/widgets/time_format.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/theme/app_spacing.dart';

class MonthlyPage extends StatelessWidget {
  const MonthlyPage({
    super.key,
    this.onSelectLocation,
  });

  final Future<void> Function()? onSelectLocation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = MonthlyTimesCubit(
          locationStore: context.read<LocationStore>(),
          repository: context.read<PrayerTimesRepository>(),
          clock: context.read<Clock>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: MonthlyView(onSelectLocation: onSelectLocation),
    );
  }
}

class MonthlyView extends StatelessWidget {
  const MonthlyView({
    super.key,
    this.onSelectLocation,
  });

  final Future<void> Function()? onSelectLocation;

  Future<void> _handleSelectLocation(BuildContext context) async {
    if (onSelectLocation != null) {
      await onSelectLocation!();
      return;
    }
    await context.push('/konum');
    if (context.mounted) {
      await context.read<MonthlyTimesCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MonthlyTimesCubit, MonthlyTimesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: state is MonthlyTimesLoaded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Aylık Vakitler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${state.location.districtName}, '
                        '${state.location.cityName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : const Text('Aylık Vakitler'),
          ),
          body: switch (state) {
            MonthlyTimesLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            MonthlyTimesNeedsLocation() => _NeedsLocationView(
              onSelectLocation: () => unawaited(
                _handleSelectLocation(context),
              ),
            ),
            MonthlyTimesError(:final message) => _ErrorView(
              message: message,
              onRetry: () => unawaited(
                context.read<MonthlyTimesCubit>().load(),
              ),
            ),
            MonthlyTimesLoaded() => _LoadedView(state: state),
          },
        );
      },
    );
  }
}

class _NeedsLocationView extends StatelessWidget {
  const _NeedsLocationView({required this.onSelectLocation});

  final VoidCallback onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: AppSpacing.xxl * 2,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Önce konum seçin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onSelectLocation,
              child: const Text('Konum seç'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSpacing.xxl * 2,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final MonthlyTimesLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = state.source == PrayerDataSource.offline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOffline)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              'Çevrimdışı hesap: Diyanet verisine ulaşılamadı, '
              'vakitler cihazda hesaplandı.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: state.days.length,
            itemBuilder: (context, index) {
              final day = state.days[index];
              return _DayCard(
                day: day,
                isToday: index == state.todayIndex,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isToday,
  });

  final PrayerDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat('d MMMM EEEE', 'tr').format(day.date);

    final cardColor = isToday
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;

    final primaryTextColor = isToday
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    final secondaryTextColor = isToday
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            'Bugün',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (day.hijriDate.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    day.hijriDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: Prayer.values.map((prayer) {
                final time = day.timeOf(prayer);
                final formattedTime = formatClock(time, day.utcOffset);

                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        prayer.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formattedTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
