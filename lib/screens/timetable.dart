import 'package:flutter/material.dart';
import '../main.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();

  void showChangeTimesDialog(BuildContext context) {}
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await DataManager().loadData();
    Map<String, dynamic> timetableData = DataManager().getTimetableData();
    setState(() {
      data = timetableData;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  void _showInputDialog(BuildContext context, String day, int index) async {
    String? selectedSubject = '';
    List<String> currentDayList;
    String dayName;
    switch (day) {
      case 'mon':
        currentDayList = mon;
        dayName = '月曜日';
        break;
      case 'tue':
        currentDayList = tue;
        dayName = '火曜日';
        break;
      case 'wed':
        currentDayList = wed;
        dayName = '水曜日';
        break;
      case 'thu':
        currentDayList = thu;
        dayName = '木曜日';
        break;
      case 'fri':
        currentDayList = fri;
        dayName = '金曜日';
        break;
      case 'sat':
        currentDayList = sat;
        dayName = '土曜日';
        break;
      case 'sun':
        currentDayList = sun;
        dayName = '日曜日';
        break;
      default:
        currentDayList = [];
        dayName = '';
    }

    if (index < currentDayList.length) {
      selectedSubject = currentDayList[index];
    }

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$dayNameの${index + 1}時間目の教科を選択'),
              content: DropdownButton<String>(
                value: selectedSubject,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                items: _buildDropdownMenuItems(),
                isExpanded: true,
              ),
              actions: <Widget>[
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
            );
          },
        );
      },
    ).then((value) async {
      if (value != null) {
        await DataManager().updateDaySubject(day, index, value);
        await _loadData();
      }
    });
  }

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    Set<String> uniqueSubjects = subjects.toSet();
    List<String> sortedSubjects = uniqueSubjects.toList()..sort();
    sortedSubjects.insert(0, ''); // 空の選択肢を最初に追加

    return sortedSubjects.map((String subject) {
      return DropdownMenuItem<String>(
        value: subject,
        child: Text(
          subject.isEmpty ? '(なし)' : subject,
          style: TextStyle(fontSize: 16),
        ),
      );
    }).toList();
  }

  void showAddSubjectDialog(BuildContext context) async {
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
                            title: Text(subjects[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await DataManager()
                                    .deleteSubject(subjects[index]);
                                await _loadData();
                                setState(() {});
                              },
                            ),
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
                  onPressed: () async {
                    String subjectName = textEditingController.text.trim();
                    if (subjectName.isNotEmpty &&
                        !await DataManager().subjectExists(subjectName)) {
                      await DataManager().addSubject(subjectName);
                      await _loadData();
                      setState(() {});
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

  void showChangeTimesDialog(BuildContext context) async {
    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('時間数を選択してください'),
          content: DropdownButton<int>(
            value: times,
            onChanged: (value) async {
              if (value != null) {
                await DataManager().updateTimes(value);
                await _loadData();
                Navigator.of(context).pop();
              }
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
          ),
        );
      },
    );
  }

  void updateSaturdayEnabled(bool value) async {
    await DataManager().updateSaturdayEnabled(value);
    await _loadData();
  }

  void updateSundayEnabled(bool value) async {
    await DataManager().updateSundayEnabled(value);
    await _loadData();
  }

  bool get saturday => _saturday;
  bool get sunday => _sunday;
}