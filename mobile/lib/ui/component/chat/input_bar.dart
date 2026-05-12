import 'package:flutter/material.dart';
import 'circle_action_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class InputBar extends StatefulWidget {
  const InputBar({
    required this.controller,
    required this.onSend,
    required this.onMicTap,
    super.key,
  });

  final TextEditingController controller;
  final void Function(String) onSend;
  final VoidCallback onMicTap;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) {
          debugPrint('onError: $val');
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
          onResult: (val) => setState(() {
            widget.controller.text = val.recognizedWords;
          }),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.onSend,
              decoration: InputDecoration(
                hintText: 'የአደጋ ሁኔታ ይጻፉ...',
                filled: true,
                fillColor: const Color(0xFFF1F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: _isListening ? Icons.mic : Icons.mic_none,
            background: _isListening
                ? Colors.red.shade50
                : const Color(0xFFF2F6F8),
            iconColor: _isListening ? Colors.red : const Color(0xFF5F6F75),
            onTap: () {
              widget.onMicTap();
              _listen();
            },
          ),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: Icons.send_rounded,
            background: const Color(0xFFE8F4ED),
            iconColor: const Color(0xFF2E9B59),
            onTap: () => widget.onSend(widget.controller.text),
          ),
        ],
      ),
    );
  }
}
