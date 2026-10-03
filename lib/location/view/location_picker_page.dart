// Konum seçimi sayfası; il ve ilçe arama ve seçme arayüzü.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vakit/location/cubit/location_picker_cubit.dart';
import 'package:vakit/location/cubit/location_picker_state.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/location/turkish_text.dart';
import 'package:vakit/shared/diyanet/diyanet_api.dart';
import 'package:vakit/theme/app_spacing.dart';

class LocationPickerPage extends StatelessWidget {
  const LocationPickerPage({super.key, this.cubit});

  final LocationPickerCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const LocationPickerView(),
      );
    }

    return BlocProvider(
      create: (context) {
        final cubit = LocationPickerCubit(
          api: context.read<DiyanetApi>(),
          locationStore: context.read<LocationStore>(),
        );
        unawaited(cubit.loadCities());
        return cubit;
      },
      child: const LocationPickerView(),
    );
  }
}

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key});

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pop(BuildContext context, [Object? result]) {
    if (GoRouter.maybeOf(context) != null) {
      context.pop(result);
    } else {
      unawaited(Navigator.of(context).maybePop(result));
    }
  }

  void _handlePop(BuildContext context, bool didPop) {
    if (didPop) {
      return;
    }
    final cubit = context.read<LocationPickerCubit>();
    if (cubit.state.step == LocationPickerStep.districts) {
      cubit.backToCities();
    } else {
      _pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LocationPickerCubit, LocationPickerState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved ||
          previous.query != current.query ||
          previous.step != current.step,
      listener: (context, state) {
        if (state.saved) {
          _pop(context, true);
          return;
        }
        if (_searchController.text != state.query) {
          _searchController.text = state.query;
        }
      },
      builder: (context, state) {
        final isDistricts = state.step == LocationPickerStep.districts;
        final title = isDistricts
            ? displayName(state.selectedCity?.name ?? '')
            : 'Konum Seçimi';

        return PopScope(
          canPop: !isDistricts,
          onPopInvokedWithResult: (didPop, _) => _handlePop(context, didPop),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Geri',
                onPressed: () {
                  if (isDistricts) {
                    context.read<LocationPickerCubit>().backToCities();
                  } else {
                    _pop(context);
                  }
                },
              ),
            ),
            body: Column(
              children: [
                if (state.loading)
                  const LinearProgressIndicator(minHeight: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: context.read<LocationPickerCubit>().search,
                    decoration: InputDecoration(
                      hintText: isDistricts ? 'İlçe ara' : 'İl ara',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Temizle',
                              onPressed: () {
                                _searchController.clear();
                                context.read<LocationPickerCubit>().search('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildContent(context, state, theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    LocationPickerState state,
    ThemeData theme,
  ) {
    if (state.errorMessage != null) {
      return _FailureContent(
        message: state.errorMessage!,
        onRetry: () {
          final cubit = context.read<LocationPickerCubit>();
          if (state.step == LocationPickerStep.cities) {
            unawaited(cubit.loadCities());
          } else if (state.selectedCity != null) {
            unawaited(cubit.selectCity(state.selectedCity!));
          }
        },
      );
    }

    if (state.step == LocationPickerStep.cities) {
      final cities = state.visibleCities;
      return ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];
          return ListTile(
            title: Text(
              displayName(city.name),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () => context.read<LocationPickerCubit>().selectCity(city),
          );
        },
      );
    }

    final districts = state.visibleDistricts;
    return ListView.builder(
      itemCount: districts.length,
      itemBuilder: (context, index) {
        final district = districts[index];
        final isCenter = state.isCenterDistrict(district);
        final name = displayName(district.name);
        final label = isCenter ? '$name (merkez)' : name;

        return ListTile(
          title: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () =>
              context.read<LocationPickerCubit>().selectDistrict(district),
        );
      },
    );
  }
}

class _FailureContent extends StatelessWidget {
  const _FailureContent({
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
