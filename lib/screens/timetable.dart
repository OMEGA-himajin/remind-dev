import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  late Map<String, dynamic> data;
  bool _saturday = true; // 初期値を設定
  bool _sunday = true; // 初期値を設定
  int times = 6;

  List<String> mon = ['hoge', '', '', '', '', '', '', '', '', ''];
  List<String> tue = ['', '', '', '', '', '', '', '', '', ''];
  List<String> wed = ['', '', '', '', '', '', '', '', '', ''];
  List<String> thu = ['', '', '', '', '', '', '', '', '', ''];
  List<String> fri = ['', '', '', '', '', '', '', '', '', ''];
  List<String> sat = ['', '', '', '', '', '', '', '', '', ''];
  List<String> sun = ['', '', '', '', '', '', '', '', '', ''];

  late Map<String, dynamic> week;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    // JSONファイルのパス
    final directory = await getApplicationDocumentsDirectory();
    String jsonFilePath = '${directory.path}/timetable.json';

    try {
      // JSONファイルを読み込む
      String jsonString = await File(jsonFilePath).readAsString();

      // JSON文字列をMapオブジェクトに変換
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // フィールドにデータをセット
      setState(() {
        data = jsonData;
        times = data['times'];
        _saturday = data['enable_sat'] ?? true; // デフォルト値を設定
        _sunday = data['enable_sun'] ?? true; // デフォルト値を設定
        mon = List<String>.from(data['mon']); // データのコピー
        tue = List<String>.from(data['tue']);
        wed = List<String>.from(data['wed']);
        thu = List<String>.from(data['thu']);
        fri = List<String>.from(data['fri']);
        sat = List<String>.from(data['sat']);
        sun = List<String>.from(data['sun']);
      });
    } catch (e) {
      // エラーハンドリング
      print('JSONファイルの読み込みエラー: $e');
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
                });
              },
              items: List.generate(
                10,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(
                    '${index + 1}時間',
                    style: const TextStyle(fontSize: 16), // テキストの大きさを指定
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
                style: TextStyle(
                    fontSize: 16, color: Colors.black), // ヒントのテキストの大きさを指定
              ),
            ),
            const ListTile(
              title: Text("教科の追加"),
              trailing: Icon(Icons.arrow_forward),
            ),
            SwitchListTile(
              title: const Text('土曜日を表示する'),
              value: _saturday,
              onChanged: (bool value) {
                setState(() {
                  _saturday = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('日曜日を表示する'),
              value: _sunday,
              onChanged: (bool value) {
                setState(() {
                  _sunday = value;
                });
              },
            ),
            TextButton(
              onPressed: () async {
                _makejson();
                String json = jsonEncode(week);
                await _saveJsonToFile(json);
                print(json);
              },
              child: const Text('click here'),
            ),
          ],
        ),
      ),
      backgroundColor:
          const Color.fromARGB(255, 5, 53, 8), // Scaffold全体の背景色を緑に設定
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
              // 動的にTableRowを生成
              for (int i = 1; i <= times; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: SizedBox(
                        height: 50, // 固定の高さを設定
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

  Widget _buildTableCell(BuildContext context, String day, List<String> list, int i) {
    return GestureDetector(
      onTap: () {
        _showInputDialog(context, day, i - 1);
      },
      child: Container(
        height: 50, // 固定の高さを設定
        color: Colors.transparent, // 背景色を透明に設定
        alignment: Alignment.center,
        child: Text(
          list[i - 1],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _makejson() {
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
    };
  }

  Future<void> _saveJsonToFile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/timetable.json');
    await file.writeAsString(jsonString);
  }

  Future<void> _showInputDialog(
      BuildContext context, String day, int index) async {
    TextEditingController textEditingController = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('教科を入力してください'),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(hintText: "教科名"),
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
                setState(() {
                  switch (day) {
                    case 'mon':
                      mon[index] = textEditingController.text;
                      break;
                    case 'tue':
                      tue[index] = textEditingController.text;
                      break;
                    case 'wed':
                      wed[index] = textEditingController.text;
                      break;
                    case 'thu':
                      thu[index] = textEditingController.text;
                      break;
                    case 'fri':
                      fri[index] = textEditingController.text;
                      break;
                    case 'sat':
                      sat[index] = textEditingController.text;
                      break;
                    case 'sun':
                      sun[index] = textEditingController.text;
                      break;
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
