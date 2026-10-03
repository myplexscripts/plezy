import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/voice_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.plezy/voice_search');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('delivers the query that launched the app', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => call.method == 'takePendingQuery' ? ' harbor ' : null);
    final queries = <String>[];
    void onQuery(String q) => queries.add(q);

    await VoiceSearchService.instance.attach(onQuery);

    expect(queries, ['harbor']);
    VoiceSearchService.instance.detach(onQuery);
  });

  test('delivers queries spoken while running, ignoring blanks', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final queries = <String>[];
    void onQuery(String q) => queries.add(q);
    await VoiceSearchService.instance.attach(onQuery);

    Future<void> send(String query) => messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('onSearch', query)),
      (_) {},
    );
    await send('Cobalt');
    await send('   ');

    expect(queries, ['Cobalt']);
    VoiceSearchService.instance.detach(onQuery);
  });
}
