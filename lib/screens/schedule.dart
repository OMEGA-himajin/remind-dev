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
  final _dataManager = DataManager();
  late DateTime _selectedStartDay;
  late DateTime _selectedEndDay;
  late DateTime _focusedDay;
  bool _isLoading = true;
  List<String> subjects = [];
  bool _isAddingEvent = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDay = _selectedEndDay = _focusedDay = DateTime.now();
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
                                final rowHeight =
                                    (constraints.maxHeight - 80) / 6;
                                return TableCalendar(
                                  firstDay: DateTime.utc(2010, 1, 1),
                                  lastDay: DateTime.utc(2030, 1, 1),
                                  focusedDay: _focusedDay,
                                  onDaySelected: _onDaySelected,
                                  calendarStyle: CalendarStyle(
                                    weekendTextStyle:
                                        TextStyle(color: Colors.red),
                                    defaultTextStyle: textTheme.bodyMedium!
                                        .copyWith(color: primaryColor),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder:
                                        (context, day, focusedDay) =>
                                            _buildDayContainer(
                                                day,
                                                focusedDay,
                                                rowHeight,
                                                primaryColor,
                                                textTheme),
                                    todayBuilder: (context, day, focusedDay) =>
                                        _buildDayContainer(day, focusedDay,
                                            rowHeight, primaryColor, textTheme,
                                            isToday: true),
                                    dowBuilder: (context, day) =>
                                        _buildDowBuilder(day, textTheme),
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
                      _buildEventAdder(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _onDaySelected(selectedDay, focusedDay) {
    setState(() {
      if (selectedDay.isBefore(_selectedStartDay) ||
          _selectedStartDay == _selectedEndDay) {
        _selectedStartDay = _selectedEndDay = selectedDay;
      } else if (selectedDay.isAfter(_selectedStartDay)) {
        _selectedEndDay = selectedDay;
      }
      _focusedDay = focusedDay;
      _isAddingEvent = true;
    });
  }

  Widget _buildDowBuilder(DateTime day, TextTheme textTheme) {
    final textColor = day.weekday == DateTime.sunday
        ? Colors.red
        : day.weekday == DateTime.saturday
            ? Colors.blue
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black;
    return Center(
      child: Text(
        DateFormat.E().format(day),
        style: textTheme.bodyMedium!.copyWith(color: textColor),
      ),
    );
  }

//
  Widget _buildEventAdder(ThemeData theme) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _isAddingEvent ? 0 : -300,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() => _isAddingEvent = false);
          }
        },
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.5),
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
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _selectedStartDay == _selectedEndDay
                            ? DateFormat('yyyy年MM月dd日の予定')
                                .format(_selectedStartDay)
                            : '${DateFormat('yyyy年MM月dd日').format(_selectedStartDay)} 〜 ${DateFormat('yyyy年MM月dd日').format(_selectedEndDay)}の予定',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      _buildEventList(),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _showAddEventDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8.0),
                            Text('予定を追加')
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
    );
  }

  Widget _buildEventList() {
    final theme = Theme.of(context);
    final events =
        _dataManager.getEventsForPeriod(_selectedStartDay, _selectedEndDay);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('予定はありません', style: theme.textTheme.bodyMedium),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: theme.cardColor,
            child: ListTile(
              title: Text(
                event['type'] == 'task' ? event['task']! : event['event']!,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: event['type'] == 'task'
                  ? Text('教科: ${event['subject']!}',
                      style: theme.textTheme.bodySmall)
                  : Text(
                      event['isAllDay'] == true
                          ? '終日'
                          : '${event['startTime']} 〜 ${event['endTime']}',
                      style: theme.textTheme.bodySmall,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContainer(DateTime day, DateTime focusedDay,
      double cellHeight, Color primaryColor, TextTheme textTheme,
      {bool isToday = false}) {
    final textColor = day.weekday == DateTime.sunday
        ? Colors.red
        : day.weekday == DateTime.saturday
            ? Colors.blue
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black;

    final events = _dataManager.getEventsForDay(day);

    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: EdgeInsets.all(2),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? primaryColor : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: textTheme.bodyMedium!.copyWith(
                  color: isToday ? Colors.white : textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: events
                  .map((event) => _buildEventIndicator(day, event))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventIndicator(DateTime day, Map<String, dynamic> event) {
    final startDate = DateTime.parse(event['startDateTime']);
    final endDate = DateTime.parse(event['endDateTime']);
    final isStart = day.isAtSameMomentAs(startDate);
    final isEnd = day.isAtSameMomentAs(endDate);
    final isMiddle = day.isAfter(startDate) && day.isBefore(endDate);
    final isSingleDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (!isStart && !isMiddle && !isEnd) return SizedBox.shrink();

    return Positioned(
      top: 0,
      left: isStart ? 0 : -0.5,
      right: isEnd ? 0 : -0.5,
      child: Container(
        height: 20, // 高さを増やして、より多くのテキストを表示できるようにします
        decoration: BoxDecoration(
          color: Color(event['color']),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isStart ? 4 : 0),
            bottomLeft: Radius.circular(isStart ? 4 : 0),
            topRight: Radius.circular(isEnd ? 4 : 0),
            bottomRight: Radius.circular(isEnd ? 4 : 0),
          ),
        ),
        child: Center(
          child: Text(
            _getEventText(event, isStart, isMiddle, isEnd, isSingleDay),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10, // フォントサイズを大きくして読みやすくします
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _getEventText(Map<String, dynamic> event, bool isStart, bool isMiddle,
      bool isEnd, bool isSingleDay) {
    if (isSingleDay || isStart) {
      return event['event'];
    } else if (isMiddle) {
      return '...'; // 中間の日には省略記号を表示
    } else if (isEnd) {
      return '終了'; // 最終日には「終了」と表示
    }
    return '';
  }

  void _showAddEventDialog() {
    final _eventController = TextEditingController();
    final _contentController = TextEditingController();
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();
    final _startDateTimeController = TextEditingController();
    final _endDateTimeController = TextEditingController();
    var selectedType = 'event';
    var selectedSubject = subjects.isNotEmpty ? subjects[0] : '';
    var selectedColor = Colors.blue;
    var startDateTime = _selectedStartDay;
    var endDateTime = _selectedEndDay;
    var isAllDay = false;

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
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('予定を追加', style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: '追加する項目',
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    style: theme.textTheme.bodyMedium,
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
                    title: Text('色を選択', style: theme.textTheme.bodyMedium),
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
                                    var selectedColor = Colors.blue as Color;
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
                      decoration: InputDecoration(
                        labelText: '予定名',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text('終日', style: theme.textTheme.bodyMedium),
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
                                decoration: InputDecoration(
                                  labelText: '開始日',
                                  labelStyle: theme.textTheme.bodyMedium,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextField(
                                controller: _endDateController,
                                decoration: InputDecoration(
                                  labelText: '終了日',
                                  labelStyle: theme.textTheme.bodyMedium,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () async {
                          final pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            final pickedTime = await showTimePicker(
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
                            decoration: InputDecoration(
                              labelText: '開始日時',
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final pickedDateTime = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDateTime != null) {
                            final pickedTime = await showTimePicker(
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
                            decoration: InputDecoration(
                              labelText: '終了日時',
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ] else if (selectedType == 'task') ...[
                    TextField(
                      controller: _eventController,
                      decoration: InputDecoration(
                        labelText: '課題名',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: InputDecoration(
                        labelText: '教科',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
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
                      decoration: InputDecoration(
                        labelText: '内容',
                        labelStyle: theme.textTheme.bodyMedium,
                      ),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('キャンセル', style: theme.textTheme.labelLarge),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('追加',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
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
    if (isAllDay) {
      startDateTime =
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      endDateTime =
          DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    } else {
      startDateTime = DateTime(
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
        startDateTime.hour,
        startDateTime.minute,
      );
      endDateTime = DateTime(
        endDateTime.year,
        endDateTime.month,
        endDateTime.day,
        endDateTime.hour,
        endDateTime.minute,
      );
    }

    final event = {
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
