import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';


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

Future<int?> getDocumentCount(String collectionPath) async {
  try {
    final query = FirebaseFirestore.instance.collection(collectionPath);
    final aggregateQuery = query.count();
    final aggregateSnapshot = await aggregateQuery.get();
    return aggregateSnapshot.count;
  } catch (e) {
    print("❌ Error getting document count: $e");
    return 0;
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
    await DbSqlHelper.delete(path);
    print("🗑️ Cleared local Hive data for path: $path");

    // 🔄 Step 2: Fetch all documents from Firestore, ordered by ID
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('datetime_id')
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No documents found in Firestore at $collectionPath.");
      return;
    }

    // 📝 Step 3: Add all documents to Hive
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final docId = data['datetime_id']?.toString();

      if (docId == null) {
        print("⚠️ Skipped document without valid 'id' field: ${doc.id}");
        continue;
      }

      try {
        await DbSqlHelper.addData(path, docId, data);
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


Future<bool> syncFirestoreFromDocIdTimestamp(
    String path,
    String lastTimestampDocId,
    bool update,
    ) async {
  try {
    final collectionPath = path.replaceAll("~", "/");

    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy(FieldPath.documentId)
        .startAfter([lastTimestampDocId]) // fetch strictly after
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No new documents found in Firestore for $collectionPath after $lastTimestampDocId.");
      return true;
    }

    for (var doc in querySnapshot.docs) {
      final docId = doc.id;
      final data = doc.data();

      try {
        if (update) {
          await DbSqlHelper.updateData(path, docId, data);
        } else {
          await DbSqlHelper.addData(path, docId, data);
        }
        print("✅ Synced doc ID $docId to Hive from $path.");
      } catch (e) {
        print("⚠️ Failed to add/update doc ID $docId to Hive: $e");
      }
    }

    print("✅ Sync complete for new docs after $lastTimestampDocId in $path.");
    return true;
  } catch (e) {
    print("❌ Error syncing from Firestore to Hive for $path: $e");
    return false;
  }
}

Future<List<Map<String, dynamic>>> getLatestDocuments(String path, {int limit = 10}) async {
  try {
    final collectionPath = path.replaceAll("~", "/");

    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('datetime_id', descending: true)
        .limit(limit)
        .get(); // 🔒 Reads only 'limit' documents

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No documents found in $collectionPath.");
      return [];
    }

    List<Map<String, dynamic>> latestDocs = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      latestDocs.add(data);
      DbSqlHelper.addData(path,data['id'],data);
    }

    print("✅ Retrieved ${latestDocs.length} latest documents from $path.");
    return latestDocs;
  } catch (e) {
    print("❌ Error fetching latest documents from $path: $e");
    return [];
  }
}

Future<List<Map<String, dynamic>>> get10BeforeTimestamp(String path, String beforeDatetimeId) async {
  try {
    final collectionPath = path.replaceAll("~", "/");

    // 👇 Query documents before the given datetime_id
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('datetime_id', descending: true)
        .where('datetime_id', isLessThan: beforeDatetimeId)
        .limit(10)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("ℹ️ No older documents found before $beforeDatetimeId in $collectionPath.");
      return [];
    }

    List<Map<String, dynamic>> result = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      try {
        await DbSqlHelper.addData(path, doc.id, data);
        result.add(data);
        print("✅ Synced doc ${doc.id} to Hive.");
      } catch (e) {
        print("⚠️ Failed to sync doc ${doc.id} to Hive: $e");
      }
    }

    print("✅ get10BeforeTimestamp() complete. Fetched ${result.length} documents.");
    return result;
  } catch (e) {
    print("❌ Error in get10BeforeTimestamp(): $e");
    return [];
  }
}


