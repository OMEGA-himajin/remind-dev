import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedDay;
  bool _isLoading = true;
  List<String> subjects = [];
  bool _isAddingEvent = false;
  final DataManager _dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    await _dataManager.loadData();
    setState(() {
      subjects = List<String>.from(_dataManager.getData()['sub'] ?? []);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スケジュール'),
      ),
      drawer: CommonUI.buildDrawer(context),
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
                              return _dataManager.getEventsForDay(day);
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
                                  DateFormat('yyyy年MM月dd日の予定')
                                      .format(_selectedDay),
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildEventList(),
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
                ..._dataManager.getEventsForDay(day).map((event) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(event['color'] as int),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          event['type'] == 'task'
                              ? event['task']
                              : event['event'],
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

  Widget _buildEventList() {
    List<Map<String, dynamic>> events =
        _dataManager.getEventsForDay(_selectedDay);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('予定はありません'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                  event['type'] == 'task' ? event['task']! : event['event']!),
              subtitle: event['type'] == 'task'
                  ? Text('教科: ${event['subject']!}')
                  : Text(event['isAllDay'] == true
                      ? '終日'
                      : '${event['startTime']} 〜 ${event['endTime']}'),
            ),
          );
        },
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController _eventController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _dateController = TextEditingController();
    final TextEditingController _startDateTimeController =
        TextEditingController();
    final TextEditingController _endDateTimeController =
        TextEditingController();
    String selectedType = 'event';
    String selectedSubject = subjects.isNotEmpty ? subjects[0] : '';
    Color selectedColor = Colors.blue;
    DateTime selectedDate = _selectedDay;
    DateTime startDateTime = DateTime.now();
    DateTime endDateTime = DateTime.now().add(Duration(hours: 1));
    bool isAllDay = false;

    _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
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
                        _dateController.text =
                            DateFormat('yyyy-MM-dd').format(selectedDate);
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
                          value: 'event', child: Text('予定')),
                      DropdownMenuItem<String>(
                          value: 'task', child: Text('課題')),
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
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                              _dateController.text =
                                  DateFormat('yyyy-MM-dd').format(selectedDate);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _dateController,
                            decoration: const InputDecoration(labelText: '日付'),
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
                          _dateController.text.isEmpty) ||
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
                  _addEvent(
                    _eventController.text,
                    selectedSubject,
                    selectedType,
                    _contentController.text,
                    isAllDay ? selectedDate : startDateTime,
                    isAllDay ? null : endDateTime,
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

  void _addEvent(
    String newEvent,
    String subject,
    String eventType,
    String content,
    DateTime startDateTime,
    DateTime? endDateTime,
    Color color,
    bool isAllDay,
  ) {
    Map<String, dynamic> event = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': eventType,
      'event': newEvent,
      'task': eventType == 'task' ? newEvent : '',
      'subject': subject,
      'content': content,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime':
          endDateTime?.toIso8601String() ?? startDateTime.toIso8601String(),
      'startTime': isAllDay ? null : DateFormat('HH:mm').format(startDateTime),
      'endTime': isAllDay ? null : DateFormat('HH:mm').format(endDateTime!),
      'color': color.value,
      'isAllDay': isAllDay,
    };

    _dataManager.addEvent(event);

    setState(() {});
  }
}
