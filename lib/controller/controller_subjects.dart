// import '../model/firestore_subjects.dart';
// import '../main.dart';

// class SubjectsController {
//   final SubjectsRepository _subjectsRepository = SubjectsRepository();

//   Future<List<String>> getAllSubjects() async {
//     return await _subjectsRepository.getAllSubjects(uid);
//   }

//   Future<void> addSubject(String subjectName) async {
//     await _subjectsRepository.addSubject(uid, subjectName);
//   }

//   Future<void> deleteSubject(String subjectName) async {
//     await _subjectsRepository.deleteSubject(uid, subjectName);
//   }

//   Future<bool> subjectExists(String subjectName) async {
//     List<String> subjects = await getAllSubjects();
//     return subjects.contains(subjectName);
//   }
// }
