import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioHardwareManager {
  static final AudioHardwareManager _instance =
      AudioHardwareManager._internal();
  static AudioHardwareManager get instance => _instance;

  AudioHardwareManager._internal();

  AudioSession? _session;

  Future<bool> initialize() async {
    // 1. Request Microphone Permissions
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    // 2. Configure Audio Session for Play-and-Record with Bluetooth support
    _session = await AudioSession.instance;
    await _session!.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
      ),
    );

    // 3. Activate the session
    return await _session!.setActive(true);
  }

  Future<void> dispose() async {
    if (_session != null) {
      await _session!.setActive(false);
      _session = null;
    }
  }
}
