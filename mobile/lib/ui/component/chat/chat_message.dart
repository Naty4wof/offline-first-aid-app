class ChatMessage {
  const ChatMessage({
    required this.isUser,
    required this.text,
    this.isImportant = false,
  });

  final bool isUser;
  final String text;
  final bool isImportant;
}
