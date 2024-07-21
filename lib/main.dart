import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/home.dart';
import 'screens/items.dart';
import 'screens/schedule.dart' as schedule;
import 'screens/timetable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Firebase initialized successfully');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タイトル',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static final List<Widget> _screens = [
    const HomeScreen(),
    const TimeTableScreen(),
    const ItemsScreen(),
    const schedule.ScheduleScreen()
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.table_view), label: '時間割'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: '持ち物'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'スケジュール'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// データ管理のクラス
class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  Map<String, dynamic> _data = {};
  Map<String, List<Map<String, dynamic>>> _events = {};

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');
    if (jsonString != null) {
      _data = json.decode(jsonString);
    }

    String? eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      Map<String, dynamic> eventsMap = json.decode(eventsJson);
      _events = eventsMap.map((key, value) {
        return MapEntry(
          key,
          (value as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      });
    }
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(_data);
    await prefs.setString('timetable', jsonString);

    Map<String, dynamic> eventsMap = _events.map((key, value) {
      return MapEntry(key, value);
    });
    await prefs.setString('events', json.encode(eventsMap));
  }

  Map<String, dynamic> getData() {
    return _data;
  }

  void updateData(Map<String, dynamic> newData) {
    _data.addAll(newData);
    saveData();
  }

  Map<String, dynamic> getTimetableData() {
    return _data;
  }

  Future<void> updateTimetableData(Map<String, dynamic> newData) async {
    _data = newData;
    await saveData();
  }

  Future<void> addSubject(String subjectName) async {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    if (!subjects.contains(subjectName)) {
      subjects.add(subjectName);
      _data['sub'] = subjects;
      await saveData();
    }
  }

  Future<void> deleteSubject(String subjectName) async {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    subjects.remove(subjectName);
    _data['sub'] = subjects;
    await saveData();
  }

  bool subjectExists(String subjectName) {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    return subjects.contains(subjectName);
  }

  Future<void> updateTimes(int newTimes) async {
    _data['times'] = newTimes;
    await saveData();
  }

  Future<void> updateSaturdayEnabled(bool enabled) async {
    _data['enable_sat'] = enabled;
    await saveData();
  }

  Future<void> updateSundayEnabled(bool enabled) async {
    _data['enable_sun'] = enabled;
    await saveData();
  }

  Future<void> updateDaySubject(String day, int index, String subject) async {
    if (_data[day] == null) {
      _data[day] = List<String>.filled(10, '');
    }
    List<String> daySubjects = List<String>.from(_data[day]);
    if (index < daySubjects.length) {
      daySubjects[index] = subject;
    } else {
      while (daySubjects.length <= index) {
        daySubjects.add('');
      }
      daySubjects[index] = subject;
    }
    _data[day] = daySubjects;
    await saveData();
  }

  Future<void> updateAllTimetableData(Map<String, dynamic> newData) async {
    _data = newData;
    await saveData();
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    List<Map<String, dynamic>> events = [];
    String key = day.toIso8601String().split('T')[0];

    // 当日の予定を追加
    events.addAll(_events[key] ?? []);

    // multidayがtrueの予定も追加
    _events.forEach((dateKey, dateEvents) {
      dateEvents.forEach((event) {
        DateTime startDate = DateTime.parse(event['startDateTime']);
        DateTime endDate = DateTime.parse(event['endDateTime']);
        if (day.isAfter(startDate.subtract(Duration(days: 1))) &&
            day.isBefore(endDate.add(Duration(days: 1)))) {
          // 既に追加されていない場合のみ追加
          if (!events.any((e) => e['id'] == event['id'])) {
            events.add(event);
          }
        }
      });
    });

    return events;
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    String key = event['startDateTime'].split('T')[0];
    if (_events[key] == null) {
      _events[key] = [];
    }

    // multidayフラグを設定
    DateTime startDate = DateTime.parse(event['startDateTime']);
    DateTime endDate = DateTime.parse(event['endDateTime']);
    event['multiday'] = !isSameDay(startDate, endDate);

    _events[key]!.add(event);
    await saveData();
  }

  Future<void> updateEvent(
      String oldKey, Map<String, dynamic> updatedEvent) async {
    String newKey = updatedEvent['startDateTime'].split('T')[0];

    // 古いイベントを削除
    _events[oldKey]?.removeWhere((e) => e['id'] == updatedEvent['id']);
    if (_events[oldKey]?.isEmpty ?? false) {
      _events.remove(oldKey);
    }

    // multidayフラグを更新
    DateTime startDate = DateTime.parse(updatedEvent['startDateTime']);
    DateTime endDate = DateTime.parse(updatedEvent['endDateTime']);
    updatedEvent['multiday'] = !isSameDay(startDate, endDate);

    // 新しいイベントを追加
    if (_events[newKey] == null) {
      _events[newKey] = [];
    }
    _events[newKey]!.add(updatedEvent);

    await saveData();
  }

  Future<void> deleteEvent(String key, String eventId) async {
    _events[key]?.removeWhere((e) => e['id'] == eventId);
    if (_events[key]?.isEmpty ?? false) {
      _events.remove(key);
    }
    await saveData();
  }

  List<Map<String, dynamic>> getEventsForPeriod(DateTime start, DateTime end) {
    List<Map<String, dynamic>> events = [];
    for (DateTime day = start;
        day.isBefore(end.add(Duration(days: 1)));
        day = day.add(Duration(days: 1))) {
      events.addAll(getEventsForDay(day));
    }
    return events.toSet().toList(); // 重複を除去
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
