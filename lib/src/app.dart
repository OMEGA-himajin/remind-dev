import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/items.dart';
import 'screens/schedule.dart';
import 'screens/timetable.dart';

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
  static const _screens = [
    HomeScreen(),
    TimeTableScreen(),
    ItemsScreen(),
    ScheduleScreen()
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
            BottomNavigationBarItem(icon: Icon(Icons.library_books), label: '持ち物'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'スケジュール'),
          ],
          type: BottomNavigationBarType.fixed,
        ));
  }
}