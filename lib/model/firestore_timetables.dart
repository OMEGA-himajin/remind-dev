import 'package:cloud_firestore/cloud_firestore.dart';

class Timetable {
  bool enableSat;  bool enableSun;
  List<String> mon;
  List<String> tue;
  List<String> wed;
  List<String> thu;
  List<String> fri;
  List<String> sat;
  List<String> sun;
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
      mon: List<String>.from(map['mon'] ?? List.filled(10, '')),
      tue: List<String>.from(map['tue'] ?? List.filled(10, '')),
      wed: List<String>.from(map['wed'] ?? List.filled(10, '')),
      thu: List<String>.from(map['thu'] ?? List.filled(10, '')),
      fri: List<String>.from(map['fri'] ?? List.filled(10, '')),
      sat: List<String>.from(map['sat'] ?? List.filled(10, '')),
      sun: List<String>.from(map['sun'] ?? List.filled(10, '')),
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
      day: FieldValue.arrayRemove([null])
    };
    await documentReference.update(updateData);
    
    List<String> daySubjects = List<String>.filled(10, '');
    DocumentSnapshot documentSnapshot = await documentReference.get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      daySubjects = List<String>.from(data[day] ?? List.filled(10, ''));
    }
    
    if (index < daySubjects.length) {
      daySubjects[index] = value;
    } else {
      while (daySubjects.length <= index) {
        daySubjects.add('');
      }
      daySubjects[index] = value;
    }
    
    updateData = {
      day: daySubjects
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