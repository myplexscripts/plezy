import '../../../../i18n/strings.g.dart';

/// How the server delivers the open source, as shown to the viewer.
enum PlaybackMethodLabel {
  /// The original file, untouched.
  directPlay,

  /// Video copied, container remuxed by the server (audio may be converted).
  directStream,

  /// Video re-encoded by the server.
  transcode,

  /// A downloaded copy on this device.
  localFile;

  /// Maps a backend `playMethod` value (`DirectPlay` / `DirectStream` /
  /// `Transcode`) onto a label, falling back to [isTranscoding] when the
  /// backend did not report one.
  static PlaybackMethodLabel resolve({String? playMethod, required bool isTranscoding, required bool isOffline}) {
    if (isOffline) return localFile;
    return switch (playMethod) {
      'DirectPlay' => directPlay,
      'DirectStream' => directStream,
      'Transcode' => transcode,
      _ => isTranscoding ? transcode : directPlay,
    };
  }

  String get label => switch (this) {
    directPlay => t.performanceOverlay.directPlay,
    directStream => t.performanceOverlay.directStream,
    transcode => t.performanceOverlay.transcode,
    localFile => t.performanceOverlay.localFile,
  };
}
