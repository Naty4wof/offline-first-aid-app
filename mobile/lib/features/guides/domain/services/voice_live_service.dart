import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:record/record.dart';
import '../../../../core/services/audio_hardware_manager.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../ui/component/chat/chat_message.dart';
import 'pcm_stream_player.dart';

enum VoiceSessionStatus { disconnected, connecting, connected, error }

abstract class VoiceLiveService {
  Stream<double> get audioLevelStream;
  Stream<VoiceSessionStatus> get statusStream;
  Stream<ChatMessage> get transcriptStream;
  Future<void> startSession(String url);
  Future<void> stopSession();
  void dispose();
}

class VoiceLiveServiceImpl implements VoiceLiveService {
  WebSocket? _socket;
  final AudioRecorder _recorder = AudioRecorder();
  final PcmStreamPlayer _player = PcmStreamPlayer();

  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  @override
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  final StreamController<VoiceSessionStatus> _statusController =
      StreamController<VoiceSessionStatus>.broadcast();
  @override
  Stream<VoiceSessionStatus> get statusStream => _statusController.stream;

  final StreamController<ChatMessage> _transcriptController =
      StreamController<ChatMessage>.broadcast();
  @override
  Stream<ChatMessage> get transcriptStream => _transcriptController.stream;

  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerStreamSubscription;

  @override
  Future<void> startSession(String url) async {
    _statusController.add(VoiceSessionStatus.connecting);

    try {
      final initialized = await AudioHardwareManager.instance.initialize();
      if (!initialized) {
        _statusController.add(VoiceSessionStatus.error);
        return;
      }

      _socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 10));

      final handshake = {
        'type': 'session.update',
        'session': {
          'modalities': ['audio', 'text'],
          'instructions':
              'You are a helpful first aid assistant. Respond only in Amharic.',
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'turn_detection': {'type': 'server_vad'},
        },
      };
      _socket?.add(jsonEncode(handshake));

      _socket?.listen(
        (data) => _handleWebSocketMessage(data),
        onError: (err) => _statusController.add(VoiceSessionStatus.error),
        onDone: () => stopSession(),
      );

      await _player.initialize();
      _player.play();

      _playerStreamSubscription = _player.alignedStream.listen((data) {
        _calculateAudioLevel(data);
      });

      await _startRecording();
      _statusController.add(VoiceSessionStatus.connected);
    } catch (e) {
      _statusController.add(VoiceSessionStatus.error);
    }
  }

  @override
  Future<void> stopSession() async {
    _recorderSubscription?.cancel();
    _playerStreamSubscription?.cancel();
    await _recorder.stop();
    await _player.stop();
    await _socket?.close();
    await AudioHardwareManager.instance.dispose();
    _socket = null;
    _statusController.add(VoiceSessionStatus.disconnected);
  }

  void _handleWebSocketMessage(dynamic data) {
    if (data is String) {
      final Map<String, dynamic> message = jsonDecode(data);
      final type = message['type'];

      if (type == 'response.audio.delta') {
        final base64Audio = message['delta'];
        if (base64Audio != null) {
          _player.feed(base64Decode(base64Audio));
        }
      } else if (type ==
          'conversation.item.input_audio_transcription.completed') {
        final text = message['transcript'];
        if (text != null) {
          final chatMsg = ChatMessage(isUser: true, text: text);
          _transcriptController.add(chatMsg);
          StorageService.instance.saveChatMessage(chatMsg);
        }
      } else if (type == 'response.audio_transcript.done') {
        final text = message['transcript'];
        if (text != null) {
          final chatMsg = ChatMessage(isUser: false, text: text);
          _transcriptController.add(chatMsg);
          StorageService.instance.saveChatMessage(chatMsg);
        }
      }
    }
  }

  Future<void> _startRecording() async {
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final stream = await _recorder.startStream(config);
    _recorderSubscription = stream.listen((data) {
      if (_player.isPlaying) _detectBargeIn(data);
      _socket?.add(
        jsonEncode({
          'type': 'input_audio_buffer.append',
          'audio': base64Encode(data),
        }),
      );
    });
  }

  void _calculateAudioLevel(Uint8List data) {
    if (data.length < 2) return;
    double sum = 0;
    int samples = data.length ~/ 2;
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < samples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sum += sample * sample;
    }
    final rms = math.sqrt(sum / samples);
    _audioLevelController.add((rms / 4000.0).clamp(0.0, 1.0));
  }

  void _detectBargeIn(Uint8List data) {
    double sum = 0;
    for (int i = 0; i < data.length; i += 2) {
      if (i + 1 < data.length) {
        sum += ByteData.sublistView(
          data,
          i,
          i + 2,
        ).getInt16(0, Endian.little).abs();
      }
    }
    if ((sum / (data.length / 2)) > 1500) {
      _socket?.add(jsonEncode({'type': 'response.cancel'}));
      _player.stop();
      _player.initialize().then((_) => _player.play());
    }
  }

  @override
  void dispose() {
    _audioLevelController.close();
    _statusController.close();
    _transcriptController.close();
    _recorder.dispose();
    _player.dispose();
  }
}
