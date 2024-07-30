import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSubject(String username, String subjectName) async {
    DocumentReference documentReference =
        _firestore.collection(username).doc('subjects');

    await documentReference.set({
      subjectName: [],
    }, SetOptions(merge: true));
  }

  Future<List<String>> getAllSubjects(String username) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(username).doc('subjects').get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      return data.keys.toList();
    } else {
      return [];
    }
  }

  Future<void> deleteSubject(String username, String subjectName) async {
    DocumentReference documentReference =
        _firestore.collection(username).doc('subjects');

    await documentReference.update({
      subjectName: FieldValue.delete(),
    });
  }

  Future<void> addUuidToSubject(String username, String subjectName, String uuid) async {
    DocumentReference documentReference =
        _firestore.collection(username).doc('subjects');

    await documentReference.update({
      subjectName: FieldValue.arrayUnion([uuid]),
    });
  }

  Future<List<String>> getSubjectUuids(String username, String subjectName) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(username).doc('subjects').get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      return List<String>.from(data[subjectName] ?? []);
    } else {
      return [];
    }
  }
}