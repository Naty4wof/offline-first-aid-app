import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:offline_first_aid_app/ui/screens/chat_screen.dart';

class FloatingMicButton extends StatefulWidget {
  const FloatingMicButton({
    required this.onLongPressStart,
    required this.onLongPressEnd,
    super.key,
  });

  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  State<FloatingMicButton> createState() => _FloatingMicButtonState();
}

class _FloatingMicButtonState extends State<FloatingMicButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listen(bool start) async {
    if (start) {
      bool available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('የድምፅ ስህተት: ${val.errorMsg}')),
            );
            setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(initialMessage: val.recognizedWords),
                ),
              );
            }
          },
          localeId: "am_ET",
          onDevice: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        widget.onLongPressStart(details);
        _listen(true);
      },
      onLongPressEnd: (details) {
        widget.onLongPressEnd(details);
        _listen(false);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = _isListening
              ? 1.0 + (_animationController.value * 0.15)
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: _isListening
                    ? const Color(0xFFE14949)
                    : const Color(0xFF2E9B59),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? const Color(0x66E14949)
                        : const Color(0x22000000),
                    blurRadius: _isListening ? 20 : 12,
                    spreadRadius: _isListening ? 4 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
