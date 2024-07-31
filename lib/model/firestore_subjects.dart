import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class FirestoreSubjects {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collection = 'subjects';

  static Future<List<String>> getSubjects() async {
    QuerySnapshot querySnapshot = await _firestore.collection(uid).doc(_collection).collection('items').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  static Future<void> addSubject(String subject) async {
    await _firestore.collection(uid).doc(_collection).collection('items').doc(subject).set({});
  }

  static Future<void> deleteSubject(String subject) async {
    await _firestore.collection(uid).doc(_collection).collection('items').doc(subject).delete();
  }

  static Future<bool> subjectExists(String subject) async {
    DocumentSnapshot doc = await _firestore.collection(uid).doc(_collection).collection('items').doc(subject).get();
    return doc.exists;
  }
}