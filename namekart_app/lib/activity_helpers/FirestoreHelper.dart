import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../database/HiveHelper.dart';

Future<void> addDataToFirestore(String collectionPath, String docName, Map<String, dynamic> data) async {
  try {
    await FirebaseFirestore.instance.collection(collectionPath).doc(docName).set(data);
    print("✅ Data added successfully to Firestore!");
  } catch (e) {
    print("❌ Error adding data to Firestore: $e");
  }
}
Future<List<String>> getSubCollectionNames(String parentCollection) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the subcollections dynamically
    List<String> subCollections = [];


    var collections = await firestore.collection(parentCollection).get();

    for (var doc in collections.docs) {
      subCollections.add(doc.id);
    }

    return subCollections;
  } catch (e) {
    print("Error fetching subcollection names: $e");
    return [];
  }
}
Future<Map<String, dynamic>> getDocumentsInfo(String collectionPath) async {
  try {
    // Get reference to the collection
    final collectionRef = FirebaseFirestore.instance.collection(collectionPath);

    // Get all documents
    QuerySnapshot querySnapshot = await collectionRef.get();

    // Get total count
    int totalCount = querySnapshot.docs.length;

    // Get list of document names (IDs)
    List<String> documentNames = querySnapshot.docs.map((doc) => doc.id).toList();

    return {
      'totalCount': totalCount,
      'documentNames': documentNames,
    };
  } catch (e) {
    print('Error getting documents info: $e');
    return {
      'totalCount': 0,
      'documentNames': [],
      'error': e.toString(),
    };
  }
}

Future<void> deleteDocumentsFromPath(
    String basePath, // Example: "mainType/subType/parentDoc"
    List<String> docIds, // Document IDs you want to delete
    ) async {
  try {
    final batch = FirebaseFirestore.instance.batch();

    for (String docId in docIds) {
      final docRef = FirebaseFirestore.instance
          .collection('$basePath')
          .doc(docId);
      batch.delete(docRef);
    }

    await batch.commit();
    print("✅ Successfully deleted ${docIds.length} documents from $basePath");
  } catch (e) {
    print("❌ Error deleting documents: $e");
  }
}


Future<void> deleteAllDocumentsInPath(String collectionPath) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection(collectionPath);
    final querySnapshot = await collectionRef.get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No documents to delete in $collectionPath.");
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print("✅ Deleted all (${querySnapshot.docs.length}) documents in $collectionPath.");
  } catch (e) {
    print("❌ Error deleting all documents in $collectionPath: $e");
  }
}


Future<void> deleteCollection(String collectionPath) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection(collectionPath);
    final querySnapshot = await collectionRef.get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ Collection $collectionPath is already empty.");
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print("✅ Collection $collectionPath deleted successfully.");
  } catch (e) {
    print("❌ Error deleting collection $collectionPath: $e");
  }
}




Future<void> getFullDatabaseForPath(String path) async {
  try {
    final collectionPath = path.replaceAll("~", "/");

    // 🧹 Step 1: Clear existing local Hive data for the path
    await HiveHelper.delete(path);
    print("🗑️ Cleared local Hive data for path: $path");

    // 🔄 Step 2: Fetch all documents from Firestore, ordered by ID
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('id')
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No documents found in Firestore at $collectionPath.");
      return;
    }

    // 📝 Step 3: Add all documents to Hive
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final docId = data['id']?.toString();

      if (docId == null) {
        print("⚠️ Skipped document without valid 'id' field: ${doc.id}");
        continue;
      }

      try {
        await HiveHelper.add(path, docId, data);
        print("✅ Synced ID $docId to Hive from $path.");
      } catch (e) {
        print("⚠️ Failed to add ID $docId to Hive: $e");
      }
    }

    print("✅ Hive sync complete for $path. Total: ${querySnapshot.docs.length} documents.");
  } catch (e) {
    print("❌ Error syncing data from Firestore to Hive for $path: $e");
  }
}


Future<bool> syncFirestoreFromDocIdRange(String path, int startingId, int endingId) async {
  try {
    final collectionPath = path.replaceAll("~", "/");

    // Lexicographically fetch docs with IDs between startingId and endingId
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy(FieldPath.documentId)
        .startAfter([startingId.toString()])
        .endAt([endingId.toString()])
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No documents found in Firestore for $collectionPath in ID range ($startingId, $endingId].");
      return true;
    }

    for (var doc in querySnapshot.docs) {
      final docIdStr = doc.id;
      final numericDocId = int.tryParse(docIdStr);

      // ✅ Only process documents strictly within numeric range
      if (numericDocId == null || numericDocId <= startingId || numericDocId > endingId) {
        print("⏩ Skipping doc ID $docIdStr (parsed: $numericDocId) - out of range.");
        continue;
      }

      final data = doc.data();

      try {
        await HiveHelper.add(path, docIdStr, data);
        print("✅ Synced doc ID $docIdStr to Hive from $path.");
      } catch (e) {
        print("⚠️ Failed to add doc ID $docIdStr to Hive: $e");
      }
    }

    print("✅ Sync of range ($startingId, $endingId] complete for $path.");
    return true;
  } catch (e) {
    print("❌ Error syncing from Firestore to Hive for $path: $e");
    return false;
  }
}
