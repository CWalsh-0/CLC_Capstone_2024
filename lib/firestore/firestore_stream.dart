import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to get a Firestore stream for the default HA collection
  Stream<DocumentSnapshot> getDocumentStream(String documentId) {
    return _db.collection('homeassistant').doc(documentId).snapshots();
  }

  // Function to get a Firestore stream for the default HA collection
  Stream<DocumentSnapshot> getRFIDStream(String documentId) {
    return _db.collection('RFUID_Readers').doc(documentId).snapshots();
  }

  // Function to get a Firestore stream for a specific collection type and object
  Stream<DocumentSnapshot> getCollectionDocStream(
      String collection, String documentId) {
    return _db.collection(collection).doc(documentId).snapshots();
  }

  void updateStreamStatus(String documentId, String newStatus) {
    _db
        .collection('homeassistant')
        .doc(documentId)
        .update({'status': newStatus});
  }
}
