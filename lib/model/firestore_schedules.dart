import 'package:cloud_firestore/cloud_firestore.dart';

/// Eventを表現するクラス。
class Event {
  String color;
  String name;
  bool isAllday;
  Timestamp startDay;
  Timestamp endDay;

  /// コンストラクタ。
  Event({
    required this.color,
    required this.name,
    required this.isAllday,
    required this.startDay,
    required this.endDay,
  });

  /// EventをMap形式に変換するメソッド。
  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'name': name,
      'isAllday': isAllday,
      'startDay': startDay,
      'endDay': endDay,
    };
  }

  /// Map形式からEventを生成するファクトリメソッド。
  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      color: map['color'],
      name: map['name'],
      isAllday: map['isAllday'],
      startDay: map['startDay'],
      endDay: map['endDay'],
    );
  }
}

/// Taskを表現するクラス。
class Task {
  String color;
  String name;
  String content;
  String subject;

  /// コンストラクタ。
  Task({
    required this.color,
    required this.name,
    required this.content,
    required this.subject,
  });

  /// TaskをMap形式に変換するメソッド。
  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'name': name,
      'content': content,
      'subject': subject,
    };
  }

  /// Map形式からTaskを生成するファクトリメソッド。
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      color: map['color'],
      name: map['name'],
      content: map['content'],
      subject: map['subject'],
    );
  }
}

/// Firestoreを利用してEventとTaskを管理するリポジトリクラス。
class ScheduleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `uid`と`eventID`に基づいてEventを取得するメソッド。
  Future<Event?> getEvent(String uid, String eventID) async {
    DocumentSnapshot documentSnapshot = await _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .doc(eventID)
        .get();

    if (documentSnapshot.exists) {
      return Event.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// `uid`と`eventID`に基づいてEventを更新するメソッド。
  Future<void> updateEvent(
      String uid, String eventID, Map<String, dynamic> updates) async {
    DocumentReference documentReference = _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .doc(eventID);
    await documentReference.set(updates, SetOptions(merge: true));
  }

  /// 新しいEventを追加するメソッド。
  Future<String> addEvent(String uid, Event event) async {
    DocumentReference documentReference = await _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .add(event.toMap());
    return documentReference.id;
  }

  /// `uid`と`taskID`に基づいてTaskを取得するメソッド。
  Future<Task?> getTask(String uid, String taskID) async {
    DocumentSnapshot documentSnapshot = await _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .doc(taskID)
        .get();

    if (documentSnapshot.exists) {
      return Task.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// `uid`と`taskID`に基づいてTaskを更新するメソッド。
  Future<void> updateTask(
      String uid, String taskID, Map<String, dynamic> updates) async {
    DocumentReference documentReference = _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .doc(taskID);
    await documentReference.set(updates, SetOptions(merge: true));
  }

  /// 新しいTaskを追加するメソッド。
  Future<String> addTask(String uid, Task task) async {
    DocumentReference documentReference = await _firestore
        .collection(uid)
        .doc('schedule')
        .collection('events')
        .add(task.toMap());
    return documentReference.id;
  }
}
