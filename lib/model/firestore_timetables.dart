import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class FirestoreTimetables {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collection = 'timetables';

  static Future<Map<String, dynamic>> getTimetableData() async {
    DocumentSnapshot doc = await _firestore.collection(uid).doc(_collection).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      return {};
    }
  }

  static Future<void> updateTimetableData(Map<String, dynamic> newData) async {
    await _firestore.collection(uid).doc(_collection).set(newData, SetOptions(merge: true));
  }

  static Future<void> updateDaySubject(String day, int index, String subject) async {
    Map<String, dynamic> data = await getTimetableData();
    List<String> dayList = List<String>.from(data[day] ?? List.filled(10, ''));
    if (index < dayList.length) {
      dayList[index] = subject;
    } else {
      while (dayList.length <= index) {
        dayList.add('');
      }
      dayList[index] = subject;
    }
    await _firestore.collection(uid).doc(_collection).update({day: dayList});
  }

  static Future<void> updateTimes(int newTimes) async {
    await _firestore.collection(uid).doc(_collection).update({'times': newTimes});
  }

  static Future<void> updateSaturdayEnabled(bool enabled) async {
    await _firestore.collection(uid).doc(_collection).update({'enable_sat': enabled});
  }

  static Future<void> updateSundayEnabled(bool enabled) async {
    await _firestore.collection(uid).doc(_collection).update({'enable_sun': enabled});
  }

  static Future<bool> getSaturdayEnabled() async {
    DocumentSnapshot doc = await _firestore.collection(uid).doc(_collection).get();
    return (doc.data() as Map<String, dynamic>)['enable_sat'] ?? true;
  }

  static Future<bool> getSundayEnabled() async {
    DocumentSnapshot doc = await _firestore.collection(uid).doc(_collection).get();
    return (doc.data() as Map<String, dynamic>)['enable_sun'] ?? true;
  }
}