import 'dart:async';
import 'package:record/record.dart';
import 'audio_recording_service.dart';

/// Implementation using the record package
class RecordAudioRecordingService implements AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<RecordState>? _recordSub;
  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();
  bool _isRecording = false;
  bool _isSupported = true;

  RecordAudioRecordingService() {
    _initializeRecorder();
  }

  void _initializeRecorder() {
    try {
      _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
        _isRecording = recordState == RecordState.record;
        _stateController.add(_isRecording);
      });
    } catch (e) {
      print('Audio recorder initialization failed: $e');
      _isSupported = false;
    }
  }

  @override
  Future<bool> isSupported() async => _isSupported;

  @override
  Future<String?> startRecording(String filePath) async {
    if (!_isSupported) {
      throw UnsupportedError('Audio recording not supported');
    }

    try {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      return filePath;
    } catch (e) {
      print('Failed to start recording: $e');
      _isSupported = false;
      throw e;
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isSupported) {
      throw UnsupportedError('Audio recording not supported');
    }

    try {
      return await _audioRecorder.stop();
    } catch (e) {
      print('Failed to stop recording: $e');
      throw e;
    }
  }

  @override
  Stream<bool> get recordingStateStream => _stateController.stream;

  @override
  bool get isRecording => _isRecording;

  @override
  void dispose() {
    _recordSub?.cancel();
    try {
      _audioRecorder.dispose();
    } catch (e) {
      print('Error disposing audio recorder: $e');
    }
    _stateController.close();
  }
}
