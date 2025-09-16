import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_shop/services/audio_recording_service.dart';
import 'package:virtual_shop/services/audio_service_factory.dart';

void main() {
  group('Audio Recording Service Tests', () {
    late AudioRecordingService audioService;

    setUp(() {
      audioService = AudioRecordingServiceFactory.getInstance();
    });

    test('should create audio service instance', () {
      expect(audioService, isNotNull);
    });

    test('should check if audio recording is supported', () async {
      final isSupported = await audioService.isSupported();
      expect(isSupported, isA<bool>());
    });

    test('should provide recording state stream', () {
      expect(audioService.recordingStateStream, isA<Stream<bool>>());
    });

    test('should return correct initial recording state', () {
      expect(audioService.isRecording, false);
    });

    tearDown(() {
      audioService.dispose();
      AudioRecordingServiceFactory.dispose();
    });
  });
}
