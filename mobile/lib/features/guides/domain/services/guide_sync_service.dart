import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class GuideSyncService {
  final firestore = FirebaseFirestore.instance;

  // ================= CATEGORIES =================

  Future<void> syncCategories() async {
    final snapshot = await firestore.collection('categories').get();

    final box = Hive.box('categories');

    for (final doc in snapshot.docs) {
      final data = doc.data();

      data['id'] = doc.id;

      await box.put(doc.id, data);
    }

    print("✅ Categories synced");
  }

  // ================= INJURIES =================

  Future<void> syncInjuries() async {
    final snapshot = await firestore.collection('injuries').get();

    final box = Hive.box('injuries');

    for (final doc in snapshot.docs) {
      final data = doc.data();

      data['id'] = doc.id;

      await box.put(doc.id, data);
    }

    print("✅ Injuries synced");
  }

  // ================= GUIDES =================

  Future<void> syncGuides() async {
    try {
      final snapshot = await firestore.collection('guides').get();

      final box = Hive.box('guides');

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // inject firestore id
        data['id'] = doc.id;

        // FIX FIRESTORE TIMESTAMP
        if (data['updatedAt'] != null &&
            data['updatedAt'] is Timestamp) {
          data['updatedAt'] =
              (data['updatedAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
        }

        print("SYNCING GUIDE:");
        print(data);

        await box.put(doc.id, data);
      }

      print("✅ Guides synced");
    } catch (e, stack) {
      print("❌ Guides sync failed");
      print(e);
      print(stack);
    }
  }

  // ================= ALL =================

  Future<void> syncAll() async {
    await syncCategories();
    await syncInjuries();
    await syncGuides();
  }
}