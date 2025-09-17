import 'dart:async';

/// Abstract interface for audio recording
abstract class AudioRecordingService {
  Future<bool> isSupported();
  Future<String?> startRecording(String filePath);
  Future<String?> stopRecording();
  Stream<bool> get recordingStateStream;
  bool get isRecording;
  void dispose();
}

/// Stub implementation for platforms where audio recording is not supported
class StubAudioRecordingService implements AudioRecordingService {
  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<String?> startRecording(String filePath) async {
    throw UnsupportedError('Audio recording not supported on this platform');
  }

  @override
  Future<String?> stopRecording() async {
    throw UnsupportedError('Audio recording not supported on this platform');
  }

  @override
  Stream<bool> get recordingStateStream => _stateController.stream;

  @override
  bool get isRecording => false;

  @override
  void dispose() {
    _stateController.close();
  }
}
