import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  late Map<String, dynamic> data = {};
  bool _saturday = true;
  bool _sunday = true;
  int times = 6;

  List<String> mon = List.filled(10, '');
  List<String> tue = List.filled(10, '');
  List<String> wed = List.filled(10, '');
  List<String> thu = List.filled(10, '');
  List<String> fri = List.filled(10, '');
  List<String> sat = List.filled(10, '');
  List<String> sun = List.filled(10, '');
  List<String> subjects = [''];

  late Map<String, dynamic> week = {};

  @override
  void initState() {
    super.initState();
    _loadSharedPreferencesData();
  }

  Future<void> _loadSharedPreferencesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');
    if (jsonString != null) {
      Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        data = jsonData;
        times = data['times'] ?? 6;
        _saturday = data['enable_sat'] ?? true;
        _sunday = data['enable_sun'] ?? true;
        mon = List<String>.from(data['mon'] ?? List.filled(10, ''));
        tue = List<String>.from(data['tue'] ?? List.filled(10, ''));
        wed = List<String>.from(data['wed'] ?? List.filled(10, ''));
        thu = List<String>.from(data['thu'] ?? List.filled(10, ''));
        fri = List<String>.from(data['fri'] ?? List.filled(10, ''));
        sat = List<String>.from(data['sat'] ?? List.filled(10, ''));
        sun = List<String>.from(data['sun'] ?? List.filled(10, ''));
        subjects = List<String>.from(
            data['sub']?.map((subject) => subject.toString()) ?? []);
        subjects =
            subjects.where((subject) => subject.trim().isNotEmpty).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割'),
      ),
      drawer: Drawer(
        elevation: 0,
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: Text('Drawer Header'),
            ),
            const Text('時間数を選択してください'),
            DropdownButton<int>(
              value: times,
              onChanged: (value) {
                setState(() {
                  times = value!;
                  _makeJson();
                  _saveToSharedPreferences();
                });
              },
              items: List.generate(
                10,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(
                    '${index + 1}時間',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              isExpanded: true,
              underline: Container(
                height: 2,
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              elevation: 16,
              hint: const Text(
                '時間数を選択してください',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            ListTile(
              title: const Text("教科の追加"),
              trailing: const Icon(Icons.add),
              onTap: () {
                _showAddSubjectDialog(context);
              },
            ),
            SwitchListTile(
              title: const Text('土曜日を表示する'),
              value: _saturday,
              onChanged: (bool value) {
                setState(() {
                  _saturday = value;
                  _makeJson();
                  _saveToSharedPreferences();
                });
              },
            ),
            SwitchListTile(
              title: const Text('日曜日を表示する'),
              value: _sunday,
              onChanged: (bool value) {
                setState(() {
                  _sunday = value;
                  _makeJson();
                  _saveToSharedPreferences();
                });
              },
            ),
            TextButton(
              onPressed: () async {
                _makeJson();
                _saveToSharedPreferences();
              },
              child: const Text('時間割を保存'),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 5, 53, 8),
      body: Center(
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Table(
            border: TableBorder.all(color: Colors.white, width: 2),
            defaultColumnWidth: const FlexColumnWidth(),
            columnWidths: const {0: FixedColumnWidth(50.0)},
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(' '),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('月'),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('火'),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('水'),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('木'),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('金'),
                  ),
                  if (_saturday)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('土'),
                    ),
                  if (_sunday)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('日'),
                    ),
                ],
              ),
              for (int i = 1; i <= times; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: SizedBox(
                        height: 50,
                        child: Center(child: Text('$i')),
                      ),
                    ),
                    _buildTableCell(context, 'mon', mon, i),
                    _buildTableCell(context, 'tue', tue, i),
                    _buildTableCell(context, 'wed', wed, i),
                    _buildTableCell(context, 'thu', thu, i),
                    _buildTableCell(context, 'fri', fri, i),
                    if (_saturday) _buildTableCell(context, 'sat', sat, i),
                    if (_sunday) _buildTableCell(context, 'sun', sun, i),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
      BuildContext context, String day, List<String> list, int i) {
    return GestureDetector(
      onTap: () {
        _showInputDialog(context, day, i - 1);
      },
      child: Container(
        height: 50,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          list[i - 1],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _makeJson() {
    week = {
      "times": times,
      "enable_sat": _saturday,
      "enable_sun": _sunday,
      "mon": mon,
      "tue": tue,
      "wed": wed,
      "thu": thu,
      "fri": fri,
      "sat": sat,
      "sun": sun,
      "sub": subjects,
    };
  }

  void _saveToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(week);
    await prefs.setString('timetable', jsonString);
    print('Shared Preferencesに保存されました');
  }

  void _showInputDialog(BuildContext context, String day, int index) async {
    String selectedSubject = '';

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('教科を選択してください'),
              contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              content: Container(
                width: double.infinity,
                height: 150,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButton<String>(
                        value: selectedSubject,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedSubject = newValue;
                            });
                          }
                        },
                        items: _buildDropdownMenuItems(),
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: const Text('キャンセル'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('保存'),
                            onPressed: () {
                              Navigator.of(context).pop(selectedSubject);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          switch (day) {
            case 'mon':
              mon[index] = value;
              break;
            case 'tue':
              tue[index] = value;
              break;
            case 'wed':
              wed[index] = value;
              break;
            case 'thu':
              thu[index] = value;
              break;
            case 'fri':
              fri[index] = value;
              break;
            case 'sat':
              sat[index] = value;
              break;
            case 'sun':
              sun[index] = value;
              break;
          }
          _makeJson();
          _saveToSharedPreferences();
        });
      }
    });
  }

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    Set<String> uniqueSubjects = subjects.toSet();

    uniqueSubjects.remove(''); // 空の選択肢を削除
    List<String> sortedSubjects = uniqueSubjects.toList()..sort();
    sortedSubjects.insert(0, ''); // 空の選択肢を最初に追加

    return sortedSubjects.map((String subject) {
      return DropdownMenuItem<String>(
        value: subject,
        child: Container(
          width: double.infinity,
          child: Text(
            subject.isEmpty ? '選択してください' : subject,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }).toList();
  }

  void _showAddSubjectDialog(BuildContext context) async {
    TextEditingController textEditingController = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('教科を追加'),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          if (subjects[index].trim().isEmpty)
                            return Container();
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(subjects[index]),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      subjects.removeAt(index);
                                      _makeJson();
                                      _saveToSharedPreferences();
                                    });
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _addSubjectToDay(
                                DateTime.now().weekday,
                                subjects[index],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: textEditingController,
                      decoration: const InputDecoration(
                        hintText: "教科名を入力してください",
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('追加'),
                  onPressed: () {
                    String subjectName = textEditingController.text.trim();
                    if (subjectName.isNotEmpty &&
                        !subjects.contains(subjectName)) {
                      setState(() {
                        subjects.add(subjectName);
                        _makeJson();
                        _saveToSharedPreferences();
                      });
                      textEditingController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('教科を追加しました'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('すでに同じ名前の教科が存在するか空白です。'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSubjectToDay(int weekday, String subjectName) {
    setState(() {
      switch (weekday) {
        case DateTime.monday:
          mon.add(subjectName);
          break;
        case DateTime.tuesday:
          tue.add(subjectName);
          break;
        case DateTime.wednesday:
          wed.add(subjectName);
          break;
        case DateTime.thursday:
          thu.add(subjectName);
          break;
        case DateTime.friday:
          fri.add(subjectName);
          break;
        case DateTime.saturday:
          sat.add(subjectName);
          break;
        case DateTime.sunday:
          sun.add(subjectName);
          break;
      }
      _makeJson();
      _saveToSharedPreferences();
    });
  }

  Future<bool> _checkIfSubjectExists(String subjectName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');
    if (jsonString != null) {
      Map<String, dynamic> data = json.decode(jsonString);
      List<String> existingSubjects = List<String>.from(data['sub'] ?? []);
      return !existingSubjects.contains(subjectName);
    }
    return true;
  }

  void _deleteSubject(String subjectName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('timetable');
    if (jsonString != null) {
      Map<String, dynamic> data = json.decode(jsonString);
      List<String> existingSubjects = List<String>.from(data['sub'] ?? []);
      existingSubjects.remove(subjectName);
      data['sub'] = existingSubjects;
      jsonString = json.encode(data);
      await prefs.setString('timetable', jsonString);
      setState(() {
        subjects = existingSubjects;
      });
      _makeJson();
      _saveToSharedPreferences();
    }
  }
}
