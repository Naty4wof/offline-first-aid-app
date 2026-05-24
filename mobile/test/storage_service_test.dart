import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';
import 'package:offline_first_aid_app/ui/component/chat/chat_message.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  group('StorageService (Hive) Tests', () {
    late StorageService storage;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      storage = StorageService.instance;
      await storage.init();
    });

    tearDown(() async {
      await Hive.close();
    });

    test('Chat history should save and retrieve correctly', () async {
      final msg = ChatMessage(
        isUser: true,
        text: 'I need help',
        isImportant: true,
      );
      await storage.saveChatMessage(msg);

      final history = storage.getChatMessages();
      expect(history.length, 1);
      expect(history.first.text, 'I need help');
      expect(history.first.isUser, true);
      expect(history.first.isImportant, true);
    });

    test('Chat history should clear correctly', () async {
      await storage.saveChatMessage(ChatMessage(isUser: true, text: 'Test'));
      await storage.clearChatHistory();
      expect(storage.getChatMessages().length, 0);
    });

    test('User profile should persist', () async {
      final profile = {'name': 'Jules', 'bloodType': 'O+'};
      await storage.saveUserProfile(profile);

      expect(storage.hasUserProfile(), isTrue);
      final retrieved = storage.getUserProfile();
      expect(retrieved?['name'], 'Jules');
      expect(retrieved?['bloodType'], 'O+');
    });

    test('Favorites should toggle correctly', () async {
      const injuryId = 'bleeding_severe';

      expect(storage.isFavorite(injuryId), isFalse);

      await storage.toggleFavorite(injuryId);
      expect(storage.isFavorite(injuryId), isTrue);
      expect(storage.getFavorites(), contains(injuryId));

      await storage.toggleFavorite(injuryId);
      expect(storage.isFavorite(injuryId), isFalse);
    });

    test('Welcome state should persist', () async {
      expect(storage.hasSeenWelcome(), isFalse);
      await storage.setHasSeenWelcome();
      expect(storage.hasSeenWelcome(), isTrue);
    });
  });
}
