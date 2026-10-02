import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';
import 'package:plezy/theme/plezzant/plezzant_palette.dart';

class WatchTogetherSessionIndicator extends StatelessWidget {
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;

  const WatchTogetherSessionIndicator({super.key, this.onCancelAutoHide, this.onStartAutoHide});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, provider, child) {
        return _SessionIndicator(
          participantCount: provider.participantCount,
          isHost: provider.isHost,
          isSyncing: provider.isSyncing,
          controlMode: provider.controlMode,
          sessionId: provider.sessionId,
          onTap: () => _showSessionMenu(context, provider),
        );
      },
    );
  }

  void _showSessionMenu(BuildContext context, WatchTogetherProvider provider) {
    onCancelAutoHide?.call();
    unawaited(
      OverlaySheetController.of(context)
          .show(
            showDragHandle: true,
            builder: (context) => ListenableBuilder(
              listenable: provider,
              builder: (context, _) => _SessionMenuSheet(provider: provider),
            ),
          )
          .whenComplete(() => onStartAutoHide?.call()),
    );
  }
}

class _SessionIndicator extends StatelessWidget {
  final int participantCount;
  final bool isHost;
  final bool isSyncing;
  final ControlMode controlMode;
  final String? sessionId;
  final VoidCallback onTap;

  const _SessionIndicator({
    required this.participantCount,
    required this.isHost,
    required this.isSyncing,
    required this.controlMode,
    required this.sessionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticValue = [
      '${t.watchTogether.participants}: $participantCount',
      if (isHost) t.watchTogether.youAreHost,
      if (isSyncing) t.watchTogether.syncing,
    ].join(', ');

    return FocusableWrapper(
      onSelect: onTap,
      semanticLabel: t.watchTogether.openSessionControls,
      semanticValue: semanticValue,
      descendantsAreFocusable: false,
      borderRadius: 20,
      useBackgroundFocus: true,
      child: Material(
        color: Colors.black54,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: .min,
              children: [
                if (isSyncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: PlatformDetector.isTV()
                        ? const AppIcon(LucideIcons.refreshCw, size: 16, color: Colors.white)
                        : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  AppIcon(LucideIcons.users, size: 18, color: isHost ? PlezzantColors.highlight : Colors.white),
                const SizedBox(width: 6),
                Text(
                  '$participantCount',
                  style: const TextStyle(color: Colors.white, fontWeight: .bold, fontSize: 14),
                ),
                if (isHost) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: PlezzantColors.highlight,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text(
                      t.watchTogether.hostBadge,
                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: .bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionMenuSheet extends StatelessWidget {
  final WatchTogetherProvider provider;

  const _SessionMenuSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomSheetPageScaffold(
      title: t.watchTogether.title,
      icon: LucideIcons.users,
      iconColor: theme.colorScheme.primary,
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Text(
          provider.controlMode == ControlMode.hostOnly ? t.watchTogether.hostControls : t.watchTogether.anyoneControls,
          style: theme.textTheme.labelSmall,
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            provider.isHost ? t.watchTogether.youAreHost : t.watchTogether.watchingWithOthers,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (provider.sessionId != null) ...[
            const SizedBox(height: 12),
            FocusableWrapper(
              onSelect: () => _copySessionCode(context, provider.sessionId!),
              semanticLabel: t.watchTogether.copySessionCode,
              semanticValue: provider.sessionId!,
              descendantsAreFocusable: false,
              borderRadius: 8,
              useBackgroundFocus: true,
              child: InkWell(
                canRequestFocus: false,
                onTap: () => _copySessionCode(context, provider.sessionId!),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Text(
                        '${t.watchTogether.sessionCode}: ',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        provider.sessionId!,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: .w800, letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 8),
                      AppIcon(LucideIcons.copy, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(t.watchTogether.participants, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final participant in provider.participants)
            if (provider.canTransferHostTo(participant))
              FocusableListTile(
                leading: _participantAvatar(theme, participant),
                title: Text(participant.displayName),
                trailing:
                    _bufferingIndicator(participant) ??
                    AppIcon(LucideIcons.star, size: 20, color: theme.colorScheme.onSurfaceVariant),
                onTap: () => unawaited(_confirmTransferHost(context, participant)),
                contentPadding: .zero,
              )
            else
              ListTile(
                leading: _participantAvatar(theme, participant),
                title: Text(participant.displayName),
                subtitle: participant.isHost ? Text(t.watchTogether.host) : null,
                trailing: _bufferingIndicator(participant),
                dense: false,
                contentPadding: .zero,
              ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          FocusableListTile(
            leading: AppIcon(LucideIcons.logOut, color: theme.colorScheme.error),
            title: Text(
              provider.isHost ? t.watchTogether.endSession : t.watchTogether.leaveSession,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => unawaited(_confirmLeave(context)),
            contentPadding: .zero,
          ),
        ],
      ),
    );
  }

  Widget _participantAvatar(ThemeData theme, Participant participant) {
    return CircleAvatar(
      backgroundColor: participant.isHost ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      child: AppIcon(
        participant.isHost ? LucideIcons.star : LucideIcons.user,
        color: participant.isHost ? Colors.white : theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget? _bufferingIndicator(Participant participant) {
    if (!participant.isBuffering) return null;
    return SizedBox(
      width: 16,
      height: 16,
      child: PlatformDetector.isTV()
          ? const AppIcon(LucideIcons.hourglass, size: 16)
          : const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Future<void> _confirmTransferHost(BuildContext context, Participant participant) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.watchTogether.makeHostQuestion,
      message: t.watchTogether.makeHostConfirm(name: participant.displayName),
      confirmText: t.watchTogether.transfer,
    );
    if (!confirmed || !context.mounted) return;
    provider.transferHost(participant);
    OverlaySheetController.closeAdaptive(context);
  }

  void _copySessionCode(BuildContext context, String sessionId) {
    Clipboard.setData(ClipboardData(text: sessionId));
    showSuccessSnackBar(context, t.watchTogether.sessionCodeCopied);
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: provider.isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion,
      message: provider.isHost ? t.watchTogether.endSessionConfirmOverlay : t.watchTogether.leaveSessionConfirmOverlay,
      confirmText: provider.isHost ? t.watchTogether.endSession : t.watchTogether.leave,
      isDestructive: true,
    );

    if (!confirmed) return;
    if (context.mounted) {
      OverlaySheetController.closeAdaptive(context);
    }
    unawaited(
      provider.leaveSession().catchError((Object error, StackTrace stackTrace) {
        appLogger.e('WatchTogether: Overlay leave failed', error: error, stackTrace: stackTrace);
      }),
    );
  }
}

class ParticipantNotificationOverlay extends StatefulWidget {
  const ParticipantNotificationOverlay({super.key});

  @override
  State<ParticipantNotificationOverlay> createState() => _ParticipantNotificationOverlayState();
}

class _ParticipantNotificationOverlayState extends State<ParticipantNotificationOverlay> {
  StreamSubscription<ParticipantEvent>? _subscription;
  final List<_NotificationEntry> _notifications = [];
  int _nextId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();
    try {
      final provider = context.read<WatchTogetherProvider>();
      _subscription = provider.participantEvents.listen(_onEvent);
    } catch (e) {
      appLogger.d('WatchTogetherOverlay: provider unavailable', error: e);
    }
  }

  void _onEvent(ParticipantEvent event) {
    if (!mounted) return;
    final id = _nextId++;
    setState(() {
      _notifications.add(_NotificationEntry(id: id, event: event));
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == id);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          children: _notifications.map((n) {
            final text = switch (n.event.type) {
              ParticipantEventType.joined => t.watchTogether.participantJoined(name: n.event.displayName),
              ParticipantEventType.left => t.watchTogether.participantLeft(name: n.event.displayName),
              ParticipantEventType.paused => t.watchTogether.participantPaused(name: n.event.displayName),
              ParticipantEventType.resumed => t.watchTogether.participantResumed(name: n.event.displayName),
              ParticipantEventType.seeked => t.watchTogether.participantSeeked(name: n.event.displayName),
              ParticipantEventType.changedSpeed => t.watchTogether.participantChangedSpeed(
                name: n.event.displayName,
                speed: formatPlaybackRate(n.event.rate ?? 1.0, normalAtOne: true),
              ),
              ParticipantEventType.buffering => t.watchTogether.participantBuffering(name: n.event.displayName),
              ParticipantEventType.needsUpdate => t.watchTogether.participantNeedsUpdate(name: n.event.displayName),
              ParticipantEventType.resumedWithout => t.watchTogether.resumingWithout(name: n.event.displayName),
              ParticipantEventType.hostChanged => t.watchTogether.hostChangedTo(name: n.event.displayName),
              ParticipantEventType.becameHost => t.watchTogether.youAreNowHost,
              ParticipantEventType.hostTransferFailed => t.watchTogether.hostTransferFailed(name: n.event.displayName),
            };
            return Container(
              key: ValueKey(n.id),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationEntry {
  final int id;
  final ParticipantEvent event;
  const _NotificationEntry({required this.id, required this.event});
}

class SyncingIndicator extends StatelessWidget {
  const SyncingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WatchTogetherProvider, bool>(
      selector: (_, provider) => provider.isSyncing,
      builder: (context, isSyncing, child) {
        if (!isSyncing) return const SizedBox.shrink();
        return _StatusPill(tvIcon: LucideIcons.refreshCw, label: t.watchTogether.syncing);
      },
    );
  }
}

class WaitingForParticipantsIndicator extends StatelessWidget {
  const WaitingForParticipantsIndicator({super.key});

  static String _label(List<String> names) {
    if (names.isEmpty) return t.watchTogether.waitingForParticipants;
    final shown = names.length <= 2 ? names.join(', ') : '${names.take(2).join(', ')} +${names.length - 2}';
    return t.watchTogether.waitingForName(name: shown);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WatchTogetherProvider, (bool, String)>(
      selector: (_, provider) {
        final waiting = provider.isWaitingForPeers;
        return (waiting, waiting ? _label(provider.waitingOnNames) : '');
      },
      builder: (context, value, child) {
        final (isWaiting, label) = value;
        if (!isWaiting) return const SizedBox.shrink();
        return _StatusPill(tvIcon: LucideIcons.hourglass, label: label);
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData tvIcon;
  final String label;

  const _StatusPill({required this.tvIcon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Row(
            mainAxisSize: .min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: PlatformDetector.isTV()
                    ? AppIcon(tvIcon, size: 14, color: Colors.white)
                    : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
