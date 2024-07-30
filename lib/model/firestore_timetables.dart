import 'package:cloud_firestore/cloud_firestore.dart';

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

  static Timetable fromMap(Map<String, dynamic> map) {
    return Timetable(
      enableSat: map['enable_sat'] ?? true,
      enableSun: map['enable_sun'] ?? true,
      mon: List<dynamic>.from(map['mon'] ?? []),
      tue: List<dynamic>.from(map['tue'] ?? []),
      wed: List<dynamic>.from(map['wed'] ?? []),
      thu: List<dynamic>.from(map['thu'] ?? []),
      fri: List<dynamic>.from(map['fri'] ?? []),
      sat: List<dynamic>.from(map['sat'] ?? []),
      sun: List<dynamic>.from(map['sun'] ?? []),
      times: map['times'] ?? 6,
    );
  }
}

class TimetableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Timetable?> getTimetable(String username) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(username).doc('timetables').get();

    if (documentSnapshot.exists) {
      return Timetable.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateTimetable(String username, Timetable timetable) async {
    DocumentReference documentReference =
        _firestore.collection(username).doc('timetables');
    await documentReference.set(timetable.toMap(), SetOptions(merge: true));
  }

  Future<void> updateDaySubject(String username, String day, int index, String value) async {
    DocumentReference documentReference = _firestore.collection(username).doc('timetables');
    Map<String, dynamic> updateData = {
      day: FieldValue.arrayRemove([{index.toString(): FieldValue.delete()}])
    };
    await documentReference.update(updateData);
    
    updateData = {
      day: FieldValue.arrayUnion([{index.toString(): value}])
    };
    await documentReference.update(updateData);
  }

  Future<void> updateTimes(String username, int times) async {
    DocumentReference documentReference = _firestore.collection(username).doc('timetables');
    await documentReference.update({'times': times});
  }

  Future<void> updateSaturdayEnabled(String username, bool enabled) async {
    DocumentReference documentReference = _firestore.collection(username).doc('timetables');
    await documentReference.update({'enable_sat': enabled});
  }

  Future<void> updateSundayEnabled(String username, bool enabled) async {
    DocumentReference documentReference = _firestore.collection(username).doc('timetables');
    await documentReference.update({'enable_sun': enabled});
  }
}