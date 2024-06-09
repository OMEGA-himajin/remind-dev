import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

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
      body: const Center(
          child: Text('スケジュール', style: TextStyle(fontSize: 32.0))),
    );
    
  }
}