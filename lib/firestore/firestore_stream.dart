import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> saveUserToFirestore(String firstName, String lastName) async {
    User? user = FirebaseAuth.instance.currentUser; // Get current user
    if (user != null) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userRef.set(
          {
            'uid': user.uid,
            'email': user.email,
            'firstName': firstName,
            'lastName': lastName,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(
              merge: true)); // merge: true avoids overwriting existing fields
    }
  }
}
