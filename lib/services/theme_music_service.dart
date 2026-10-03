import 'dart:async';

import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../utils/app_logger.dart';
import 'playback_coordinator.dart';
import 'settings_service.dart';

/// Plays a title's theme song quietly behind its details page, like the
/// official Plex apps: a soft fade in, once through, and a fade out the moment
/// the viewer plays something or leaves.
///
/// Theme music never competes with real playback. It only starts while no
/// music or video session is live, and [PlaybackCoordinator] stops it before
/// either claims the audio pipeline.
class ThemeMusicService {
  ThemeMusicService._() {
    PlaybackCoordinator.instance.registerThemeMusic(stop: stopNow);
  }

  static final ThemeMusicService instance = ThemeMusicService._();

  /// Theme level relative to full volume; quiet enough to talk over.
  static const double themeVolume = 35;
  static const Duration _fadeIn = Duration(milliseconds: 1500);
  static const Duration _fadeOut = Duration(milliseconds: 600);
  static const int _fadeSteps = 12;

  Player? _player;
  Object? _owner;
  String? _url;
  int _generation = 0;

  bool get isPlaying => _player != null;

  /// Starts [url] for [owner] (usually a details page State). A second call for
  /// the same URL just takes ownership, so moving between a show and its season
  /// keeps the song going.
  Future<void> play({
    required Object owner,
    required String url,
    required Map<String, String> headers,
    required bool otherAudioActive,
  }) async {
    if (!(SettingsService.instanceOrNull?.read(SettingsService.playThemeMusic) ?? false)) return;
    if (otherAudioActive || PlaybackCoordinator.instance.hasVideoSession) return;
    if (_url == url && _player != null) {
      _owner = owner;
      return;
    }
    await stopNow();
    final generation = ++_generation;
    _owner = owner;
    _url = url;
    final player = Player.audio();
    _player = player;
    try {
      await player.setVolume(0);
      await player.open(Media(url, headers: headers), play: true);
      await _ramp(player, generation, from: 0, to: themeVolume, duration: _fadeIn);
    } catch (e) {
      appLogger.d('Theme music unavailable', error: e);
      if (generation == _generation) await stopNow();
    }
  }

  /// Fades out [owner]'s theme. Ignored when a newer page owns the song.
  Future<void> stop({required Object owner}) async {
    if (!identical(owner, _owner)) return;
    final player = _player;
    if (player == null) return;
    final generation = ++_generation;
    await _ramp(player, generation, from: themeVolume, to: 0, duration: _fadeOut);
    if (generation == _generation) await stopNow();
  }

  /// Immediate teardown (playback is about to start).
  Future<void> stopNow() async {
    _generation++;
    final player = _player;
    _player = null;
    _owner = null;
    _url = null;
    if (player == null || player.disposed) return;
    try {
      await player.stop();
    } catch (_) {}
    await player.dispose();
  }

  Future<void> _ramp(
    Player player,
    int generation, {
    required double from,
    required double to,
    required Duration duration,
  }) async {
    final step = Duration(microseconds: duration.inMicroseconds ~/ _fadeSteps);
    for (var i = 1; i <= _fadeSteps; i++) {
      if (generation != _generation || player.disposed) return;
      await player.setVolume(from + (to - from) * i / _fadeSteps);
      await Future<void>.delayed(step);
    }
  }
}
