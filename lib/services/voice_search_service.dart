import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/// Voice and global search from Android TV: "Search for … in Plezzant" from
/// the Assistant, or the system search, arrives here with its query (see
/// `MainActivity.handleSearchIntent`).
class VoiceSearchService {
  VoiceSearchService._();

  static final VoiceSearchService instance = VoiceSearchService._();

  static const MethodChannel _channel = MethodChannel('com.plezy/voice_search');

  ValueChanged<String>? _onQuery;

  /// Routes queries to [onQuery] and delivers one that launched the app.
  Future<void> attach(ValueChanged<String> onQuery) async {
    _onQuery = onQuery;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSearch' && call.arguments is String) _deliver(call.arguments as String);
    });
    try {
      final pending = await _channel.invokeMethod<String>('takePendingQuery');
      if (pending != null) _deliver(pending);
    } on MissingPluginException {
      // Not running inside the Android activity (tests, other platforms).
    } catch (e) {
      appLogger.d('Voice search channel unavailable', error: e);
    }
  }

  void detach(ValueChanged<String> onQuery) {
    if (_onQuery == onQuery) _onQuery = null;
  }

  void _deliver(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) _onQuery?.call(trimmed);
  }
}
