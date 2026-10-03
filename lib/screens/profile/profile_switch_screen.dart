import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_activation.dart';
import '../../profiles/profile_avatar.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_merge.dart';
import '../../services/app_exit_service.dart';
import '../../theme/plezzant/plezzant_typography.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/layout_constants.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focusable_popup_menu_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/profile_switching_overlay.dart';
import '../libraries/state_messages.dart';
import 'add_local_profile_screen.dart';
import 'pin_entry_dialog.dart';
import 'profile_teardown.dart';
import 'profile_detail_screen.dart';

/// Flat picker showing every [Profile] in the system — Plex Home users
/// auto-surfaced from connected accounts, plus user-created locals.
///
/// Each tile shows avatar, name, an Active badge for the current profile,
/// and one backend chip per connection bound to the profile (parent Plex
/// account + any borrowed connections for Plex Home users).
class ProfileSwitchScreen extends StatefulWidget {
  final bool requireSelection;

  const ProfileSwitchScreen({super.key, this.requireSelection = false});

  @override
  State<ProfileSwitchScreen> createState() => _ProfileSwitchScreenState();
}

class _ProfileSwitchScreenState extends State<ProfileSwitchScreen> with MountedSetStateMixin {
  bool _allowPop = false;
  final Map<String, FocusNode> _profileFocusNodes = {};
  final Map<String, FocusNode> _profileMenuFocusNodes = {};
  final Map<String, GlobalKey<AppMenuButtonState<_TileAction>>> _profileMenuKeys = {};
  bool _switching = false;

  @override
  void dispose() {
    for (final node in _profileFocusNodes.values) {
      node.dispose();
    }
    for (final node in _profileMenuFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the whole provider: with the view stream gone it is this
    // screen's only rebuild source, so the old stream+select double-rebuild
    // concern no longer applies.
    final activeProvider = context.watch<ActiveProfileProvider>();
    // Gate on initialization: rendering the not-yet-loaded profile list as
    // real data flashes the "No profiles available" error state on open.
    final loading = !activeProvider.isInitialized;
    final profiles = activeProvider.profiles;
    _pruneProfileFocusResources(profiles.map((p) => p.id).toSet());
    final activeId = activeProvider.activeId;
    return PopScope(
      canPop: !widget.requireSelection || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.requireSelection) {
          unawaited(AppExitService.requestExit());
        }
      },
      child: Stack(
        children: [
          if (PlatformDetector.isTV() && widget.requireSelection && profiles.isNotEmpty)
            // Fill the screen: as a loose Stack child the picker would shrink
            // to its avatar row.
            Positioned.fill(
              child: TvWhoIsWatching(
                profiles: profiles,
                avatarUrlFor: activeProvider.avatarUrlFor,
                focusNodeFor: _profileFocusNode,
                onSelect: _switching ? null : _switchTo,
                onAdd: _switching ? null : _addLocalProfile,
              ),
            )
          else
            FocusedScrollScaffold(
              title: Text(t.screens.switchProfile),
              automaticallyImplyLeading: !widget.requireSelection,
              onBackPressed: widget.requireSelection ? () => unawaited(AppExitService.requestExit()) : null,
              slivers: [
                if (profiles.isEmpty)
                  SliverFillRemaining(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : EmptyStateWidget(
                            message: t.messages.noProfilesAvailable,
                            subtitle: t.messages.contactAdminForProfiles,
                            icon: LucideIcons.userX,
                          ),
                  )
                else
                  ..._buildSections(activeProvider, activeId),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: FocusableWrapper(
                      disableScale: true,
                      borderRadius: 100,
                      useBackgroundFocus: true,
                      descendantsAreFocusable: false,
                      onSelect: _switching ? null : _addLocalProfile,
                      child: OutlinedButton.icon(
                        onPressed: _switching ? null : _addLocalProfile,
                        icon: const AppIcon(LucideIcons.userPlus, fill: 1),
                        label: Text(t.profiles.addPlezzantProfile),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_switching) const ProfileSwitchingOverlay(),
        ],
      ),
    );
  }

  FocusNode _profileFocusNode(Profile profile) {
    return _profileFocusNodes.putIfAbsent(profile.id, () => FocusNode(debugLabel: 'ProfileTile:${profile.id}'));
  }

  FocusNode _profileMenuFocusNode(Profile profile) {
    return _profileMenuFocusNodes.putIfAbsent(profile.id, () => FocusNode(debugLabel: 'ProfileActions:${profile.id}'));
  }

  GlobalKey<AppMenuButtonState<_TileAction>> _profileMenuKey(Profile profile) {
    return _profileMenuKeys.putIfAbsent(profile.id, () => GlobalKey<AppMenuButtonState<_TileAction>>());
  }

  void _pruneProfileFocusResources(Set<String> activeIds) {
    // Runs during build. Detach the map entries
    // synchronously so tiles never receive a stale node, but defer the
    // actual dispose to after the frame: on TV the pruned tile's node is
    // often the one holding primary focus (the profile just signed out /
    // deleted), and disposing the focused node mid-build wedges the focus
    // system on DPAD-only devices.
    final removed = <FocusNode>[];
    for (final id in _profileFocusNodes.keys.toList()) {
      if (!activeIds.contains(id)) {
        final node = _profileFocusNodes.remove(id);
        if (node != null) removed.add(node);
      }
    }
    for (final id in _profileMenuFocusNodes.keys.toList()) {
      if (!activeIds.contains(id)) {
        final node = _profileMenuFocusNodes.remove(id);
        if (node != null) removed.add(node);
      }
    }
    for (final id in _profileMenuKeys.keys.toList()) {
      if (!activeIds.contains(id)) {
        _profileMenuKeys.remove(id);
      }
    }
    if (removed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in removed) {
          node.dispose();
        }
      });
    }
  }

  void _openProfileMenu(Profile profile) {
    _profileMenuKeys[profile.id]?.currentState?.showButtonMenu();
  }

  List<Widget> _buildSections(ActiveProfileProvider activeProvider, String? activeId) {
    return [_profileList(activeProvider.profiles, activeProvider, activeId, autofocusFirst: true)];
  }

  SliverList _profileList(
    List<Profile> profiles,
    ActiveProfileProvider activeProvider,
    String? activeId, {
    required bool autofocusFirst,
  }) {
    // The tile keys and `findChildIndexCallback` below are one mechanism, not
    // two independent safeguards. A refreshed profile source can re-sort this
    // list after first paint; the key stops the sliver handing a tile's
    // Element the next profile's focus node, and the lookup lets it map that
    // key to its new index. Without the lookup the tile is destroyed and
    // re-inflated instead of moved, which keeps primary focus but resets
    // FocusableWrapper's chrome — a focused tile with no highlight (#1792).
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final profile = profiles[index];
          final isActive = profile.id == activeId;
          final tokensRef = tokens(context);
          final tileRadii = groupItemRadii(context, index, profiles.length);
          final isFirstSelectable = autofocusFirst && index == 0;
          final profileFocusNode = _profileFocusNode(profile);
          final menuFocusNode = _profileMenuFocusNode(profile);
          final menuKey = _profileMenuKey(profile);
          // All tile actions are disabled while a switch is binding: the
          // overlay's barrier blocks pointers but not DPAD key events, and a
          // Manage/Delete flow racing the in-flight switch corrupts state
          // (e.g. a delete confirmation left open when the switch settles).
          final actionsEnabled = !widget.requireSelection && !_switching;
          final onManage = actionsEnabled ? () => _manageProfile(profile) : null;
          final onDelete = profile.isLocal && actionsEnabled ? () => _deleteProfile(profile) : null;
          final onSignOut = profile.isPlexHome && profile.parentConnectionId != null && actionsEnabled
              ? () => _signOutPlexAccount(profile)
              : null;
          final hasMenu = onManage != null || onDelete != null || onSignOut != null;

          return Padding(
            key: ValueKey(profile.id),
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 4 : tokensRef.groupGap, 16, 0),
            // The focus fill must paint above the opaque Card surface, so the
            // wrapper sits inside the Card (clipped by its shape) rather than
            // around it.
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: tileRadii),
              clipBehavior: Clip.antiAlias,
              child: FocusableWrapper(
                autofocus: isFirstSelectable,
                focusNode: profileFocusNode,
                disableScale: true,
                useBackgroundFocus: true,
                borderRadii: tileRadii,
                enableLongPress: hasMenu,
                onLongPress: hasMenu ? () => _openProfileMenu(profile) : null,
                onNavigateRight: hasMenu ? () => menuFocusNode.requestFocus() : null,
                onSelect: _switching || (isActive && !widget.requireSelection) ? null : () => _switchTo(profile),
                child: _ProfileTile(
                  borderRadius: tileRadii,
                  profile: profile,
                  avatarUrl: activeProvider.avatarUrlFor(profile.id),
                  isActive: isActive && !widget.requireSelection,
                  chips: _chipsFor(profile, activeProvider),
                  onTap: () => _switchTo(profile),
                  onLongPress: hasMenu ? () => _openProfileMenu(profile) : null,
                  // Manage available for any profile — adding/removing
                  // borrowed connections is supported on plex_home too. Delete
                  // stays local-only (Plex Home users are owned by Plex).
                  onManage: onManage,
                  onDelete: onDelete,
                  onSignOut: onSignOut,
                  menuFocusNode: menuFocusNode,
                  menuKey: menuKey,
                  onMenuNavigateLeft: () => profileFocusNode.requestFocus(),
                ),
              ),
            ),
          );
        },
        childCount: profiles.length,
        findChildIndexCallback: (key) {
          final id = (key as ValueKey<String>).value;
          final index = profiles.indexWhere((profile) => profile.id == id);
          return index < 0 ? null : index;
        },
      ),
    );
  }

  /// Gate Manage/Delete on a non-active, PIN-protected local profile behind
  /// its PIN: without this the picker menu bypasses the lock entirely
  /// ([ProfileDetailScreen] exposes rename, PIN removal, and connection
  /// edits). The active profile already proved its PIN at switch time, and
  /// Plex Home profiles keep their server-side PIN flow. Loops on wrong
  /// entries with the same shake-on-error pattern as activation — see
  /// [showPinEntryDialog].
  Future<bool> _verifyPinForProfileAction(Profile profile) async {
    if (!profile.isLocal || !profile.isPinProtected) return true;
    if (profile.id == context.read<ActiveProfileProvider>().activeId) return true;
    String? errorMessage;
    while (true) {
      if (!mounted) return false;
      final pin = await showPinEntryDialog(context, profile.displayName, errorMessage: errorMessage);
      if (!mounted || pin == null) return false;
      if (verifyProfilePin(profile, pin)) return true;
      errorMessage = t.profiles.incorrectPinTryAgain;
    }
  }

  Future<void> _manageProfile(Profile profile) async {
    if (!await _verifyPinForProfileAction(profile)) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)));
  }

  /// Drop the parent Plex account [profile] hangs off — same effect as
  /// "Forget account" elsewhere in Plex apps. The shared teardown flow
  /// removes the account, its virtual Plex Home profiles, and their
  /// borrowed connections, then routes to auth when nothing selectable
  /// remains (#1423).
  Future<void> _signOutPlexAccount(Profile profile) async {
    final parentId = profile.parentConnectionId;
    if (parentId == null) return;
    await confirmAndSignOutPlexAccount(context, accountConnectionId: parentId);
  }

  Future<void> _deleteProfile(Profile profile) async {
    if (!await _verifyPinForProfileAction(profile)) return;
    if (!mounted) return;
    await confirmAndDeleteProfile(
      context,
      profile: profile,
      title: t.profiles.deleteThisProfileTitle,
      message: t.profiles.deleteThisProfileMessage(displayName: profile.displayName),
    );
  }

  List<_ChipData> _chipsFor(Profile profile, ActiveProfileProvider activeProvider) {
    final chips = <_ChipData>[];
    // Plex Home profiles implicitly own their parent Plex connection (no
    // join-table row), so prepend it before any borrowed connections. The
    // profile *is* the Home user there, so its own name identifies the user
    // half of the label.
    if (profile.isPlexHome) {
      final parentId = profile.parentConnectionId;
      if (parentId != null) {
        final conn = activeProvider.connectionsById[parentId];
        if (conn != null) chips.add(_chipFor(conn, user: profile.displayName));
      }
    }
    final pcs = visibleProfileConnections(
      profile,
      activeProvider.connectionsByProfile[profile.id] ?? const <ProfileConnection>[],
    );
    for (final pc in pcs) {
      final conn = activeProvider.connectionsById[pc.connectionId];
      if (conn != null) chips.add(_chipFor(conn, user: _plexHomeUserName(activeProvider, conn, pc.userIdentifier)));
    }
    return chips;
  }

  /// A Plex account connection labels itself with the account owner's name,
  /// which under a profile tile reads as the profile being signed in as that
  /// person — wrong for a Plex Home user, and wrong again for a local profile
  /// that borrowed a Home user out of someone else's account.
  ///
  /// Both halves of that relation go through a single translated string so a
  /// locale can order them itself; several put the account first (`ja`, `ko`,
  /// `tr`, `zh`). [user] is null only when the Home cache cannot resolve the
  /// connection's uuid yet, which falls back to naming the account alone.
  _ChipData _chipFor(Connection conn, {required String? user}) {
    return _ChipData(
      backend: conn.backend,
      label: switch (conn) {
        PlexAccountConnection(:final accountLabel) when user != null => t.profiles.plexAccountUserChip(
          user: user,
          account: accountLabel,
        ),
        PlexAccountConnection(:final accountLabel) => t.profiles.plexAccountChip(account: accountLabel),
        _ => conn.displayLabel,
      },
    );
  }

  /// Home user behind a borrowed Plex connection, or null when the live cache
  /// has no match for [userIdentifier] (not loaded yet, or the row predates
  /// the account's current Home membership).
  String? _plexHomeUserName(ActiveProfileProvider activeProvider, Connection conn, String userIdentifier) {
    if (conn is! PlexAccountConnection || userIdentifier.isEmpty) return null;
    final users = activeProvider.plexHomeByConnectionId[conn.id];
    if (users == null) return null;
    for (final user in users) {
      if (user.uuid == userIdentifier) return user.displayName;
    }
    return null;
  }

  Future<void> _addLocalProfile() async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddLocalProfileScreen()));
  }

  Future<void> _switchTo(Profile profile) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);
      final switched = await switchProfileFromUi(context, profile);
      if (!mounted || !switched) return;
      if (widget.requireSelection) {
        setState(() => _allowPop = true);
      }
      // Pop only when this screen is still the top route. A blind
      // `navigator.pop(true)` after the unbounded switch-await pops
      // whatever is topmost — it can dismiss a confirmation dialog WITH
      // `true` (auto-confirming a delete) or close the wrong screen.
      if (route != null && route.isCurrent) {
        navigator.pop(true);
      }
    } finally {
      setStateIfMounted(() => _switching = false);
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final Profile profile;
  final String? avatarUrl;
  final bool isActive;
  final BorderRadius borderRadius;
  final List<_ChipData> chips;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onManage;
  final VoidCallback? onDelete;
  final VoidCallback? onSignOut;
  final FocusNode menuFocusNode;
  final GlobalKey<AppMenuButtonState<_TileAction>> menuKey;
  final VoidCallback onMenuNavigateLeft;

  const _ProfileTile({
    required this.profile,
    required this.avatarUrl,
    required this.isActive,
    required this.borderRadius,
    required this.chips,
    required this.onTap,
    this.onLongPress,
    this.onManage,
    this.onDelete,
    this.onSignOut,
    required this.menuFocusNode,
    required this.menuKey,
    required this.onMenuNavigateLeft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = onManage != null || onDelete != null || onSignOut != null;
    return InkWell(
      canRequestFocus: false,
      onTap: isActive ? null : onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProfileAvatar(profile: profile, size: 44, avatarUrl: avatarUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(profile.displayName, style: theme.textTheme.titleMedium, overflow: .ellipsis),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        // Plain inline indicator instead of a boxed badge: a
                        // filled pill fights the tile's own focus fill.
                        AppIcon(LucideIcons.circleCheck, fill: 1, size: 16, color: tokens(context).textMuted),
                        const SizedBox(width: 4),
                        Text(
                          t.profiles.active,
                          style: theme.textTheme.labelMedium?.copyWith(color: tokens(context).textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _ConnectionChips(chips: chips),
                ],
              ),
            ),
            if (hasMenu)
              _ProfileActionsButton(
                menuKey: menuKey,
                focusNode: menuFocusNode,
                onNavigateLeft: onMenuNavigateLeft,
                onSelected: _handleAction,
                actions: [
                  if (onManage != null) _TileAction.manage,
                  if (onDelete != null) _TileAction.delete,
                  if (onSignOut != null) _TileAction.signOut,
                ],
              )
            else if (!isActive)
              const Padding(padding: .only(left: 8), child: AppIcon(LucideIcons.chevronRight, fill: 1)),
          ],
        ),
      ),
    );
  }

  void _handleAction(_TileAction action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (action) {
        case _TileAction.manage:
          onManage?.call();
          break;
        case _TileAction.delete:
          onDelete?.call();
          break;
        case _TileAction.signOut:
          onSignOut?.call();
          break;
      }
    });
  }
}

class _ProfileActionsButton extends StatelessWidget {
  final GlobalKey<AppMenuButtonState<_TileAction>> menuKey;
  final FocusNode focusNode;
  final VoidCallback onNavigateLeft;
  final ValueChanged<_TileAction> onSelected;
  final List<_TileAction> actions;

  const _ProfileActionsButton({
    required this.menuKey,
    required this.focusNode,
    required this.onNavigateLeft,
    required this.onSelected,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return FocusablePopupMenuButton<_TileAction>(
      menuKey: menuKey,
      focusNode: focusNode,
      semanticLabel: t.profiles.manage,
      onNavigateLeft: onNavigateLeft,
      icon: const AppIcon(LucideIcons.ellipsisVertical, fill: 1),
      tooltip: t.profiles.manage,
      onSelected: onSelected,
      itemBuilder: (_) => [for (final action in actions) AppMenuItem(value: action, label: action.label)],
    );
  }
}

extension _TileActionLabel on _TileAction {
  String get label {
    return switch (this) {
      _TileAction.manage => t.profiles.manage,
      _TileAction.delete => t.profiles.delete,
      _TileAction.signOut => t.profiles.signOut,
    };
  }
}

enum _TileAction { manage, delete, signOut }

class _ConnectionChips extends StatelessWidget {
  final List<_ChipData> chips;

  const _ConnectionChips({required this.chips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (chips.isEmpty) {
      return Text(t.profiles.noConnections, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error));
    }
    // Plain muted metadata instead of boxed chips: any filled pill fights the
    // tile's own focus fill (and the opaque theme surfaces read as dark holes
    // on it), so the connections render like the app's other meta rows.
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final c in chips)
          Row(
            mainAxisSize: .min,
            children: [
              BackendBadge(backend: c.backend, size: 12),
              const SizedBox(width: 5),
              // Account labels are often an email address, and an entry in a
              // Wrap gets unbounded main-axis space — without this the row
              // overflows the tile instead of ellipsizing.
              Flexible(
                child: Text(
                  c.label,
                  style: theme.textTheme.labelSmall?.copyWith(color: tokens(context).textMuted),
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ChipData {
  final MediaBackend backend;
  final String label;
  const _ChipData({required this.backend, required this.label});
}

/// Apple TV style "who's watching": round avatars centred on a soft gradient,
/// the focused one lifted with a white ring, and an add tile at the end.
class TvWhoIsWatching extends StatelessWidget {
  final List<Profile> profiles;
  final String? Function(String profileId) avatarUrlFor;
  final FocusNode Function(Profile profile) focusNodeFor;
  final Future<void> Function(Profile profile)? onSelect;
  final Future<void> Function()? onAdd;

  const TvWhoIsWatching({
    super.key,
    required this.profiles,
    required this.avatarUrlFor,
    required this.focusNodeFor,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scale = TvLayoutConstants.scaleOf(context);
    final avatarSize = 176.0 * scale;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8A5A63), Color(0xFF3F5F86), Color(0xFF1B3550)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.profiles.whoIsWatching,
              textAlign: TextAlign.center,
              style: PlezzantTvType.of(context, PlezzantTvType.screenTitle).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Color(0x55000000), blurRadius: 16)],
              ),
            ),
            SizedBox(height: 48 * scale),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 64 * scale, vertical: 48 * scale),
                // Centred while the row fits; scrolls once there are many profiles.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: math.max(0, constraints.maxWidth - 128 * scale)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, profile) in profiles.indexed)
                        _TvProfileTile(
                          focusNode: focusNodeFor(profile),
                          autofocus: index == 0,
                          size: avatarSize,
                          label: profile.displayName,
                          onSelect: onSelect == null ? null : () => onSelect!(profile),
                          builder: (_) =>
                              ProfileAvatar(profile: profile, size: avatarSize, avatarUrl: avatarUrlFor(profile.id)),
                        ),
                      _TvProfileTile(
                        size: avatarSize,
                        label: t.profiles.addProfileShort,
                        onSelect: onAdd,
                        builder: (focused) => AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: focused ? Colors.white : Colors.white.withValues(alpha: 0.18),
                          ),
                          child: Center(
                            child: AppIcon(
                              LucideIcons.plus,
                              fill: 1,
                              size: avatarSize * 0.32,
                              color: focused ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvProfileTile extends StatefulWidget {
  final FocusNode? focusNode;
  final bool autofocus;
  final double size;
  final String label;
  final VoidCallback? onSelect;
  final Widget Function(bool focused) builder;

  const _TvProfileTile({
    this.focusNode,
    this.autofocus = false,
    required this.size,
    required this.label,
    required this.onSelect,
    required this.builder,
  });

  @override
  State<_TvProfileTile> createState() => _TvProfileTileState();
}

class _TvProfileTileState extends State<_TvProfileTile> {
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'tv_profile_tile'));

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final onSelect = widget.onSelect;
    final ring = size * 0.045;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.16),
      child: FocusableWrapper(
        focusNode: _node,
        autofocus: widget.autofocus,
        onSelect: onSelect,
        delegateFocusBorder: true,
        focusScale: 1.1,
        autoScroll: true,
        borderRadius: size,
        semanticLabel: widget.label,
        child: ListenableBuilder(
          listenable: _node,
          builder: (context, _) {
            final focused = _node.hasFocus;
            return GestureDetector(
              onTap: onSelect,
              child: SizedBox(
                width: size + ring * 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.all(ring),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: focused ? Colors.white : Colors.transparent,
                        boxShadow: focused
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: size * 0.2)]
                            : const [],
                      ),
                      child: widget.builder(focused),
                    ),
                    SizedBox(height: size * 0.12),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: PlezzantTvType.of(context, PlezzantTvType.cardTitle).copyWith(
                        color: Colors.white.withValues(alpha: focused ? 1 : 0.78),
                        fontWeight: focused ? FontWeight.w700 : FontWeight.w600,
                        shadows: const [Shadow(color: Color(0x66000000), blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
