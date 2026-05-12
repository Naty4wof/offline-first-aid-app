import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_first_aid_app/ui/component/chat/chat_message.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Future<void> init() async {
    await Hive.openBox('chat_history');
    await Hive.openBox('user');
  }

  // Chat history (store as simple Map entries)
  Future<void> saveChatMessage(ChatMessage msg) async {
    final box = Hive.box('chat_history');
    await box.add({
      'isUser': msg.isUser,
      'text': msg.text,
      'isImportant': msg.isImportant,
      'ts': DateTime.now().toIso8601String(),
    });
  }

  List<ChatMessage> getChatMessages() {
    final box = Hive.box('chat_history');
    return box.values
        .map((dynamic m) {
          try {
            return ChatMessage(
              isUser: m['isUser'] as bool,
              text: m['text'] as String,
              isImportant: m['isImportant'] as bool? ?? false,
            );
          } catch (_) {
            return ChatMessage(isUser: false, text: m.toString());
          }
        })
        .toList()
        .cast<ChatMessage>();
  }

  Future<void> clearChatHistory() async {
    final box = Hive.box('chat_history');
    await box.clear();
  }

  // Simple user profile storage
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final box = Hive.box('user');
    await box.put('profile', profile);
  }

  Map<String, dynamic>? getUserProfile() {
    final box = Hive.box('user');
    final v = box.get('profile');
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  bool hasUserProfile() {
    final box = Hive.box('user');
    return box.containsKey('profile');
  }

  bool hasSeenWelcome() {
    final box = Hive.box('user');
    return box.get('has_seen_welcome') == true;
  }

  Future<void> setHasSeenWelcome() async {
    final box = Hive.box('user');
    await box.put('has_seen_welcome', true);
  }
}
