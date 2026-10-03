import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/catalog_sources_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/settings_service.dart' hide ThemeMode;
import '../../services/settings_service.dart' as settings show ThemeMode;
import '../../focus/focusable_slider.dart';
import '../../services/device_performance.dart';
import '../../utils/platform_detector.dart';
import '../../theme/plezzant/plezzant_preferences.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Nullable watch: hosts without the profile session scope (tests) simply
    // never show the Explore toggle, mirroring the tab's own visibility.
    final hasExplore = context.watch<CatalogSourcesProvider?>()?.hasAnySource ?? false;
    return SettingsPage(
      title: Text(t.settings.appearance),
      children: [
        SettingsGroup(
          title: t.settings.display,
          children: [
            _themeSelector(),
            _ambienceSelector(),
            _glassSelector(),
            if (PlatformDetector.isAutomotive()) _displayScaleSelector(),
            if (Platform.isAndroid) _visualEffectsSelector(context),
          ],
        ),

        SettingsGroup(
          title: t.settings.libraryAndCards,
          children: [
            _viewModeSelector(),
            _densitySelector(),
            _gridSpacingSelector(),
            if (PlatformDetector.isTV()) _tvCardStyleSelector(),
            _episodePosterModeSelector(),
            SettingSwitchTile(
              pref: SettingsService.showEpisodeNumberOnCards,
              icon: LucideIcons.hash,
              title: t.settings.showEpisodeNumberOnCards,
              subtitle: t.settings.showEpisodeNumberOnCardsDescription,
            ),
            if (!PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.showSeasonPostersOnTabs,
                icon: LucideIcons.image,
                title: t.settings.showSeasonPostersOnTabs,
                subtitle: t.settings.showSeasonPostersOnTabsDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.hideSpoilers,
              icon: LucideIcons.eyeOff,
              title: t.settings.hideSpoilers,
              subtitle: t.settings.hideSpoilersDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.showWatchedIndicators,
              icon: LucideIcons.circleCheck,
              title: t.settings.showWatchedIndicators,
              subtitle: t.settings.showWatchedIndicatorsDescription,
            ),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.tvFullCardLayout,
                icon: LucideIcons.image,
                title: t.settings.tvFullCardLayout,
                subtitle: t.settings.tvFullCardLayoutDescription,
              ),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.trailerPreviews,
                icon: LucideIcons.squarePlay,
                title: t.settings.trailerPreviews,
                subtitle: t.settings.trailerPreviewsDescription,
              ),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.tvCornerSpotlightBackdrop,
                icon: LucideIcons.pictureInPicture2,
                title: t.settings.tvCornerSpotlightBackdrop,
                subtitle: t.settings.tvCornerSpotlightBackdropDescription,
              ),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.focusGlow,
                icon: LucideIcons.lightbulb,
                title: t.settings.focusGlow,
                subtitle: t.settings.focusGlowDescription,
              ),
          ],
        ),

        SettingsGroup(
          title: t.settings.homeScreen,
          children: [
            if (!PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.showHeroSection,
                icon: LucideIcons.squarePlay,
                title: t.settings.showHeroSection,
                subtitle: t.settings.showHeroSectionDescription,
              ),
            _continueWatchingActionSelector(),
            _episodeActionSelector(),
            SettingSwitchTile(
              pref: SettingsService.useGlobalHubs,
              icon: LucideIcons.house,
              title: t.settings.useGlobalHubs,
              subtitle: t.settings.useGlobalHubsDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.showServerNameOnHubs,
              icon: LucideIcons.server,
              title: t.settings.showServerNameOnHubs,
              subtitle: t.settings.showServerNameOnHubsDescription,
            ),
          ],
        ),

        SettingsGroup(
          title: t.settings.navigation,
          children: [
            if (hasExplore)
              SettingSwitchTile(
                pref: SettingsService.showExploreTab,
                icon: LucideIcons.compass,
                title: t.settings.showExploreTab,
                subtitle: t.settings.showExploreTabDescription,
              ),
            if (PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.alwaysKeepSidebarOpen,
                icon: LucideIcons.panelLeft,
                title: t.settings.alwaysKeepSidebarOpen,
                subtitle: t.settings.alwaysKeepSidebarOpenDescription,
              ),
            if (PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.groupLibrariesByServer,
                icon: LucideIcons.server,
                title: t.settings.groupLibrariesByServer,
                subtitle: t.settings.groupLibrariesByServerDescription,
              ),
            if (!PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.showNavBarLabels,
                icon: LucideIcons.tag,
                title: t.settings.showNavBarLabels,
                subtitle: t.settings.showNavBarLabelsDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.showUnwatchedCount,
              icon: LucideIcons.squareDot,
              title: t.settings.showUnwatchedCount,
              subtitle: t.settings.showUnwatchedCountDescription,
            ),
          ],
        ),

        SettingsGroup(
          title: t.settings.liveTv,
          children: [
            SettingSwitchTile(
              pref: SettingsService.liveTvDefaultFavorites,
              icon: LucideIcons.star,
              title: t.settings.liveTvDefaultFavorites,
              subtitle: t.settings.liveTvDefaultFavoritesDescription,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Writes the pref directly; ThemeProvider listens to the pref's listenable
  // and applies the change live. The Consumer only feeds the dynamic icon.
  Widget _themeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SettingSelectionTile<settings.ThemeMode>(
          pref: SettingsService.themeMode,
          icon: themeProvider.themeModeIcon,
          title: t.settings.theme,
          subtitleBuilder: themeModeLabel,
          options: settings.ThemeMode.values.map((m) => DialogOption(value: m, title: themeModeLabel(m))).toList(),
        );
      },
    );
  }

  Widget _ambienceSelector() {
    String label(AmbienceIntensity v) => switch (v) {
      AmbienceIntensity.off => t.settings.ambienceOff,
      AmbienceIntensity.subtle => t.settings.ambienceSubtle,
      AmbienceIntensity.rich => t.settings.ambienceRich,
    };
    return SettingSelectionTile<AmbienceIntensity>(
      pref: SettingsService.ambienceIntensity,
      icon: LucideIcons.sunMoon,
      title: t.settings.ambience,
      subtitleBuilder: (v) => '${label(v)} · ${t.settings.ambienceDescription}',
      options: AmbienceIntensity.values.map((v) => DialogOption(value: v, title: label(v))).toList(),
    );
  }

  Widget _glassSelector() {
    String label(GlassIntensity v) => switch (v) {
      GlassIntensity.off => t.settings.glassOff,
      GlassIntensity.subtle => t.settings.glassSubtle,
      GlassIntensity.full => t.settings.glassFull,
    };
    return SettingSelectionTile<GlassIntensity>(
      pref: SettingsService.glassIntensity,
      icon: LucideIcons.layers,
      title: t.settings.glass,
      subtitleBuilder: (v) => '${label(v)} · ${t.settings.glassDescription}',
      options: GlassIntensity.values.map((v) => DialogOption(value: v, title: label(v))).toList(),
    );
  }

  // Same label-row-plus-control layout as SegmentedSetting so slider and
  // button-group tiles read as one family inside a SettingsGroup.
  Widget _densitySelector() {
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (context, density, _) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  const AppIcon(LucideIcons.layoutGrid, fill: 1),
                  const SizedBox(width: 16),
                  Text(t.settings.libraryDensity, style: settingsOptionTitleStyle(context)),
                ],
              ),
              const SizedBox(height: 12),
              FocusableSlider(
                value: density.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => SettingsService.instance.write(SettingsService.libraryDensity, v.round()),
              ),
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(t.settings.compact, style: theme.textTheme.bodySmall),
                  Text(t.settings.comfortable, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _displayScaleSelector() {
    return SettingValueBuilder<double>(
      pref: SettingsService.automotiveUiScale,
      builder: (context, scale, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  const AppIcon(LucideIcons.type, fill: 1),
                  const SizedBox(width: 16),
                  Text(t.settings.displayScale, style: settingsOptionTitleStyle(context)),
                  const Spacer(),
                  Text('${scale.toStringAsFixed(2)}×', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              FocusableSlider(
                value: scale,
                min: AutomotiveUiScale.min,
                max: AutomotiveUiScale.max,
                divisions: 20,
                onChanged: (value) => SettingsService.instance.write(SettingsService.automotiveUiScale, value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _viewModeSelector() => SettingSegmentedTile<ViewMode>(
    pref: SettingsService.viewMode,
    icon: LucideIcons.list,
    title: t.settings.viewMode,
    segments: [
      ButtonSegment(value: ViewMode.grid, label: Text(t.settings.gridView)),
      ButtonSegment(value: ViewMode.list, label: Text(t.settings.listView)),
    ],
  );

  Widget _gridSpacingSelector() => SettingSegmentedTile<GridSpacing>(
    pref: SettingsService.gridSpacing,
    icon: LucideIcons.squareDashed,
    title: t.settings.gridSpacing,
    segments: [
      ButtonSegment(value: GridSpacing.tight, label: Text(t.settings.gridSpacingTight)),
      ButtonSegment(value: GridSpacing.normal, label: Text(t.settings.gridSpacingNormal)),
      ButtonSegment(value: GridSpacing.spacious, label: Text(t.settings.gridSpacingSpacious)),
    ],
  );

  Widget _tvCardStyleSelector() => SettingSegmentedTile<TvCardStyle>(
    pref: SettingsService.tvCardStyle,
    icon: LucideIcons.galleryHorizontal,
    title: t.settings.tvCardStyle,
    segments: [
      ButtonSegment(value: TvCardStyle.landscape, label: Text(t.settings.tvCardStyleLandscape)),
      ButtonSegment(value: TvCardStyle.poster, label: Text(t.settings.tvCardStylePoster)),
    ],
  );

  Widget _episodePosterModeSelector() => SettingSegmentedTile<EpisodePosterMode>(
    pref: SettingsService.episodePosterMode,
    icon: LucideIcons.image,
    title: t.settings.episodePosterMode,
    segments: [
      ButtonSegment(value: EpisodePosterMode.seriesPoster, label: Text(t.settings.seriesPoster)),
      ButtonSegment(value: EpisodePosterMode.seasonPoster, label: Text(t.settings.seasonPoster)),
      ButtonSegment(value: EpisodePosterMode.episodeThumbnail, label: Text(t.settings.episodeThumbnail)),
    ],
  );

  Widget _continueWatchingActionSelector() => SettingSegmentedTile<ContinueWatchingAction>(
    pref: SettingsService.continueWatchingAction,
    icon: LucideIcons.circlePlay,
    title: t.settings.continueWatchingAction,
    segments: [
      ButtonSegment(value: ContinueWatchingAction.play, label: Text(t.settings.continueWatchingPlay)),
      ButtonSegment(value: ContinueWatchingAction.details, label: Text(t.settings.continueWatchingDetails)),
    ],
  );

  Widget _episodeActionSelector() => SettingSegmentedTile<EpisodeAction>(
    pref: SettingsService.episodeAction,
    icon: LucideIcons.tv,
    title: t.settings.episodeAction,
    segments: [
      ButtonSegment(value: EpisodeAction.play, label: Text(t.settings.episodePlay)),
      ButtonSegment(value: EpisodeAction.details, label: Text(t.settings.episodeDetails)),
    ],
  );

  String _visualEffectsLabel(VisualEffectsSetting value) => switch (value) {
    VisualEffectsSetting.auto => t.settings.visualEffectsAuto,
    VisualEffectsSetting.full => t.settings.visualEffectsFull,
    VisualEffectsSetting.reduced => t.settings.visualEffectsReduced,
  };

  Widget _visualEffectsSelector(BuildContext context) => SettingSelectionTile<VisualEffectsSetting>(
    pref: SettingsService.visualEffects,
    icon: LucideIcons.blend,
    title: t.settings.visualEffects,
    subtitleBuilder: _visualEffectsLabel,
    options: [
      DialogOption(
        value: VisualEffectsSetting.auto,
        title: t.settings.visualEffectsAuto,
        subtitle: t.settings.visualEffectsAutoDescription,
      ),
      DialogOption(value: VisualEffectsSetting.full, title: t.settings.visualEffectsFull),
      DialogOption(
        value: VisualEffectsSetting.reduced,
        title: t.settings.visualEffectsReduced,
        subtitle: t.settings.visualEffectsReducedDescription,
      ),
    ],
  );
}
