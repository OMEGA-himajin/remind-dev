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
    return Scaffold(
      appBar: AppBar(
        title: const Text('スケジュール'),
      ),
      drawer: Drawer(
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
            ListTile(
              leading: Icon(Icons.home),
              title: Text('ホーム'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('スケジュール'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 他のメニュー項目をここに追加
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
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableHeight = constraints.maxHeight;
                                final rowHeight =
                                    (availableHeight - 80) / 6; // 6週間分のカレンダーを想定
                                return TableCalendar(
                                  firstDay: DateTime.utc(2010, 1, 1),
                                  lastDay: DateTime.utc(2030, 1, 1),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) {
                                    return day.isAfter(_selectedStartDay
                                            .subtract(Duration(days: 1))) &&
                                        day.isBefore(_selectedEndDay
                                            .add(Duration(days: 1)));
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
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
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder: (context, day, focusedDay) {
                                      return _buildDayContainer(
                                          day, focusedDay);
                                    },
                                    selectedBuilder:
                                        (context, day, focusedDay) {
                                      return _buildDayContainer(day, focusedDay,
                                          isSelected: true);
                                    },
                                    todayBuilder: (context, day, focusedDay) {
                                      return _buildDayContainer(day, focusedDay,
                                          isToday: true);
                                    },
                                  ),
                                  rowHeight: rowHeight,
                                  daysOfWeekHeight: 40,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(fontSize: 20),
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
                            padding: EdgeInsets.all(16.0),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
    List<Map<String, dynamic>> events = _dataManager.getEventsForDay(day);

    bool isInSelectedRange =
        day.isAfter(_selectedStartDay.subtract(Duration(days: 1))) &&
            day.isBefore(_selectedEndDay.add(Duration(days: 1)));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        color: isInSelectedRange ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 5,
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
            top: 25, // 日付の下にイベントを配置
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildEventOverlay(day, events),
          ),
        ],
      ),
    );
  }

  Widget _buildEventOverlay(DateTime day, List<Map<String, dynamic>> events) {
    List<Widget> eventWidgets = [];
    int displayedEvents = 0;
    bool hasMoreEvents = false;

    // イベントを期間の長さでソート（長い順）
    events.sort((a, b) {
      DateTime startA = DateTime.parse(a['startDateTime']);
      DateTime endA = DateTime.parse(a['endDateTime']);
      DateTime startB = DateTime.parse(b['startDateTime']);
      DateTime endB = DateTime.parse(b['endDateTime']);
      int durationA = endA.difference(startA).inDays;
      int durationB = endB.difference(startB).inDays;
      return durationB.compareTo(durationA);
    });

    Map<int, DateTime> lastEndDate = {};

    for (var event in events) {
      if (displayedEvents >= 2) {
        hasMoreEvents = true;
        break;
      }

      DateTime startDate = DateTime.parse(event['startDateTime']);
      DateTime endDate = DateTime.parse(event['endDateTime']);
      bool isInRange = !day.isBefore(startDate) && !day.isAfter(endDate);

      if (isInRange) {
        bool isStart = isSameDay(day, startDate);
        bool isEnd = isSameDay(day, endDate);
        bool shouldShowLabel = _shouldShowLabel(day, startDate, endDate);

        int row = 0;
        while (lastEndDate.containsKey(row) &&
            lastEndDate[row]!.isAfter(startDate)) {
          row++;
        }

        if (row < 2) {
          double height = 16.0;
          double top = row * (height + 1);

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
                              fontSize: 9,
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

          lastEndDate[row] = endDate;
          displayedEvents++;
        }
      }
    }

    if (hasMoreEvents) {
      eventWidgets.add(
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 2 * (16.0 + 1) + 2, // 2つのイベント + 追加のスペース
      child: Stack(children: eventWidgets),
    );
  }

  bool _shouldShowLabel(DateTime day, DateTime startDate, DateTime endDate) {
    // 開始日または終了日の場合は常にラベルを表示
    if (isSameDay(day, startDate) || isSameDay(day, endDate)) {
      return true;
    }

    // 月初めの場合はラベルを表示
    if (day.day == 1) {
      return true;
    }

    int daysBetween = endDate.difference(startDate).inDays;

    // イベントが2週間以上の場合のみ、中間点のラベル表示を考慮
    if (daysBetween > 13) {
      // イベントの中間点を計算
      DateTime midpoint = startDate.add(Duration(days: daysBetween ~/ 2));

      // 中間点の週の水曜日を計算
      DateTime weekMidpoint =
          midpoint.subtract(Duration(days: midpoint.weekday - 3));

      // 現在の日が中間点の週の水曜日で、かつ開始日と終了日の間にある場合にラベルを表示
      if (isSameDay(day, weekMidpoint) &&
          day.isAfter(startDate) &&
          day.isBefore(endDate)) {
        // 開始日と終了日が異なる週にあることを確認
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

  bool _eventsOverlap(
      Map<String, dynamic> event1, Map<String, dynamic> event2, DateTime day) {
    DateTime start1 = DateTime.parse(event1['startDateTime']);
    DateTime end1 = DateTime.parse(event1['endDateTime']);
    DateTime start2 = DateTime.parse(event2['startDateTime']);
    DateTime end2 = DateTime.parse(event2['endDateTime']);

    return (start1.isBefore(end2) || isSameDay(start1, end2)) &&
        (start2.isBefore(end1) || isSameDay(start2, end1)) &&
        !day.isBefore(start1.isAfter(start2) ? start1 : start2) &&
        !day.isAfter(end1.isBefore(end2) ? end1 : end2);
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
