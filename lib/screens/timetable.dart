import 'package:flutter/material.dart';
import '../model/firestore_timetables.dart';
import '../model/firestore_subjects.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();

  void showChangeTimesDialog(BuildContext context) {}

  Widget buildTimetableSpecificMenuItems(BuildContext context) {
    return _TimeTableScreenState().buildTimetableSpecificMenuItems(context);
  }
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  final TimetableRepository _timetableRepository = TimetableRepository();
  final SubjectsRepository _subjectsRepository = SubjectsRepository();

  late Timetable _timetable;
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    String uid = 'test_fir'; // Replace with actual user ID
    _timetable = await _timetableRepository.getTimetable(uid) ??
        Timetable(
          enableSat: true,
          enableSun: true,
          mon: List.filled(10, ''),
          tue: List.filled(10, ''),
          wed: List.filled(10, ''),
          thu: List.filled(10, ''),
          fri: List.filled(10, ''),
          sat: List.filled(10, ''),
          sun: List.filled(10, ''),
          times: 6,
        );
    _subjects = await _subjectsRepository.getAllSubjects(uid);

    setState(() {
      _isLoading = false;
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
                  if (_timetable.enableSat)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('土'),
                    ),
                  if (_timetable.enableSun)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('日'),
                    ),
                ],
              ),
              for (int i = 1; i <= _timetable.times; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: SizedBox(
                        height: 50,
                        child: Center(child: Text('$i')),
                      ),
                    ),
                    _buildTableCell(context, 'mon', _timetable.mon, i),
                    _buildTableCell(context, 'tue', _timetable.tue, i),
                    _buildTableCell(context, 'wed', _timetable.wed, i),
                    _buildTableCell(context, 'thu', _timetable.thu, i),
                    _buildTableCell(context, 'fri', _timetable.fri, i),
                    if (_timetable.enableSat)
                      _buildTableCell(context, 'sat', _timetable.sat, i),
                    if (_timetable.enableSun)
                      _buildTableCell(context, 'sun', _timetable.sun, i),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
      BuildContext context, String day, List<dynamic> list, int i) {
    return GestureDetector(
      onTap: () {
        _showInputDialog(context, day, i - 1);
      },
      child: Container(
        height: 50,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          list[i - 1].toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context, String day, int index) async {
    String? selectedSubject = '';
    List<dynamic> currentDayList;
    String dayName;
    switch (day) {
      case 'mon':
        currentDayList = _timetable.mon;
        dayName = '月曜日';
        break;
      case 'tue':
        currentDayList = _timetable.tue;
        dayName = '火曜日';
        break;
      case 'wed':
        currentDayList = _timetable.wed;
        dayName = '水曜日';
        break;
      case 'thu':
        currentDayList = _timetable.thu;
        dayName = '木曜日';
        break;
      case 'fri':
        currentDayList = _timetable.fri;
        dayName = '金曜日';
        break;
      case 'sat':
        currentDayList = _timetable.sat;
        dayName = '土曜日';
        break;
      case 'sun':
        currentDayList = _timetable.sun;
        dayName = '日曜日';
        break;
      default:
        currentDayList = [];
        dayName = '';
    }

    if (index < currentDayList.length) {
      selectedSubject = currentDayList[index].toString();
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
        await _timetableRepository.updateDaySubject(
            'current_user_uid', day, index, value);
        await _loadData();
      }
    });
  }

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    Set<String> uniqueSubjects = _subjects.toSet();
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

  Widget buildTimetableSpecificMenuItems(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("教科の追加"),
          trailing: Icon(Icons.add),
          onTap: () {
            _showAddSubjectDialog(context);
          },
        ),
        ListTile(
          title: Text("時間数の変更"),
          trailing: DropdownButton<int>(
            value: _timetable.times,
            onChanged: (int? newValue) async {
              if (newValue != null) {
                await _timetableRepository.updateTimes(
                    'current_user_uid', newValue);
                await _loadData();
              }
            },
            items: List.generate(
              10,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text('${index + 1}時間'),
              ),
            ),
          ),
        ),
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                SwitchListTile(
                  title: Text('土曜日を表示する'),
                  value: _timetable.enableSat,
                  onChanged: (bool value) async {
                    await _timetableRepository.updateSaturdayEnabled(
                        'current_user_uid', value);
                    await _loadData();
                  },
                ),
                SwitchListTile(
                  title: Text('日曜日を表示する'),
                  value: _timetable.enableSun,
                  onChanged: (bool value) async {
                    await _timetableRepository.updateSundayEnabled(
                        'current_user_uid', value);
                    await _loadData();
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddSubjectDialog(BuildContext context) async {
    TextEditingController textEditingController = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('教科を追加'),
              content: Container(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          if (_subjects[index].trim().isEmpty)
                            return Container();
                          return ListTile(
                            title: Text(
                              _subjects[index],
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await _subjectsRepository.deleteSubject(
                                    'current_user_uid', _subjects[index]);
                                await _loadData();
                                setDialogState(() {});
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
                        !_subjects.contains(subjectName)) {
                      await _subjectsRepository.addSubject(
                          'current_user_uid', subjectName);
                      await _loadData();
                      setDialogState(() {});
                      textEditingController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('教科を追加しました')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('すでに同じ名前の教科が存在するか空白です。')),
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
}
