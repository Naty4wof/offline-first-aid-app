import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';

class PcmStreamPlayer {
  AudioSource? _audioSource;
  final List<int> _buffer = [];
  bool _isInitialized = false;
  SoundHandle? _handle;

  final StreamController<Uint8List> _alignedStreamController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get alignedStream => _alignedStreamController.stream;

  Future<void> initialize() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
    }
    _audioSource = SoLoud.instance.setBufferStream(
      sampleRate: 16000,
      channels: Channels.mono,
      format: BufferType.s16le,
    );
    _isInitialized = true;
  }

  void play() {
    if (_audioSource != null) {
      _handle = SoLoud.instance.play(_audioSource!);
    }
  }

  bool get isPlaying =>
      _handle != null && SoLoud.instance.getIsValidVoiceHandle(_handle!);

  void feed(Uint8List data) {
    if (!_isInitialized || _audioSource == null) return;

    // Even-Byte Guard: ensure we only pass 16-bit aligned samples (2 bytes)
    _buffer.addAll(data);

    if (_buffer.length >= 2) {
      final alignedLength = (_buffer.length ~/ 2) * 2;
      final alignedData = Uint8List.fromList(_buffer.sublist(0, alignedLength));
      _buffer.removeRange(0, alignedLength);

      SoLoud.instance.addAudioDataStream(_audioSource!, alignedData);
      _alignedStreamController.add(alignedData);
    }
  }

  Future<void> stop() async {
    if (_handle != null) {
      SoLoud.instance.stop(_handle!);
      _handle = null;
    }
    if (_audioSource != null) {
      _audioSource = null;
    }
    _buffer.clear();
    _isInitialized = false;
  }

  void dispose() {
    _alignedStreamController.close();
  }
}
