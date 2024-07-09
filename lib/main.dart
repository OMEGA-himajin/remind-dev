import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/home.dart';
import 'screens/items.dart';
import 'screens/schedule.dart' as schedule;
import 'screens/timetable.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  // 時間割データの取得
  Map<String, dynamic> getTimetableData() {
    return _data;
  }

  // 時間割データの更新
  Future<void> updateTimetableData(Map<String, dynamic> newData) async {
    _data = newData;
    await saveData();
  }

  // 教科の追加
  Future<void> addSubject(String subjectName) async {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    if (!subjects.contains(subjectName)) {
      subjects.add(subjectName);
      _data['sub'] = subjects;
      await saveData();
    }
  }

  // 教科の削除
  Future<void> deleteSubject(String subjectName) async {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    subjects.remove(subjectName);
    _data['sub'] = subjects;
    await saveData();
  }

  // 教科の存在確認
  bool subjectExists(String subjectName) {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    return subjects.contains(subjectName);
  }

  // 時間数の更新
  Future<void> updateTimes(int newTimes) async {
    _data['times'] = newTimes;
    await saveData();
  }

  // 土曜日表示の更新
  Future<void> updateSaturdayEnabled(bool enabled) async {
    _data['enable_sat'] = enabled;
    await saveData();
  }

  // 日曜日表示の更新
  Future<void> updateSundayEnabled(bool enabled) async {
    _data['enable_sun'] = enabled;
    await saveData();
  }

  // 特定の曜日と時間の教科を更新
  Future<void> updateDaySubject(String day, int index, String subject) async {
    List<String> daySubjects = List<String>.from(_data[day] ?? []);
    if (index < daySubjects.length) {
      daySubjects[index] = subject;
    } else {
      daySubjects.add(subject);
    }
    _data[day] = daySubjects;
    await saveData();
  }

  // 全ての時間割データを更新
  Future<void> updateAllTimetableData(Map<String, dynamic> newData) async {
    _data = newData;
    await saveData();
  }

  // イベントの取得
  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    String key = day.toIso8601String().split('T')[0];
    return _events[key] ?? [];
  }

  // イベントの追加
  Future<void> addEvent(Map<String, dynamic> event) async {
    String key = event['startDateTime'].split('T')[0];
    if (_events[key] == null) {
      _events[key] = [];
    }
    _events[key]!.add(event);
    await saveData();
  }

  // イベントの更新
  Future<void> updateEvent(
      String oldKey, Map<String, dynamic> updatedEvent) async {
    String newKey = updatedEvent['startDateTime'].split('T')[0];

    // 古いイベントを削除
    _events[oldKey]?.removeWhere((e) => e['id'] == updatedEvent['id']);
    if (_events[oldKey]?.isEmpty ?? false) {
      _events.remove(oldKey);
    }

    // 新しいイベントを追加
    if (_events[newKey] == null) {
      _events[newKey] = [];
    }
    _events[newKey]!.add(updatedEvent);

    await saveData();
  }

  // イベントの削除
  Future<void> deleteEvent(String key, String eventId) async {
    _events[key]?.removeWhere((e) => e['id'] == eventId);
    if (_events[key]?.isEmpty ?? false) {
      _events.remove(key);
    }
    await saveData();
  }

  // 期間内のイベントを取得
  List<Map<String, dynamic>> getEventsForPeriod(DateTime start, DateTime end) {
    List<Map<String, dynamic>> events = [];
    for (DateTime day = start;
        day.isBefore(end.add(Duration(days: 1)));
        day = day.add(Duration(days: 1))) {
      String key = day.toIso8601String().split('T')[0];
      events.addAll(_events[key] ?? []);
    }
    return events;
  }
}

// 共通のUIコンポーネント
class CommonUI {
  static AppBar buildAppBar(String title) {
    return AppBar(
      title: Text(title),
    );
  }

  static Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          const DrawerHeader(
            child: Text('メニュー'),
          ),
          ListTile(
            title: const Text("ホーム"),
            trailing: const Icon(Icons.home),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("設定"),
            trailing: const Icon(Icons.settings),
            onTap: () {
              // 設定画面への遷移処理
            },
          ),
        ],
      ),
    );
  }
}