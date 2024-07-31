// import '../model/firestore_timetables.dart';
// import '../main.dart';

// class TimetableController {
//   final TimetableRepository _timetableRepository = TimetableRepository();

//   Future<Timetable> getTimetable() async {
//     return await _timetableRepository.getTimetable(uid) ??
//         Timetable(
//           enableSat: true,
//           enableSun: true,
//           mon: List.filled(10, ''),
//           tue: List.filled(10, ''),
//           wed: List.filled(10, ''),
//           thu: List.filled(10, ''),
//           fri: List.filled(10, ''),
//           sat: List.filled(10, ''),
//           sun: List.filled(10, ''),
//           times: 6,
//         );
//   }

//   Future<void> updateTimes(int times) async {
//     await _timetableRepository.updateTimes(uid, times);
//   }

//   Future<void> updateSaturdayEnabled(bool enabled) async {
//     await _timetableRepository.updateSaturdayEnabled(uid, enabled);
//   }

//   Future<void> updateSundayEnabled(bool enabled) async {
//     await _timetableRepository.updateSundayEnabled(uid, enabled);
//   }

//   Future<void> updateDaySubject(String day, int index, String value) async {
//     await _timetableRepository.updateDaySubject(uid, day, index, value);
//   }
// }
