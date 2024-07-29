import 'package:cloud_firestore/cloud_firestore.dart';

/// Timetableを表現するクラス。
class Timetable {
  bool enableSat;
  bool enableSun;
  List<dynamic> mon;
  List<dynamic> tue;
  List<dynamic> wed;
  List<dynamic> thu;
  List<dynamic> fri;
  List<dynamic> sat;
  List<dynamic> sun;
  int times;

  /// コンストラクタ。
  Timetable({
    required this.enableSat,
    required this.enableSun,
    required this.mon,
    required this.tue,
    required this.wed,
    required this.thu,
    required this.fri,
    required this.sat,
    required this.sun,
    required this.times,
  });

  /// TimetableをMap形式に変換するメソッド。
  Map<String, dynamic> toMap() {
    return {
      'enable_sat': enableSat,
      'enable_sun': enableSun,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
      'times': times,
    };
  }

  /// Map形式からTimetableを生成するファクトリメソッド。
  static Timetable fromMap(Map<String, dynamic> map) {
    return Timetable(
      enableSat: map['enable_sat'],
      enableSun: map['enable_sun'],
      mon: List<dynamic>.from(map['mon']),
      tue: List<dynamic>.from(map['tue']),
      wed: List<dynamic>.from(map['wed']),
      thu: List<dynamic>.from(map['thu']),
      fri: List<dynamic>.from(map['fri']),
      sat: List<dynamic>.from(map['sat']),
      sun: List<dynamic>.from(map['sun']),
      times: map['times'],
    );
  }
}

/// Firestoreを利用してTimetableを管理するリポジトリクラス。
class TimetableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `uid`に基づいてTimetableを取得するメソッド。
  Future<Timetable?> getTimetable(String uid) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(uid).doc('timetables').get();

    if (documentSnapshot.exists) {
      return Timetable.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// `uid`に基づいてTimetableを更新するメソッド。
  Future<void> updateTimetable(String uid, Map<String, dynamic> updates) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('timetables');
    await documentReference.set(updates, SetOptions(merge: true));
  }

  /// 新しいTimetableを追加するメソッド。
  Future<void> addTimetable(String uid, Timetable timetable) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('timetables');
    await documentReference.set(timetable.toMap());
  }
}
