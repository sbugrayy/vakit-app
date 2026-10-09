// Ayarlar sayfası; bildirim, tema, konum ve veri kaynağı tercihleri.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vakit/location/models/selected_location.dart';
import 'package:vakit/location/repository/location_store.dart';
import 'package:vakit/settings/cubit/settings_cubit.dart';
import 'package:vakit/settings/models/app_settings.dart';
import 'package:vakit/theme/app_spacing.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SelectedLocation? _location;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocation());
  }

  Future<void> _loadLocation() async {
    final location = await context.read<LocationStore>().load();
    if (mounted) {
      setState(() {
        _location = location;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _handleSelectLocation() async {
    await context.push('/konum');
    if (mounted) {
      await _loadLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, state) {
          final subtitleText = _isLoadingLocation
              ? null
              : (_location != null
                    ? '${_location!.districtName}, ${_location!.cityName}'
                    : 'Seçilmedi');

          return ListView(
            children: [
              const _SectionHeader(title: 'Bildirim'),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: const Text('Kalıcı vakit bildirimi'),
                subtitle: const Text(
                  'Sıradaki vakti ve geri sayımı bildirim çubuğunda gösterir',
                ),
                value: state.notificationEnabled,
                onChanged: (value) => unawaited(
                  context.read<SettingsCubit>().setNotificationEnabled(
                    enabled: value,
                  ),
                ),
              ),
              const _SectionHeader(title: 'Görünüm'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tema',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ThemePreference>(
                      segments: const [
                        ButtonSegment(
                          value: ThemePreference.system,
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemePreference.light,
                          label: Text('Açık'),
                        ),
                        ButtonSegment(
                          value: ThemePreference.dark,
                          label: Text('Koyu'),
                        ),
                      ],
                      selected: {state.themePreference},
                      onSelectionChanged: (selected) {
                        final preference = selected.firstOrNull;
                        if (preference != null) {
                          unawaited(
                            context.read<SettingsCubit>().setThemePreference(
                              preference,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const _SectionHeader(title: 'Konum'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Konum'),
                subtitle: subtitleText != null ? Text(subtitleText) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => unawaited(_handleSelectLocation()),
              ),
              const _SectionHeader(title: 'Hakkında'),
              const ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: Icon(Icons.info_outline),
                title: Text('Veri kaynağı'),
                subtitle: Text(
                  'Vakitler Diyanet İşleri Başkanlığı verisidir. '
                  'İnternet yokken cihazda hesaplanır.',
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: Text('Kıble yönü'),
                subtitle: Text(
                  'Gerçek kuzeye göre, manyetik sapma düzeltilerek '
                  'hesaplanır.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
