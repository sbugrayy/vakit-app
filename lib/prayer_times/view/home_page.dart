// Ana ekran görünümü, vakit kartı, vakit listesi ve durum gösterimleri.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/notifications/repository/notification_bridge.dart';
import 'package:vakit/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:vakit/prayer_times/cubit/prayer_times_state.dart';
import 'package:vakit/prayer_times/models/prayer.dart';
import 'package:vakit/prayer_times/models/prayer_day.dart';
import 'package:vakit/prayer_times/repository/prayer_times_repository.dart';
import 'package:vakit/prayer_times/widgets/time_format.dart';
import 'package:vakit/shared/clock.dart';
import 'package:vakit/theme/app_spacing.dart';
import 'package:vakit/theme/app_typography.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onSelectLocation,
  });

  final Future<void> Function()? onSelectLocation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = PrayerTimesCubit(
          locationStore: context.read<LocationStore>(),
          repository: context.read<PrayerTimesRepository>(),
          notificationBridge: context.read<NotificationBridge>(),
          clock: context.read<Clock>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: HomeView(onSelectLocation: onSelectLocation),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.onSelectLocation,
  });

  final Future<void> Function()? onSelectLocation;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<PrayerTimesCubit>().requestNotificationPermission(),
    );
  }

  Future<void> _handleSelectLocation() async {
    if (widget.onSelectLocation != null) {
      await widget.onSelectLocation!();
      return;
    }
    await context.push('/konum');
    if (mounted) {
      await context.read<PrayerTimesCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      buildWhen: (previous, current) {
        if (previous is! PrayerTimesLoaded || current is! PrayerTimesLoaded) {
          return true;
        }
        return previous.location != current.location ||
            previous.result != current.result ||
            previous.status.next?.prayer != current.status.next?.prayer ||
            previous.status.next?.date != current.status.next?.date ||
            previous.status.current?.prayer != current.status.current?.prayer ||
            previous.status.today != current.status.today ||
            previous.status.daysRemaining != current.status.daysRemaining;
      },
      builder: (context, state) {
        return switch (state) {
          PrayerTimesInitial() || PrayerTimesLoading() => const _LoadingView(),
          PrayerTimesNeedsLocation() => _NeedsLocationView(
            onSelectLocation: _handleSelectLocation,
          ),
          PrayerTimesFailure(:final message) => _FailureView(
            message: message,
            onRetry: () => context.read<PrayerTimesCubit>().load(),
          ),
          PrayerTimesLoaded() => _LoadedView(
            state: state,
            onSelectLocation: _handleSelectLocation,
          ),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _NeedsLocationView extends StatelessWidget {
  const _NeedsLocationView({required this.onSelectLocation});

  final VoidCallback onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
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
                'Vakitleri gösterebilmemiz için konumunuzu seçin.',
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
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
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
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.onSelectLocation,
  });

  final PrayerTimesLoaded state;
  final VoidCallback onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = state.status.today;
    final next = state.status.next;

    final displayDay =
        today ??
        (next != null
            ? state.result.days.where((d) => d.date == next.date).firstOrNull
            : null) ??
        (state.result.days.isNotEmpty ? state.result.days.first : null);

    final utcOffset =
        today?.utcOffset ??
        (state.result.days.isNotEmpty
            ? state.result.days.first.utcOffset
            : const Duration(hours: 3));

    final badge = _buildSourceBadge(state);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.location.districtName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              state.location.cityName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Kıble',
            onPressed: () => unawaited(context.push('/kible')),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => context.read<PrayerTimesCubit>().load(
              forceRefresh: true,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Konum seç',
            onPressed: onSelectLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (badge != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: badge,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildNextPrayerCard(context, state, utcOffset),
            const SizedBox(height: AppSpacing.lg),
            if (displayDay != null) ...[
              _buildDateRow(context, displayDay),
              const SizedBox(height: AppSpacing.sm),
              _buildPrayersList(context, state, displayDay),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildSourceBadge(PrayerTimesLoaded state) {
    final String? label;
    if (state.result.source == PrayerDataSource.offline) {
      label = 'Çevrimdışı hesap';
    } else if (state.result.source == PrayerDataSource.cache &&
        state.status.daysRemaining < 3) {
      label = 'Veriler güncellenmeli';
    } else {
      label = null;
    }

    if (label == null) {
      return null;
    }

    return Chip(
      label: Text(label),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }

  Widget _buildNextPrayerCard(
    BuildContext context,
    PrayerTimesLoaded state,
    Duration utcOffset,
  ) {
    final theme = Theme.of(context);
    final next = state.status.next;

    if (next == null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              'Vakit bilgisi güncel değil. Yenileyin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sıradaki vakit',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  next.prayer.label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  formatClock(next.time, utcOffset),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _CountdownSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(BuildContext context, PrayerDay displayDay) {
    final theme = Theme.of(context);
    final formattedDate = formatLongDate(displayDay.date);
    final hasHijri = displayDay.hijriDate.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        hasHijri ? '$formattedDate • ${displayDay.hijriDate}' : formattedDate,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPrayersList(
    BuildContext context,
    PrayerTimesLoaded state,
    PrayerDay displayDay,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final next = state.status.next;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: Prayer.values.map((prayer) {
            final isNext =
                next != null &&
                next.prayer == prayer &&
                next.date == displayDay.date;

            final bool isPast;
            if (next == null) {
              isPast = true;
            } else if (displayDay.date.isBefore(next.date)) {
              isPast = true;
            } else if (displayDay.date.isAfter(next.date)) {
              isPast = false;
            } else {
              isPast = prayer.index < next.prayer.index;
            }

            final backgroundColor = isNext
                ? colorScheme.primaryContainer
                : null;

            final Color textColor;
            if (isNext) {
              textColor = colorScheme.onPrimaryContainer;
            } else if (isPast) {
              textColor = colorScheme.onSurfaceVariant;
            } else {
              textColor = colorScheme.onSurface;
            }

            final prayerTime = displayDay.timeOf(prayer);
            final formattedTime = formatClock(
              prayerTime,
              displayDay.utcOffset,
            );

            return Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prayer.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CountdownSection extends StatelessWidget {
  const _CountdownSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PrayerTimesCubit,
      PrayerTimesState,
      ({Duration? remaining, double? progress})
    >(
      selector: (state) {
        if (state is PrayerTimesLoaded) {
          return (
            remaining: state.status.remaining,
            progress: state.status.progress,
          );
        }
        return (remaining: null, progress: null);
      },
      builder: (context, data) {
        final theme = Theme.of(context);
        final remaining = data.remaining ?? Duration.zero;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatCountdown(remaining),
              style: AppTypography.countdown(theme.textTheme).copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: data.progress ?? 0,
                minHeight: AppSpacing.sm,
              ),
            ),
          ],
        );
      },
    );
  }
}
