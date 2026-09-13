import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../i18n/strings.g.dart';
import '../utils/platform_detector.dart';

enum NavigationTabId { discover, explore, libraries, liveTv, search, downloads, settings }

class NavigationTab {
  final NavigationTabId id;
  final bool onlineOnly;
  final IconData icon;
  final String Function() getLabel;

  const NavigationTab({required this.id, required this.onlineOnly, required this.icon, required this.getLabel});

  Widget toDestination() {
    return DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: NavigationDestination(icon: AppIcon(icon), selectedIcon: AppIcon(icon), label: getLabel()),
    );
  }

  static List<NavigationTab> getVisibleTabs({
    required bool isOffline,
    bool hasLiveTv = false,
    bool hasExplore = false,
  }) {
    return allNavigationTabs.where((tab) {
      if (isOffline && tab.onlineOnly) return false;
      if (tab.id == NavigationTabId.liveTv && !hasLiveTv) return false;
      if (tab.id == NavigationTabId.explore && !hasExplore) return false;
      if (tab.id == NavigationTabId.downloads && PlatformDetector.isAppleTV()) return false;
      return true;
    }).toList();
  }

  static NavigationTabId resolveDefaultTab({
    required bool isOffline,
    required bool hasLiveTv,
    bool hasExplore = false,
    required NavigationTabId? preferredStartup,
  }) {
    final tabs = getVisibleTabs(isOffline: isOffline, hasLiveTv: hasLiveTv, hasExplore: hasExplore);
    if (isOffline && tabs.any((t) => t.id == NavigationTabId.downloads)) {
      return NavigationTabId.downloads;
    }
    if (preferredStartup != null && tabs.any((t) => t.id == preferredStartup)) {
      return preferredStartup;
    }
    return tabs.first.id;
  }
}

String _getHomeLabel() => t.common.home;
String _getExploreLabel() => t.navigation.explore;
String _getLibrariesLabel() => t.navigation.libraries;
String _getLiveTvLabel() => t.navigation.liveTv;
String _getSearchLabel() => t.common.search;
String _getDownloadsLabel() => t.navigation.downloads;
String _getSettingsLabel() => t.common.settings;

const allNavigationTabs = [
  NavigationTab(id: NavigationTabId.discover, onlineOnly: true, icon: LucideIcons.house, getLabel: _getHomeLabel),
  NavigationTab(
    id: NavigationTabId.libraries,
    onlineOnly: true,
    icon: LucideIcons.library_big,
    getLabel: _getLibrariesLabel,
  ),
  NavigationTab(id: NavigationTabId.liveTv, onlineOnly: true, icon: LucideIcons.tv, getLabel: _getLiveTvLabel),
  NavigationTab(id: NavigationTabId.explore, onlineOnly: true, icon: LucideIcons.compass, getLabel: _getExploreLabel),
  NavigationTab(id: NavigationTabId.search, onlineOnly: true, icon: LucideIcons.search, getLabel: _getSearchLabel),
  NavigationTab(
    id: NavigationTabId.downloads,
    onlineOnly: false,
    icon: LucideIcons.download,
    getLabel: _getDownloadsLabel,
  ),
  NavigationTab(
    id: NavigationTabId.settings,
    onlineOnly: false,
    icon: LucideIcons.settings,
    getLabel: _getSettingsLabel,
  ),
];
