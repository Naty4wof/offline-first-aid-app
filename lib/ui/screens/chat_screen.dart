import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/features/guides/domain/services/chat_service.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import '../component/chat/chat_message.dart';
import '../component/chat/message_bubble.dart';
import '../component/chat/suggestion_chips.dart';
import '../component/chat/input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      isUser: false,
      text: 'እንኳን ደህና መጡ። የአደጋ ሁኔታውን ይጻፉ ወይም በድምፅ ያስገቡ።',
      isImportant: false,
    ),
  ];

  late final ChatService _chatService;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // ChatService needs repository; access via GuideBloc provided at app root
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<GuideBloc>().repository;
      _chatService = ChatServiceImpl(repo);

      if (widget.initialMessage != null &&
          widget.initialMessage!.trim().isNotEmpty) {
        _sendMessage(widget.initialMessage!);
      }
    });
  }

  Future<void> _sendMessage(String input) async {
    final text = input.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
    });

    _controller.clear();

    // Quick local intents: greetings, thanks, help — respond immediately in Amharic
    final lower = text.toLowerCase();
    final greetings = ['hi', 'hello', 'hey', 'ሰላም', 'ሰላምታ'];
    final thanks = ['thanks', 'thank you', 'thx', 'አመሰግናለሁ', 'እግዚአብሔር'];
    final help = ['help', 'assist', 'support', 'እርዳታ', 'እገዛ'];

    bool _containsAny(List<String> words) =>
        words.any((w) => lower.contains(w));

    if (_containsAny(greetings)) {
      setState(() {
        _messages.add(
          const ChatMessage(
            isUser: false,
            text:
                'ሰላም! እንኳን ደህና መጡ። እባክዎ የአደጋውን ሁኔታ ይጻፉ ወይም ከሚሰጡ ምርጫዎች አንዱን ይምረጡ።',
            isImportant: false,
          ),
        );
      });
      return;
    }

    if (_containsAny(thanks)) {
      setState(() {
        _messages.add(
          const ChatMessage(
            isUser: false,
            text: 'እናመሰግናለን — ይህ እንደረገው ደግሞ እንደሚፈልጉ እንደሚሆን ይጠይቁ።',
            isImportant: false,
          ),
        );
      });
      return;
    }

    if (_containsAny(help)) {
      setState(() {
        _messages.add(
          const ChatMessage(
            isUser: false,
            text: 'እባክዎ የእርዳታ ዓይነት ይገልጹ — ለምሳሌ "ደም መደምሰስ" ወይም "ቃጠሎ" ይጻፉ።',
            isImportant: false,
          ),
        );
      });
      return;
    }

    final result = await _chatService.match(text);

    if (result.injury == null) {
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text:
                'ይቅርታ — የሚመሳሰሉ ጉዳቶች አልተገኙም። እባክዎ በተለዋዋጭ ቃላት ይሞክሩ ወይም ከሚሰጡ ምርጫዎች አንዱን ይምረጡ።',
            isImportant: true,
          ),
        );
      });
      return;
    }

    // format response: injury name + steps
    final buffer = StringBuffer();
    buffer.writeln('የተመረጠ: ${result.injury!.title}');
    if (result.steps.isNotEmpty) {
      for (var i = 0; i < result.steps.length; i++) {
        buffer.writeln('${i + 1}) ${result.steps[i]}');
      }
    } else {
      buffer.writeln('ለዚህ ጉዳት ዝርዝር እርምጃዎች አልተገኙም።');
    }

    setState(() {
      _messages.add(
        ChatMessage(isUser: false, text: buffer.toString(), isImportant: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        title: const Text('የአደጋ እርዳታ ውይይት'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF132125),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: SuggestionChips(
                labels: const ['ሕፃን መታፈን', 'ከፍተኛ የደም መደምሰስ'],
                onTap: (s) => _sendMessage(s),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            InputBar(
              controller: _controller,
              onSend: _sendMessage,
              onMicTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('የድምፅ ግቤት በቅርቡ ይመጣል')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
