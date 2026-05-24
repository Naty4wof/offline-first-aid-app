import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../features/guides/domain/services/voice_live_service.dart';
import '../component/chat/chat_message.dart';

class VoiceLiveScreen extends StatefulWidget {
  const VoiceLiveScreen({super.key});

  @override
  State<VoiceLiveScreen> createState() => _VoiceLiveScreenState();
}

class _VoiceLiveScreenState extends State<VoiceLiveScreen>
    with SingleTickerProviderStateMixin {
  late final VoiceLiveService _voiceService;
  late final AnimationController _animationController;
  double _currentLevel = 0.0;
  VoiceSessionStatus _status = VoiceSessionStatus.disconnected;
  final List<ChatMessage> _liveTranscripts = [];

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceLiveServiceImpl();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _voiceService.audioLevelStream.listen((level) {
      if (mounted) {
        setState(() {
          _currentLevel = level;
        });
      }
    });

    _voiceService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    _voiceService.transcriptStream.listen((message) {
      if (mounted) {
        setState(() {
          _liveTranscripts.add(message);
        });
      }
    });

    _voiceService.startSession('wss://api.example.com/v1/realtime');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.stopSession();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'በድምፅ እርዳታ',
              style: TextStyle(
                color: Color(0xFF132125),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status == VoiceSessionStatus.connecting
                  ? 'በመገናኘት ላይ...'
                  : _status == VoiceSessionStatus.error
                  ? 'የግንኙነት ስህተት'
                  : _status == VoiceSessionStatus.connected
                  ? 'እያዳመጥኩ ነው...'
                  : 'ተቋርጧል',
              style: TextStyle(
                color: _status == VoiceSessionStatus.error
                    ? Colors.redAccent
                    : const Color(0xFF5F6F75),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _liveTranscripts.length,
                itemBuilder: (context, index) {
                  final msg = _liveTranscripts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${msg.isUser ? "እርስዎ: " : "ረዳት: "}${msg.text}',
                      style: TextStyle(
                        color: msg.isUser
                            ? const Color(0xFF132125)
                            : const Color(0xFF2E9B59),
                        fontSize: 14,
                        fontStyle: msg.isUser
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Waveform animation will go here
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: WaveformPainter(
                    animation: _animationController,
                    audioLevel: _currentLevel,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FloatingActionButton.large(
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final double audioLevel;

  WaveformPainter({required this.animation, required this.audioLevel})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E9B59).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;
    final scale = 1.0 + (audioLevel * 2.0);

    for (int i = 0; i < 3; i++) {
      final animValue = (animation.value + (i / 3)) % 1.0;
      final radius = baseRadius * scale * (1.0 + animValue);
      final opacity = (1.0 - animValue).clamp(0.0, 1.0);

      paint.color = const Color(0xFF2E9B59).withOpacity(opacity * 0.3);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw reacting inner circle
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF2E9B59).withOpacity(0.6);
    canvas.drawCircle(center, baseRadius * scale, paint);

    // Draw some "sound waves"
    final wavePaint = Paint()
      ..color = const Color(0xFF132125).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    for (double i = 0; i < size.width; i++) {
      final y =
          center.dy +
          math.sin(
                (i / size.width * 2 * math.pi) +
                    (animation.value * 2 * math.pi),
              ) *
              (20 * scale);
      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
