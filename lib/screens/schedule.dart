import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Map<DateTime, List<Map<String, String>>> _events = {};
  late DateTime _selectedDay;
  late User _user; // Firebase User object
  late FirebaseFirestore _db; // Firestore instance
  bool _isLoading = true;
  List<String> subjects = [];

  bool _isAddingEvent = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeFirebase(); // Initialize Firebase dependencies
    _loadFirestoreData(); // Fetch subjects from Firestore
    _fetchEvents(); // Fetch events from Firestore
  }

  void _initializeFirebase() {
    _user = FirebaseAuth.instance.currentUser!; // Get current user
    _db = FirebaseFirestore.instance; // Initialize Firestore
  }

  Future<void> _loadFirestoreData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot document = await FirebaseFirestore.instance
            .collection('timetables')
            .doc(user.uid)
            .get();

        if (document.exists) {
          Map<String, dynamic> jsonData =
              document.data() as Map<String, dynamic>;

          setState(() {
            subjects = List<String>.from(
                jsonData['sub']?.map((subject) => subject.toString()) ?? []);
            subjects =
                subjects.where((subject) => subject.trim().isNotEmpty).toList();
          });
        }
      } catch (e) {
        print('Firestoreデータの読み込みエラー: $e');
      }
    }
  }

  Future<void> _fetchEvents() async {
    // Fetch events from Firestore for the current user
    try {
      final eventDoc = await _db.collection('events').doc(_user.uid).get();

      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          final DateTime date = DateTime.parse(key);
          final List<Map<String, String>> events =
              List<Map<String, String>>.from(
                  value.map((item) => Map<String, String>.from(item)));
          _events[date] = events;
        });
      } else {
        _events = {}; // Initialize with empty map if document doesn't exist
      }

      setState(() {
        _isLoading = false; // Data loading complete
      });
    } catch (error) {
      print("Failed to fetch events: $error");
      setState(() {
        _isLoading = false; // Set loading to false even on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スケジュール'),
      ),
      drawer: Drawer(
        child: ListView(
          children: const <Widget>[
            DrawerHeader(
              child: Text('メニュー'),
            ),
            ListTile(
              title: Text("ホーム"),
              trailing: Icon(Icons.home),
            ),
            ListTile(
              title: Text("設定"),
              trailing: Icon(Icons.settings),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          TableCalendar(
                            firstDay: DateTime.utc(2010, 1, 1),
                            lastDay: DateTime.utc(2030, 1, 1),
                            focusedDay: _selectedDay,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _isAddingEvent = true;
                              });
                            },
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                return _buildDayContainer(day, focusedDay);
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                return _buildDayContainer(day, focusedDay,
                                    isSelected: true);
                              },
                              todayBuilder: (context, day, focusedDay) {
                                return _buildDayContainer(day, focusedDay,
                                    isToday: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        bottom: _isAddingEvent ? 0 : -300,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity! > 0) {
                              setState(() {
                                _isAddingEvent = false;
                              });
                            }
                          },
                          child: Container(
                            height: 300,
                            padding: EdgeInsets.all(16.0),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '$_selectedDay の予定',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_events[_selectedDay] != null &&
                                    _events[_selectedDay]!.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8.0),
                                      Text(
                                        '予定時刻:',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.0),
                                      ..._events[_selectedDay]!.map((event) {
                                        if (event['type'] == 'event' &&
                                            event.containsKey('startTime') &&
                                            event.containsKey('endTime')) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Text(
                                              '${event['startTime']} 〜 ${event['endTime']}',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          );
                                        } else {
                                          return SizedBox.shrink();
                                        }
                                      }).toList(),
                                    ],
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount:
                                        _getEventsForDay(_selectedDay).length,
                                    itemBuilder: (context, index) {
                                      final event =
                                          _getEventsForDay(_selectedDay)[index];
                                      return Card(
                                        margin: EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: ListTile(
                                          title: Text(event['type'] == 'task'
                                              ? event['task']!
                                              : event['event']!),
                                          subtitle: event['type'] == 'task'
                                              ? Text('教科: ${event['subject']!}')
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                ElevatedButton(
                                  onPressed: () {
                                    _showAddEventDialog();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add),
                                      SizedBox(width: 8.0),
                                      Text('予定を追加'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(); // Corrected method call
        },
        child: Icon(Icons.add),
        tooltip: '追加',
      ),
    );
  }

  Widget _buildDayContainer(DateTime day, DateTime focusedDay,
      {bool isSelected = false, bool isToday = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16.0,
                color: isSelected
                    ? Colors.blue
                    : isToday
                        ? Colors.red
                        : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_events[day] != null)
                  ..._events[day]!.map((event) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.blue,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            event['type'] == 'task'
                                ? '${event['task']}'
                                : '${event['startTime']}~${event['event']}',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController _eventController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _startTimeController = TextEditingController();
    final TextEditingController _endTimeController = TextEditingController();
    String selectedType = 'event';
    String selectedSubject = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('予定を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: '追加する項目'),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        _eventController.clear();
                        _contentController.clear();
                        _startTimeController.clear();
                        _endTimeController.clear();
                        selectedSubject = '';
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                          value: 'event', child: Text('予定')),
                      DropdownMenuItem<String>(
                          value: 'task', child: Text('課題')),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  if (selectedType == 'event') ...[
                    TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(labelText: '予定名'),
                      // バリデーションとエラーメッセージの追加
                      onChanged: (value) {
                        setState(() {
                          // エラーメッセージをリセットする場合に利用
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? startTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (startTime != null) {
                          setState(() {
                            _startTimeController.text =
                                '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(labelText: '開始時刻'),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? endTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (endTime != null) {
                          setState(() {
                            _endTimeController.text =
                                '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(labelText: '終了時刻'),
                        ),
                      ),
                    ),
                  ] else if (selectedType == 'task') ...[
                    DropdownButtonFormField<String>(
                      value:
                          selectedSubject.isNotEmpty ? selectedSubject : null,
                      decoration: InputDecoration(labelText: '教科'),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSubject = newValue!;
                        });
                      },
                      items: subjects
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(labelText: '課題名'),
                      // バリデーションとエラーメッセージの追加
                      onChanged: (value) {
                        setState(() {
                          // エラーメッセージをリセットする場合に利用
                        });
                      },
                    ),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: '課題内容'),
                      maxLines: 3,
                      // バリデーションとエラーメッセージの追加
                      onChanged: (value) {
                        setState(() {
                          // エラーメッセージをリセットする場合に利用
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('追加'),
                onPressed: () {
                  if (_eventController.text.isEmpty ||
                      (selectedType == 'event' &&
                          (_startTimeController.text.isEmpty ||
                              _endTimeController.text.isEmpty)) ||
                      (selectedType == 'task' &&
                          (_eventController.text.isEmpty ||
                              selectedSubject.isEmpty ||
                              _contentController.text.isEmpty))) {
                    // エラーメッセージを表示する
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('入力項目を正しく入力してください'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _updateEvents(
                    _eventController.text,
                    selectedSubject,
                    selectedType,
                    _contentController.text,
                    _startTimeController.text,
                    _endTimeController.text,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateEvents(String newEvent, String subject, String eventType,
      String content, String startTime, String endTime) {
    List<Map<String, String>> eventsForDay = _events[_selectedDay] ?? [];
    eventsForDay.add({
      'type': eventType,
      'event': newEvent,
      'task': eventType == 'task' ? newEvent : '',
      'subject': subject,
      'content': content,
      'startTime': startTime,
      'endTime': endTime,
    });

    _db.collection('events').doc(_user.uid).set({
      for (var entry in _events.entries) '${entry.key.toString()}': entry.value,
    }).then((_) {
      setState(() {
        _events[_selectedDay] = eventsForDay;
      });
    }).catchError((error) {
      print("Failed to update events: $error");
    });
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
}
