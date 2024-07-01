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
  Map<DateTime, List<String>> _events = {};
  late DateTime _selectedDay;
  late User _user; // Firebase User object
  late FirebaseFirestore _db; // Firestore instance
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeFirebase(); // Initialize Firebase dependencies
    _fetchEvents(); // Fetch events from Firestore
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
          final List<String> events = List<String>.from(value);
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
                      return ListTile(
                        title: Text(_getEventsForDay(_selectedDay)[index]),
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
                            event,
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
    final TextEditingController _eventController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を追加'),
        content: TextField(
          controller: _eventController,
          decoration: const InputDecoration(hintText: '予定を入力'),
        ),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('追加'),
            onPressed: () {
              if (_eventController.text.isEmpty) return;

              // Update Firestore document with new event
              _updateEvents(_eventController.text);

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _updateEvents(String newEvent) {
    // Add the new event to the existing list of events for the selected day
    List<String> eventsForDay = _events[_selectedDay] ?? [];
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

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
}
