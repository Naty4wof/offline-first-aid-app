import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';

enum VoiceSessionStatus { disconnected, connecting, connected, error }

abstract class VoiceLiveService {
  Stream<double> get audioLevelStream;
  Stream<VoiceSessionStatus> get statusStream;
  Future<void> startSession(String url);
  Future<void> stopSession();
  void dispose();
}

class VoiceLiveServiceImpl implements VoiceLiveService {
  WebSocket? _socket;
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // Alignment Buffer: Ensures we only feed complete 16-bit samples (2 bytes)
  // This prevents byte-swapping/alignment traps mid-stream.
  final List<int> _incomingBuffer = [];

  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  @override
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  final StreamController<VoiceSessionStatus> _statusController =
      StreamController<VoiceSessionStatus>.broadcast();
  @override
  Stream<VoiceSessionStatus> get statusStream => _statusController.stream;

  StreamSubscription? _recorderSubscription;

  @override
  Future<void> startSession(String url) async {
    _statusController.add(VoiceSessionStatus.connecting);

    if (url.contains('example.com')) {
      await _startMockSession();
      return;
    }

    try {
      _socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 10));

      // Initial handshake specifying audio-only modalities and turn detection
      final handshake = {
        'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'session.update',
        'session': {
          'modalities': ['audio', 'text'],
          'instructions':
              'You are a helpful first aid assistant. Respond only in Amharic.',
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'voice': 'alloy',
          'turn_detection': {
            'type': 'server_vad',
            'threshold': 0.5,
            'prefix_padding_ms': 300,
            'silence_duration_ms': 500,
          },
        },
      };

      final modalitiesHandshake = {
        'type': 'response.create',
        'response': {
          'modalities': ['AUDIO'],
        },
      };

      _socket?.add(jsonEncode(handshake));
      _socket?.add(jsonEncode(modalitiesHandshake));

      _socket?.listen(
        (data) {
          if (_socket?.readyState == WebSocket.open) {
            _statusController.add(VoiceSessionStatus.connected);
          }
          _handleWebSocketMessage(data);
        },
        onError: (err) {
          print('WebSocket Error: $err');
          _statusController.add(VoiceSessionStatus.error);
        },
        onDone: () => stopSession(),
      );

      await _player.openPlayer();
      // FIX: Explicitly binding to 16000Hz PCM16 to avoid 44.1kHz chipmunk trap
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        bufferSize: 8192,
        interleaved: true,
      );
      await _startRecording();
    } catch (e) {
      print('Error starting session: $e');
    }
  }

  @override
  Future<void> stopSession() async {
    _recorderSubscription?.cancel();
    await _recorder.stop();
    await _player.stopPlayer();
    _socket?.close();
    _socket = null;
  }

  void _handleWebSocketMessage(dynamic data) {
    if (data is String) {
      final Map<String, dynamic> message = jsonDecode(data);
      final type = message['type'];

      if (type == 'response.audio.delta') {
        final base64Audio = message['delta'];
        if (base64Audio != null) {
          final audioBytes = base64Decode(base64Audio);
          _playAudioChunk(audioBytes);
        }
      }
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      // FIX: Explicitly set Bit-Depth to PCM 16-bit to avoid Float32 scrambling trap
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _recorder.startStream(config);

      _recorderSubscription = stream.listen((data) {
        _calculateAudioLevel(data);

        if (_player.isPlaying) {
          _detectBargeIn(data);
        }

        final base64Audio = base64Encode(data);
        final audioEvent = {
          'type': 'input_audio_buffer.append',
          'audio': base64Audio,
        };
        _socket?.add(jsonEncode(audioEvent));
      });
    }
  }

  void _calculateAudioLevel(Uint8List data) {
    if (data.length < 2) return;

    // RMS calculation for 16-bit Signed Integer PCM (Little Endian)
    double sum = 0;
    int samples = data.length ~/ 2;

    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < samples; i++) {
      // Explicitly read as Int16 to verify Bit-Depth Layout
      final sample = byteData.getInt16(i * 2, Endian.little);
      sum += sample * sample;
    }

    final rms = math.sqrt(sum / samples);
    final level = (rms / 4000.0).clamp(0.0, 1.0);
    _audioLevelController.add(level);
  }

  Future<void> _startMockSession() async {
    await Future.delayed(const Duration(seconds: 1));
    _statusController.add(VoiceSessionStatus.connected);
    await _player.openPlayer();
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
      bufferSize: 8192,
      interleaved: true,
    );
    await _startRecording();

    Future.delayed(const Duration(seconds: 3), () {
      if (_statusController.isClosed) return;
      final dummyAudio = Uint8List(3200);
      for (int i = 0; i < dummyAudio.length; i++) dummyAudio[i] = (i % 255);
      _playAudioChunk(dummyAudio);
    });
  }

  Future<void> _playAudioChunk(Uint8List bytes) async {
    // 1. Bit-Depth Alignment: Accumulate bytes to ensure 2-byte alignment (Int16)
    _incomingBuffer.addAll(bytes);

    if (_incomingBuffer.length >= 2) {
      final evenLength = (_incomingBuffer.length ~/ 2) * 2;
      final alignedBytes = Uint8List.fromList(
        _incomingBuffer.sublist(0, evenLength),
      );

      _incomingBuffer.removeRange(0, evenLength);

      _calculateAudioLevel(alignedBytes);

      // Feed aligned 16kHz Int16 bytes to the player
      await _player.feedFromStream(alignedBytes);
    }
  }

  void _detectBargeIn(Uint8List data) {
    double sum = 0;
    for (int i = 0; i < data.length; i += 2) {
      if (i + 1 < data.length) {
        final sample = ByteData.sublistView(
          data,
          i,
          i + 2,
        ).getInt16(0, Endian.little);
        sum += sample.abs();
      }
    }
    final avgAmplitude = sum / (data.length / 2);

    if (avgAmplitude > 1500) {
      _interruptAI();
    }
  }

  Future<void> _interruptAI() async {
    print('Barge-in detected! Interrupting AI...');

    final interruptEvent = {'type': 'response.cancel'};
    final clearEvent = {'type': 'input_audio_buffer.clear'};

    _socket?.add(jsonEncode(interruptEvent));
    _socket?.add(jsonEncode(clearEvent));

    _incomingBuffer.clear();
    await _player.stopPlayer();

    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
      bufferSize: 8192,
      interleaved: true,
    );
  }

  @override
  void dispose() {
    _audioLevelController.close();
    _statusController.close();
    _socket?.close();
    _recorder.dispose();
    _player.closePlayer();
  }
}
