import 'dart:async';

import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'playback_coordinator.dart';
import 'settings_service.dart';
import 'trailer_resolver.dart';

/// Netflix-style trailer previews for the TV Home hero.
///
/// When a movie or show stays focused for [dwell], its trailer starts
/// silently behind the hero (the hero artwork fades out once the first frame
/// is up). Moving focus, leaving the screen or starting real playback stops
/// it. While a preview shows, the Play/Pause key opens the trailer full-screen
/// with sound (see [takeTrailerForPlayback]).
///
/// One preview at a time, on its own video core, which [PlaybackCoordinator]
/// tears down before any real playback builds one.
class TrailerPreviewService extends ChangeNotifier {
  TrailerPreviewService._() {
    PlaybackCoordinator.instance.registerTrailerPreview(stop: stop);
  }

  static final TrailerPreviewService instance = TrailerPreviewService._();

  /// How long a card must stay focused before its trailer starts.
  static const Duration dwell = Duration(milliseconds: 3500);

  Timer? _timer;
  Player? _player;
  MediaItem? _subject;
  MediaItem? _trailer;
  bool _showing = false;
  int _generation = 0;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The preview's player while it exists (the hero mounts its surface).
  Player? get player => _player;

  /// True once the preview has a frame on screen.
  bool get isShowing => _showing;

  /// The title whose trailer is previewing (or about to).
  MediaItem? get subject => _subject;

  /// Whether a preview of [item] is on screen.
  bool isShowingFor(MediaItem? item) => _showing && item != null && _subject?.globalKey == item.globalKey;

  bool _eligible(MediaItem item) {
    if (!PlatformDetector.isTV()) return false;
    if (!(SettingsService.instanceOrNull?.read(SettingsService.trailerPreviews) ?? false)) return false;
    if (item.kind != MediaKind.movie && item.kind != MediaKind.show) return false;
    return !PlaybackCoordinator.instance.hasVideoSession;
  }

  /// Focus moved to [item] (null: nothing previewable). Restarts the dwell.
  /// [otherAudioActive] (music playing) suppresses previews entirely.
  void focus(MediaItem? item, MediaServerClient? client, {bool otherAudioActive = false}) {
    if (item != null && _subject?.globalKey == item.globalKey && (_timer != null || _player != null)) return;
    unawaited(stop());
    if (item == null || client == null || otherAudioActive || !_eligible(item)) return;
    _subject = item;
    final generation = _generation;
    _timer = Timer(dwell, () => unawaited(_start(item, client, generation)));
  }

  Future<void> _start(MediaItem item, MediaServerClient client, int generation) async {
    _timer = null;
    final trailer = await TrailerResolver.instance.trailerFor(item, client);
    if (trailer == null || generation != _generation) return;
    String? url;
    try {
      url = await client.resolveExternalPlaybackUrl(trailer);
    } catch (e) {
      appLogger.d('Trailer preview URL unavailable', error: e);
    }
    if (url == null || generation != _generation || !_eligible(item)) return;

    final settings = SettingsService.instance;
    final player = Player(
      useExoPlayer: settings.read(SettingsService.useExoPlayer),
      hardwareDecoding: settings.read(SettingsService.enableHardwareDecoding),
    );
    _player = player;
    _trailer = trailer;
    notifyListeners();
    try {
      await player.setVolume(0);
      await player.setProperty('hwdec', settings.read(SettingsService.enableHardwareDecoding) ? 'auto' : 'no');
      if (generation != _generation) return;
      _subscriptions
        ..add(
          player.streams.playbackRestart.listen((_) {
            if (generation != _generation || _showing) return;
            _showing = true;
            notifyListeners();
            // Kick the video output once the surface is laid out (the player
            // screen does the same after layout changes).
            unawaited(player.updateFrame());
            // Once more after the hero has re-laid out without its artwork:
            // a surface placed just after the first frame can miss it.
            Timer(const Duration(milliseconds: 400), () {
              if (generation == _generation && !player.disposed) unawaited(player.updateFrame());
            });
          }),
        )
        ..add(
          player.streams.completed.listen((done) {
            if (done && generation == _generation) unawaited(stop());
          }),
        )
        ..add(
          player.streams.fileLoadFailed.listen((_) {
            if (generation == _generation) unawaited(stop());
          }),
        );
      await player.open(Media(url), play: true);
    } catch (e) {
      appLogger.d('Trailer preview failed', error: e);
      if (generation == _generation) await stop();
    }
  }

  /// Stops any pending or playing preview.
  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    _timer = null;
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    final player = _player;
    final wasVisible = _showing || player != null || _subject != null;
    _player = null;
    _trailer = null;
    _subject = null;
    _showing = false;
    if (wasVisible) notifyListeners();
    if (player == null || player.disposed) return;
    try {
      await player.stop();
    } catch (_) {}
    await player.dispose();
  }

  /// The previewing trailer, stopping the preview so real playback can take
  /// over; null when nothing is showing.
  Future<MediaItem?> takeTrailerForPlayback() async {
    final trailer = _showing ? _trailer : null;
    await stop();
    return trailer;
  }
}
