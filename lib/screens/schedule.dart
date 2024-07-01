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
  List<String> _subjects = []; // List to store subjects

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeFirebase(); // Initialize Firebase dependencies
    _fetchEvents(); // Fetch events from Firestore
    _fetchSubjects(); // Fetch subjects from Firestore
  }

  void _initializeFirebase() {
    _user = FirebaseAuth.instance.currentUser!; // Get current user
    _db = FirebaseFirestore.instance; // Initialize Firestore
  }

  Future<void> _fetchEvents() async {
    // Fetch events from Firestore for the current user
    try {
      final eventDoc = await _db.collection('events').doc(_user.uid).get();

      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          final DateTime date = DateTime.parse(key);
          final List<Map<String, String>> events = List<Map<String, String>>.from(
            value.map((event) => Map<String, String>.from(event))
          );
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

  Future<void> _fetchSubjects() async {
    // Fetch subjects from Firestore
    try {
      final subjectsDoc = await _db.collection('timetable').doc(_user.uid).get();

      if (subjectsDoc.exists) {
        final data = subjectsDoc.data() as Map<String, dynamic>;
        setState(() {
          _subjects = List<String>.from(data['subjects']);
        });
      } else {
        _subjects = [];
      }
    } catch (error) {
      print("Failed to fetch subjects: $error");
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
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: Text("Item 1"),
              trailing: Icon(Icons.arrow_forward),
            ),
            ListTile(
              title: Text("Item 2"),
              trailing: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                    });
                    _showAddEventDialog();
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayContainer(day, focusedDay);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildDayContainer(day, focusedDay, isSelected: true);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildDayContainer(day, focusedDay, isToday: true);
                    },
                  ),
                ),
                SizedBox(height: 20.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay)[index];
                      return ListTile(
                        title: Text(event['title']!),
                        subtitle: Text(event['description']!),
                      );
                    },
                  ),
                ),
              ],
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
                color: isSelected ? Colors.blue : isToday ? Colors.red : null,
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
                            event['title']!,
                            style: TextStyle(color: Colors.white),
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
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    String _selectedEventType = '提出課題';
    String? _selectedSubject;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('予定を追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'タイトルを入力'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: '説明を入力'),
                ),
                DropdownButton<String>(
                  value: _selectedEventType,
                  items: <String>['提出課題', '行事', 'その他'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedEventType = newValue!;
                      if (_selectedEventType != '提出課題') {
                        _selectedSubject = null; // Reset selected subject if not an assignment
                      }
                    });
                  },
                ),
                if (_selectedEventType == '提出課題')
                  DropdownButton<String>(
                    value: _selectedSubject,
                    hint: const Text('教科を選択'),
                    items: _subjects.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('追加'),
                onPressed: () {
                  if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) return;

                  // Update Firestore document with new event
                  _updateEvents({
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'type': _selectedEventType,
                    'subject': _selectedSubject ?? '',
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        }
      ),
    );
  }

  void _updateEvents(Map<String, String> newEvent) {
    // Add the new event to the existing list of events for the selected day
    List<Map<String, String>> eventsForDay = _events[_selectedDay] ?? [];
    eventsForDay.add(newEvent);

    // Update Firestore document with updated events list
    _db.collection('events').doc(_user.uid).set({
      for (var entry in _events.entries)
        '${entry.key.toString()}': entry.value,
      '${_selectedDay.toString()}': eventsForDay,
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
