import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'package:flutter/material.dart' show ThemeData, TextTheme;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DataManager _dataManager = DataManager();
  late DateTime _selectedStartDay;
  late DateTime _selectedEndDay;
  late DateTime _focusedDay;
  bool _isLoading = true;
  List<String> subjects = [];
  bool _isAddingEvent = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDay = DateTime.now();
    _selectedEndDay = DateTime.now();
    _focusedDay = DateTime.now();
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableHeight = constraints.maxHeight;
                                final rowHeight = (availableHeight - 80) / 6;
                                return TableCalendar(
                                  firstDay: DateTime.utc(2010, 1, 1),
                                  lastDay: DateTime.utc(2030, 1, 1),
                                  focusedDay: _focusedDay,
                                  onDaySelected: (
                                    selectedDay,
                                    focusedDay,
                                  ) {
                                    setState(() {
                                      if (selectedDay
                                              .isBefore(_selectedStartDay) ||
                                          _selectedStartDay ==
                                              _selectedEndDay) {
                                        _selectedStartDay = selectedDay;
                                        _selectedEndDay = selectedDay;
                                      } else if (selectedDay
                                          .isAfter(_selectedStartDay)) {
                                        _selectedEndDay = selectedDay;
                                      }
                                      _focusedDay = focusedDay;
                                      _isAddingEvent = true;
                                    });
                                  },
                                  calendarStyle: CalendarStyle(
                                    weekendTextStyle:
                                        TextStyle(color: Colors.red),
                                    defaultTextStyle: textTheme.bodyMedium!
                                        .copyWith(color: primaryColor),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder: (context, day, focusedDay) {
                                      return _buildDayContainer(day, focusedDay,
                                          rowHeight, primaryColor, textTheme);
                                    },
                                    todayBuilder: (context, day, focusedDay) {
                                      return _buildDayContainer(day, focusedDay,
                                          rowHeight, primaryColor, textTheme,
                                          isToday: true);
                                    },
                                    dowBuilder: (context, day) {
                                      if (day.weekday == DateTime.sunday) {
                                        return Center(
                                          child: Text(
                                            DateFormat.E().format(day),
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        );
                                      }
                                      if (day.weekday == DateTime.saturday) {
                                        return Center(
                                          child: Text(
                                            DateFormat.E().format(day),
                                            style:
                                                TextStyle(color: Colors.blue),
                                          ),
                                        );
                                      }
                                      return Center(
                                        child: Text(
                                          DateFormat.E().format(day),
                                          style: textTheme.bodyMedium!
                                              .copyWith(color: primaryColor),
                                        ),
                                      );
                                    },
                                  ),
                                  rowHeight: rowHeight,
                                  daysOfWeekHeight: 40,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: textTheme.titleLarge!
                                        .copyWith(color: primaryColor),
                                  ),
                                );
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, -3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 25,
                                  child: Center(
                                    child: Container(
                                      width: 120,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 179, 177, 177),
                                        borderRadius:
                                            BorderRadius.circular(2.5),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          _selectedStartDay == _selectedEndDay
                                              ? DateFormat('yyyy年MM月dd日の予定')
                                                  .format(_selectedStartDay)
                                              : '${DateFormat('yyyy年MM月dd日').format(_selectedStartDay)} 〜 ${DateFormat('yyyy年MM月dd日').format(_selectedEndDay)}の予定',
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
    );
  }

  Widget _buildDayContainer(DateTime day, DateTime focusedDay,
      double cellHeight, Color primaryColor, TextTheme textTheme,
      {bool isToday = false}) {
    List<Map<String, dynamic>> events = _dataManager.getEventsForDay(day);

    Color textColor;
    if (day.weekday == DateTime.sunday) {
      textColor = Colors.red;
    } else if (day.weekday == DateTime.saturday) {
      textColor = Colors.blue;
    } else {
      textColor = isToday ? Colors.white : primaryColor;
    }

    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? primaryColor : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: textTheme.bodyMedium!.copyWith(
                  color: textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildEventOverlay(day, events, cellHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildEventOverlay(
      DateTime day, List<Map<String, dynamic>> events, double cellHeight) {
    List<Widget> eventWidgets = [];
    Map<String, int> eventRows = {};
    int maxRows =
        ((cellHeight - 20) / 16).floor(); // セルの高さから日付の高さを引き、1行の高さ(16)で割る

    events.sort((a, b) {
      DateTime startA = DateTime.parse(a['startDateTime']);
      DateTime endA = DateTime.parse(a['endDateTime']);
      DateTime startB = DateTime.parse(b['startDateTime']);
      DateTime endB = DateTime.parse(b['endDateTime']);
      int durationA = endA.difference(startA).inDays;
      int durationB = endB.difference(startB).inDays;
      return durationB.compareTo(durationA);
    });

    for (var event in events) {
      DateTime startDate = DateTime.parse(event['startDateTime']);
      DateTime endDate = DateTime.parse(event['endDateTime']);
      bool isInRange = !day.isBefore(startDate) && !day.isAfter(endDate);

      if (isInRange) {
        String eventId = event['id'];
        bool isStart = isSameDay(day, startDate);
        bool isEnd = isSameDay(day, endDate);
        bool shouldShowLabel = _shouldShowLabel(day, startDate, endDate);

        if (!eventRows.containsKey(eventId)) {
          int row = 0;
          while (eventRows.containsValue(row) && row < maxRows) {
            row++;
          }
          if (row < maxRows) {
            eventRows[eventId] = row;
          } else {
            continue; // スキップして次のイベントへ
          }
        }

        int row = eventRows[eventId]!;
        double height = 14.0;
        double top = row * (height + 1) + 1;

        eventWidgets.add(
          Positioned(
            top: top,
            left: isStart ? 2 : 0,
            right: isEnd ? 2 : 0,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: Color(event['color'] as int),
                borderRadius: BorderRadius.horizontal(
                  left: isStart ? Radius.circular(4.0) : Radius.zero,
                  right: isEnd ? Radius.circular(4.0) : Radius.zero,
                ),
              ),
              child: shouldShowLabel
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _getEventDisplayText(event),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      }
    }

    return Container(
      height: cellHeight - 20, // 日付の高さを引く
      child: Stack(children: eventWidgets),
    );
  }

  bool _shouldShowLabel(DateTime day, DateTime startDate, DateTime endDate) {
    if (isSameDay(day, startDate) || isSameDay(day, endDate)) {
      return true;
    }

    if (day.day == 1) {
      return true;
    }

    int daysBetween = endDate.difference(startDate).inDays;

    if (daysBetween > 13) {
      DateTime midpoint = startDate.add(Duration(days: daysBetween ~/ 2));
      DateTime weekMidpoint =
          midpoint.subtract(Duration(days: midpoint.weekday - 3));

      if (isSameDay(day, weekMidpoint) &&
          day.isAfter(startDate) &&
          day.isBefore(endDate)) {
        if (weekMidpoint.difference(startDate).inDays >= 7 &&
            endDate.difference(weekMidpoint).inDays >= 7) {
          return true;
        }
      }
    }

    return false;
  }

  String _getEventDisplayText(Map<String, dynamic> event) {
    if (event['isAllDay'] == true) {
      return '${event['type'] == 'task' ? event['task'] : event['event']}';
    } else {
      return event['type'] == 'task' ? event['task'] : event['event'];
    }
  }

  Widget _buildEventList() {
    List<Map<String, dynamic>> events =
        _dataManager.getEventsForPeriod(_selectedStartDay, _selectedEndDay);

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
    final TextEditingController _startDateController = TextEditingController();
    final TextEditingController _endDateController = TextEditingController();
    final TextEditingController _startDateTimeController =
        TextEditingController();
    final TextEditingController _endDateTimeController =
        TextEditingController();
    String selectedType = 'event';
    String selectedSubject = subjects.isNotEmpty ? subjects[0] : '';
    Color selectedColor = Colors.blue;
    DateTime startDateTime = _selectedStartDay;
    DateTime endDateTime = _selectedEndDay;
    bool isAllDay = false;

    _startDateController.text = DateFormat('yyyy-MM-dd').format(startDateTime);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(endDateTime);
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
                        _startDateController.text =
                            DateFormat('yyyy-MM-dd').format(startDateTime);
                        _endDateController.text =
                            DateFormat('yyyy-MM-dd').format(endDateTime);
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
                    if (isAllDay) ...[
                      GestureDetector(
                        onTap: () async {
                          DateTimeRange? pickedDateRange =
                              await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(
                                start: startDateTime, end: endDateTime),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateRange != null) {
                            setState(() {
                              startDateTime = pickedDateRange.start;
                              endDateTime = pickedDateRange.end;
                              _startDateController.text =
                                  DateFormat('yyyy-MM-dd')
                                      .format(startDateTime);
                              _endDateController.text =
                                  DateFormat('yyyy-MM-dd').format(endDateTime);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: Column(
                            children: [
                              TextField(
                                controller: _startDateController,
                                decoration:
                                    const InputDecoration(labelText: '開始日'),
                              ),
                              TextField(
                                controller: _endDateController,
                                decoration:
                                    const InputDecoration(labelText: '終了日'),
                              ),
                            ],
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
                          (isAllDay
                              ? _startDateController.text.isEmpty
                              : _startDateTimeController.text.isEmpty)) ||
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
                    isAllDay
                        ? DateTime.parse(_startDateController.text)
                        : startDateTime,
                    isAllDay
                        ? DateTime.parse(_endDateController.text)
                            .add(Duration(days: 1))
                            .subtract(Duration(milliseconds: 1))
                        : endDateTime,
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
    DateTime endDateTime,
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
      'endDateTime': endDateTime.toIso8601String(),
      'startTime': isAllDay ? null : DateFormat('HH:mm').format(startDateTime),
      'endTime': isAllDay ? null : DateFormat('HH:mm').format(endDateTime),
      'color': color.value,
      'isAllDay': isAllDay,
      'multiday': !isSameDay(startDateTime, endDateTime),
    };

    _dataManager.addEvent(event);

    setState(() {});
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
