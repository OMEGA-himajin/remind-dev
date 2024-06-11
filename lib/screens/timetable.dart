import 'package:flutter/material.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  _TimeTableScreenState createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  bool _saturday = true;
  bool _sunday = true;
  int times = 6;
  List<String> mon = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> tue = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> wed = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> thu = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> fri = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> sat = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];
  List<String> sun = ['国語', '数学', '数学', '数学', '数学', '数学', '', '', '', ''];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割'),
      ),
      drawer: Drawer(
        elevation: 0,
        child: Container(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                child: const Text('Drawer Header'),
              ),
              TextField(
                onChanged: (value) {
                  // 入力が数字のみかチェック
                  if (RegExp(r'^[0-9]+$').hasMatch(value)) {
                    if(int.parse(value)<=10&&int.parse(value)>=1){
                    // 数字の場合、"times"変数に格納
                    setState(() {
                      times = int.parse(value);
                    });}
                  }
                },
                keyboardType: TextInputType.number, // 数字のみを入力可能にする
                decoration: InputDecoration(
                  border: OutlineInputBorder(), // 四角形の箱
                  hintText: '時間数を入力(1-10まで)', // 入力フィールドのプレースホルダーテキスト
                ),
              ),
              ListTile(
                title: const Text("教科の追加"),
                trailing: const Icon(Icons.arrow_forward),
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
            ],
          ),
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
              // ヘッダー行を動的に作成
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(' '),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('月'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('火'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('水'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('木'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('金'),
                  ),
                  if (_saturday)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          _showInputDialog(context);
                        },
                        child: Text('土'),
                      ),
                    ),
                  if (_sunday)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          _showInputDialog(context);
                        },
                        child: Text('日'),
                      ),
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(mon[i-1])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(tue[i-1])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(wed[i-1])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(thu[i-1])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(fri[i-1])),
                    ),
                    if (_saturday)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            _showInputDialog(context);
                          },
                          child: Center(child: Text(sat[i-1])),
                        ),
                      ),
                    if (_sunday)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            _showInputDialog(context);
                          },
                          child: Center(child: Text(sun[i-1])),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('値を入力'),
          content: TextField(
            onChanged: (value) {
            },
            decoration: const InputDecoration(
              hintText: '値を入力してください',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // 表示を更新するためにsetStateを呼び出す
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: TimeTableScreen(),
  ));
}
