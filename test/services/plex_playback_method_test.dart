import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/playback_method_label.dart';

Map<String, Object?> _decision(List<Map<String, Object?>> streams) => {
  'MediaContainer': {
    'Metadata': [
      {
        'Media': [
          {
            'container': 'mp4',
            'Part': [
              {'decision': 'transcode', 'Stream': streams},
            ],
          },
        ],
      },
    ],
  },
};

void main() {
  group('PlexClient.decisionCopiesVideo', () {
    test('video copy is a Direct Stream', () {
      final body = _decision([
        {'streamType': 1, 'codec': 'hevc', 'decision': 'copy'},
        {'streamType': 2, 'codec': 'aac', 'decision': 'transcode'},
      ]);
      expect(PlexClient.decisionCopiesVideo(body), isTrue);
    });

    test('video re-encode is a Transcode', () {
      final body = _decision([
        {'streamType': 1, 'codec': 'h264', 'decision': 'transcode'},
        {'streamType': 2, 'codec': 'aac', 'decision': 'copy'},
      ]);
      expect(PlexClient.decisionCopiesVideo(body), isFalse);
    });

    test('string stream types are accepted', () {
      final body = _decision([
        {'streamType': '1', 'decision': 'copy'},
      ]);
      expect(PlexClient.decisionCopiesVideo(body), isTrue);
    });

    test('malformed or empty bodies are not a copy', () {
      expect(PlexClient.decisionCopiesVideo(null), isFalse);
      expect(PlexClient.decisionCopiesVideo('<html>'), isFalse);
      expect(PlexClient.decisionCopiesVideo({'MediaContainer': {}}), isFalse);
      expect(PlexClient.decisionCopiesVideo(_decision([])), isFalse);
    });
  });

  group('PlaybackMethodLabel.resolve', () {
    test('maps backend play methods', () {
      expect(
        PlaybackMethodLabel.resolve(playMethod: 'DirectPlay', isTranscoding: false, isOffline: false),
        PlaybackMethodLabel.directPlay,
      );
      expect(
        PlaybackMethodLabel.resolve(playMethod: 'DirectStream', isTranscoding: true, isOffline: false),
        PlaybackMethodLabel.directStream,
      );
      expect(
        PlaybackMethodLabel.resolve(playMethod: 'Transcode', isTranscoding: true, isOffline: false),
        PlaybackMethodLabel.transcode,
      );
    });

    test('falls back to the transcoding flag without a reported method', () {
      expect(
        PlaybackMethodLabel.resolve(playMethod: null, isTranscoding: true, isOffline: false),
        PlaybackMethodLabel.transcode,
      );
      expect(
        PlaybackMethodLabel.resolve(playMethod: null, isTranscoding: false, isOffline: false),
        PlaybackMethodLabel.directPlay,
      );
    });

    test('downloaded copies report a local file', () {
      expect(
        PlaybackMethodLabel.resolve(playMethod: 'DirectPlay', isTranscoding: false, isOffline: true),
        PlaybackMethodLabel.localFile,
      );
    });
  });
}
