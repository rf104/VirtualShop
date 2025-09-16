import 'audio_recording_service.dart';
import 'record_audio_service.dart';

/// Factory for creating audio recording services
class AudioRecordingServiceFactory {
  static AudioRecordingService? _instance;

  static AudioRecordingService getInstance() {
    if (_instance != null) return _instance!;

    try {
      // Try to create the record-based service
      _instance = RecordAudioRecordingService();
      return _instance!;
    } catch (e) {
      print('Record package not available, using stub: $e');
      // Fallback to stub implementation
      _instance = StubAudioRecordingService();
      return _instance!;
    }
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
