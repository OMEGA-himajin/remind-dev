import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreを利用してSubjectsを管理するリポジトリクラス。
class SubjectsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `uid`と`subjectName`に基づいてUUIDを追加するメソッド。
  Future<void> addSubject(String uid, String subjectName,
      {String? uuid}) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('subjects');

    DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      List<String> uuids = List<String>.from(data[subjectName] ?? []);
      if (uuid != null) {
        uuids.add(uuid);
      }
      await documentReference.update({subjectName: uuids});
    } else {
      await documentReference.set({
        subjectName: uuid != null ? [uuid] : [],
      });
    }
  }

  /// `uid`と`subjectName`に基づいてUUIDのリストを取得するメソッド。
  Future<List<String>> getSubject(String uid, String subjectName) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('subjects');

    DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return List<String>.from(data[subjectName] ?? []);
    } else {
      return [];
    }
  }

  /// `uid`と`subjectName`に基づいてUUIDを削除するメソッド。
  Future<void> removeSubject(
      String uid, String subjectName, String uuid) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('subjects');

    DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      List<String> uuids = List<String>.from(data[subjectName] ?? []);
      uuids.remove(uuid);
      await documentReference.update({subjectName: uuids});
    }
  }
}
