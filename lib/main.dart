import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/home.dart';
import 'screens/items.dart';
import 'screens/schedule.dart' as schedule;
import 'screens/timetable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? themeModeString = prefs.getString('themeMode');
  ThemeMode themeMode;
  if (themeModeString == 'ThemeMode.light') {
    themeMode = ThemeMode.light;
  } else if (themeModeString == 'ThemeMode.dark') {
    themeMode = ThemeMode.dark;
  } else {
    themeMode = ThemeMode.system;
  }
  runApp(MyApp(initialThemeMode: themeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeThemeMode(ThemeMode newThemeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = newThemeMode;
    });
    await prefs.setString('themeMode', newThemeMode.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タイトル',
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.white,
          surface: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.grey[900]!,
          surface: Colors.grey[800]!,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: MyStatefulWidget(onThemeModeChanged: _changeThemeMode),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const MyStatefulWidget({super.key, required this.onThemeModeChanged});

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

  void _showAddSubjectDialog(BuildContext context) async {
    TextEditingController textEditingController = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('教科を追加'),
              content: Container(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: _getSubjects(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }
                          List<String> subjects = snapshot.data!;
                          return ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              if (subjects[index].trim().isEmpty)
                                return Container();
                              return ListTile(
                                title: Text(
                                  subjects[index],
                                  style: TextStyle(color: Colors.black),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    await DataManager()
                                        .deleteSubject(subjects[index]);
                                    setDialogState(() {});
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: textEditingController,
                      decoration: const InputDecoration(
                        hintText: "教科名を入力してください",
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    String subjectName = textEditingController.text.trim();
                    if (subjectName.isNotEmpty &&
                        !await DataManager().subjectExists(subjectName)) {
                      await DataManager().addSubject(subjectName);
                      setDialogState(() {});
                      textEditingController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('教科を追加しました')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('すでに同じ名前の教科が存在するか空白です。')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getSubjects() async {
    await DataManager().loadData();
    Map<String, dynamic> timetableData = DataManager().getTimetableData();
    List<String> subjects = List<String>.from(
        timetableData['sub']?.map((subject) => subject.toString()) ?? []);
    subjects = subjects.where((subject) => subject.trim().isNotEmpty).toList();
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      drawer: _buildCommonDrawer(context),
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

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'ホーム';
      case 1:
        return '時間割';
      case 2:
        return '持ち物';
      case 3:
        return 'スケジュール';
      default:
        return '';
    }
  }

  Widget _buildCommonDrawer(BuildContext context) {
    ThemeMode currentThemeMode = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      currentThemeMode = ThemeMode.system;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'メニュー',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('テーマ', style: TextStyle(fontSize: 16)),
                DropdownButton<ThemeMode>(
                  value: currentThemeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      widget.onThemeModeChanged(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('システムテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('ライトテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('ダークテーマ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedIndex == 1) ...[
            Divider(),
            (_screens[1] as TimeTableScreen)
                .buildTimetableSpecificMenuItems(context),
          ],
        ],
      ),
    );
  }
}

class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  Map<String, dynamic> _data = {};
  Map<String, List<Map<String, dynamic>>> _events = {};

  Future<void> deleteSubject(String subjectName) async {
    List<String> subjects = List<String>.from(_data['sub'] ?? []);
    subjects.remove(subjectName);
    _data['sub'] = subjects;
    await saveData();
  }

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

  bool getSaturdayEnabled() {
    return _data['enable_sat'] ?? true;
  }

  bool getSundayEnabled() {
    return _data['enable_sun'] ?? true;
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

    events.addAll(_events[key] ?? []);

    _events.forEach((dateKey, dateEvents) {
      dateEvents.forEach((event) {
        DateTime startDate = DateTime.parse(event['startDateTime']);
        DateTime endDate = DateTime.parse(event['endDateTime']);
        if (day.isAtSameMomentAs(startDate) ||
            (day.isAfter(startDate) &&
                day.isBefore(endDate.add(Duration(days: 1))))) {
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

    DateTime startDate = DateTime.parse(event['startDateTime']);
    DateTime endDate = DateTime.parse(event['endDateTime']);
    event['multiday'] = !isSameDay(startDate, endDate);

    _events[key]!.add(event);
    await saveData();
  }

  Future<void> updateEvent(
      String oldKey, Map<String, dynamic> updatedEvent) async {
    String newKey = updatedEvent['startDateTime'].split('T')[0];

    _events[oldKey]?.removeWhere((e) => e['id'] == updatedEvent['id']);
    if (_events[oldKey]?.isEmpty ?? false) {
      _events.remove(oldKey);
    }

    DateTime startDate = DateTime.parse(updatedEvent['startDateTime']);
    DateTime endDate = DateTime.parse(updatedEvent['endDateTime']);
    updatedEvent['multiday'] = !isSameDay(startDate, endDate);

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
    return events.toSet().toList();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date2.day == date2.day;
  }
}
