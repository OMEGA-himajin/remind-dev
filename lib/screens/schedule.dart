import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Map<String, dynamic> data = {};
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  late DateTime _selectedDay;
  bool _isLoading = true;
  List<String> subjects = [];

  bool _isAddingEvent = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadSharedPreferencesData();
  }

  Future<void> _loadSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? timetableJson = prefs.getString('timetable');
    if (timetableJson != null) {
      Map<String, dynamic> jsonData = json.decode(timetableJson);
      setState(() {
        data = jsonData;
        subjects = List<String>.from(
            data['sub']?.map((subject) => subject.toString()) ?? []);
      });
    }

    String? eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      Map<String, dynamic> eventsMap = json.decode(eventsJson);
      _events = eventsMap.map((key, value) {
        return MapEntry(
          DateTime.parse(key),
          (value as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> eventsMap = _events.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });
    await prefs.setString('events', json.encode(eventsMap));
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
                            eventLoader: (day) {
                              return _getEventsForDay(day);
                            },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        if (event['type'] == 'event') {
                                          if (event['isAllDay'] == true) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2.0),
                                              child: Text(
                                                '終日',
                                                style:
                                                    TextStyle(fontSize: 14.0),
                                              ),
                                            );
                                          } else if (event
                                                  .containsKey('startTime') &&
                                              event.containsKey('endTime')) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2.0),
                                              child: Text(
                                                '${event['startTime']} 〜 ${event['endTime']}',
                                                style:
                                                    TextStyle(fontSize: 14.0),
                                              ),
                                            );
                                          }
                                        }
                                        return SizedBox.shrink();
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
          _showAddEventDialog();
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
                if (_getEventsForDay(day).isNotEmpty)
                  ..._getEventsForDay(day).map((event) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(event['color'] as int),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            event['type'] == 'task'
                                ? '${event['task']}'
                                : event['isAllDay'] == true
                                    ? '終日 ${event['event']}'
                                    : '${event['startTime']}~${event['endTime']} ${event['event']}',
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
    _loadSharedPreferencesData();
    final TextEditingController _eventController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _startDateTimeController =
        TextEditingController();
    final TextEditingController _endDateTimeController =
        TextEditingController();
    String selectedType = 'event';
    String selectedSubject = subjects.isNotEmpty ? subjects[0] : '';
    Color selectedColor = Colors.blue;
    DateTime startDateTime = _selectedDay;
    DateTime endDateTime = _selectedDay.add(Duration(hours: 1));
    bool isAllDay = false;

    _startDateTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(startDateTime);
    _endDateTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(endDateTime);

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
                        _startDateTimeController.text =
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(startDateTime);
                        _endDateTimeController.text =
                            DateFormat('yyyy-MM-dd HH:mm').format(endDateTime);
                        selectedSubject =
                            subjects.isNotEmpty ? subjects[0] : '';
                        isAllDay = false;
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: 'event',
                        child: Text('予定'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'task',
                        child: Text('課題'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  ListTile(
                    title: const Text('色を選択'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('色を選択'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16.0),
                  if (selectedType == 'event') ...[
                    TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(labelText: '予定名'),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text('終日'),
                      value: isAllDay,
                      onChanged: (bool value) {
                        setState(() {
                          isAllDay = value;
                          if (isAllDay) {
                            _startDateTimeController.text =
                                DateFormat('yyyy-MM-dd').format(startDateTime);
                            _endDateTimeController.text =
                                DateFormat('yyyy-MM-dd').format(endDateTime);
                          } else {
                            _startDateTimeController.text =
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(startDateTime);
                            _endDateTimeController.text =
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(endDateTime);
                          }
                        });
                      },
                    ),
                    if (!isAllDay) ...[
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  pickedDateTime.year,
                                  pickedDateTime.month,
                                  pickedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                _startDateTimeController.text =
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(startDateTime);
                              });
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startDateTimeController,
                            decoration:
                                const InputDecoration(labelText: '開始日時'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  pickedDateTime.year,
                                  pickedDateTime.month,
                                  pickedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                _endDateTimeController.text =
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(endDateTime);
                              });
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _endDateTimeController,
                            decoration:
                                const InputDecoration(labelText: '終了日時'),
                          ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            setState(() {
                              startDateTime = pickedDateTime;
                              _startDateTimeController.text =
                                  DateFormat('yyyy-MM-dd')
                                      .format(startDateTime);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startDateTimeController,
                            decoration: const InputDecoration(labelText: '開始日'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            setState(() {
                              endDateTime = pickedDateTime;
                              _endDateTimeController.text =
                                  DateFormat('yyyy-MM-dd').format(endDateTime);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _endDateTimeController,
                            decoration: const InputDecoration(labelText: '終了日'),
                          ),
                        ),
                      ),
                    ],
                  ] else if (selectedType == 'task') ...[
                    TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(labelText: '課題名'),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: InputDecoration(labelText: '教科'),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value!;
                        });
                      },
                      items: subjects.map((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: '内容'),
                      maxLines: 3,
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
                          (_startDateTimeController.text.isEmpty ||
                              _endDateTimeController.text.isEmpty)) ||
                      (selectedType == 'task' &&
                          (_eventController.text.isEmpty ||
                              selectedSubject.isEmpty ||
                              _contentController.text.isEmpty))) {
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
                    startDateTime,
                    endDateTime,
                    selectedColor,
                    isAllDay,
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

  void _updateEvents(
      String newEvent,
      String subject,
      String eventType,
      String content,
      DateTime startDateTime,
      DateTime endDateTime,
      Color color,
      bool isAllDay) {
    DateTime eventDate =
        DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
    List<Map<String, dynamic>> eventsForDay = _events[eventDate] ?? [];
    eventsForDay.add({
      'type': eventType,
      'event': newEvent,
      'task': eventType == 'task' ? newEvent : '',
      'subject': subject,
      'content': content,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'startTime': isAllDay ? null : DateFormat('HH:mm').format(startDateTime),
      'endTime': isAllDay ? null : DateFormat('HH:mm').format(endDateTime),
      'color': color.value,
      'isAllDay': isAllDay,
    });

    setState(() {
      _events[eventDate] = eventsForDay;
    });

    _saveSharedPreferencesData();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events.entries
        .where((entry) => isSameDay(entry.key, day))
        .expand((entry) => entry.value)
        .toList();
  }
}
