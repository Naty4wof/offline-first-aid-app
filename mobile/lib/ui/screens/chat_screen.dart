import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/features/guides/domain/services/chat_service.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';
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

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      isUser: false,
      text: 'እንኳን ደህና መጡ። የአደጋ ሁኔታውን ይጻፉ ወይም በድምፅ ያስገቡ።',
      isImportant: false,
    ),
  ];

  late final ChatService _chatService;
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final AnimationController _typingController;
  List<String> _suggestions = const ['ቃጠሎ', 'ደም መደምሰስ', 'መታፈን'];

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
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
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _sendMessage(widget.initialMessage!);
          }
        });
      }
    });
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // load persisted chat history if any
    try {
      final stored = StorageService.instance.getChatMessages();
      if (stored.isNotEmpty) {
        _messages.clear();
        _messages.addAll(stored);
        // ensure list shows last message
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      // ignore storage errors for now
    }
  }

  Future<void> _sendMessage(String input) async {
    final text = input.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
    });
    // persist user message
    try {
      StorageService.instance.saveChatMessage(
        ChatMessage(isUser: true, text: text),
      );
    } catch (_) {}

    _controller.clear();
    _scrollToBottom();

    // Quick local intents: greetings, thanks, help — respond immediately in Amharic
    final lower = text.toLowerCase();
    final greetings = ['hi', 'hello', 'hey', 'ሰላም', 'ሰላምታ'];
    final thanks = ['thanks', 'thank you', 'thx', 'አመሰግናለሁ', 'እግዚአብሔር'];
    final help = ['help', 'assist', 'support', 'እርዳታ', 'እገዛ'];

    bool _containsAny(List<String> words) =>
        words.any((w) => lower.contains(w));

    // Show a typing indicator for 2 seconds before responding
    setState(() => _isTyping = true);
    _scrollToBottom();
    await Future.delayed(const Duration(seconds: 2));

    if (_containsAny(greetings)) {
      final msg = const ChatMessage(
        isUser: false,
        text: 'ሰላም! እንኳን ደህና መጡ። እባክዎ የአደጋውን ሁኔታ ይጻፉ ወይም ከሚሰጡ ምርጫዎች አንዱን ይምረጡ።',
        isImportant: false,
      );
      setState(() => _messages.add(msg));
      try {
        StorageService.instance.saveChatMessage(msg);
      } catch (_) {}
      setState(() => _isTyping = false);
      _scrollToBottom();
      return;
    }

    if (_containsAny(thanks)) {
      final msg = const ChatMessage(
        isUser: false,
        text: 'እናመሰግናለን — ይህ እንደረገው ደግሞ እንደሚፈልጉ እንደሚሆን ይጠይቁ።',
        isImportant: false,
      );
      setState(() => _messages.add(msg));
      try {
        StorageService.instance.saveChatMessage(msg);
      } catch (_) {}
      setState(() => _isTyping = false);
      _scrollToBottom();
      return;
    }

    if (_containsAny(help)) {
      final msg = const ChatMessage(
        isUser: false,
        text: 'እባክዎ የእርዳታ ዓይነት ይገልጹ — ለምሳሌ "ደም መደምሰስ" ወይም "ቃጠሎ" ይጻፉ።',
        isImportant: false,
      );
      setState(() => _messages.add(msg));
      try {
        StorageService.instance.saveChatMessage(msg);
      } catch (_) {}
      setState(() => _isTyping = false);
      _scrollToBottom();
      return;
    }

    final result = await _chatService.match(text);

    if (result.injury == null) {
      final buffer = StringBuffer();
      buffer.writeln('ይቅርታ — የሚመሳሰሉ ጉዳቶች በትክክል አልተገኙም። እነዚህን ይሞክሩ:');
      for (final s in result.suggestions) {
        buffer.writeln('• ${s.title}');
      }

      final msg = ChatMessage(
        isUser: false,
        text: buffer.toString(),
        isImportant: true,
      );
      setState(() => _messages.add(msg));
      try {
        StorageService.instance.saveChatMessage(msg);
      } catch (_) {}
      setState(() => _isTyping = false);
      _scrollToBottom();
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

    if (result.suggestions.isNotEmpty) {
      buffer.writeln('\nተመሳሳይ ጉዳቶች:');
      for (final s in result.suggestions) {
        buffer.writeln('• ${s.title}');
      }
      setState(
        () => _suggestions = result.suggestions.map((s) => s.title).toList(),
      );
    }

    final msg = ChatMessage(
      isUser: false,
      text: buffer.toString(),
      isImportant: true,
    );
    setState(() {
      _messages.add(msg);
      _isTyping = false;
    });
    try {
      StorageService.instance.saveChatMessage(msg);
    } catch (_) {}
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
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
                labels: _suggestions,
                onTap: (s) => _sendMessage(s),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            // typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Color(0xFF6B7880),
                        ),
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _typingController,
                          builder: (context, child) {
                            final t = (_typingController.value * 3).floor() + 1;
                            final dots = List.filled(t, '.').join();
                            return Text(
                              dots,
                              style: const TextStyle(
                                color: Color(0xFF6B7880),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
