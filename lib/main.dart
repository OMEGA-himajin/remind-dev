import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home.dart';
import 'screens/schedule.dart' as schedule;
import 'screens/timetable.dart';
import 'screens/item.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

String uid = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  String? themeModeString = prefs.getString('themeMode');
  ThemeMode themeMode;
  if (themeModeString == 'ThemeMode.light') {
    themeMode = ThemeMode.light;
  } else if (themeModeString == 'ThemeMode.dark') {
    themeMode = ThemeMode.dark;
  } else {
    themeMode = ThemeMode.system;
  }
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(MyApp(initialThemeMode: themeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeThemeMode(ThemeMode newThemeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = newThemeMode;
    });
    await prefs.setString('themeMode', newThemeMode.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タイトル',
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.white,
          surface: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'NotoSansJP',
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.grey[900]!,
          surface: Colors.grey[800]!,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: MyStatefulWidget(onThemeModeChanged: _changeThemeMode),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const MyStatefulWidget({super.key, required this.onThemeModeChanged});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static final List<Widget> _screens = [
    const HomeScreen(),
    const TimeTableScreen(),
    const schedule.ScheduleScreen(),
    const ItemsScreen(),
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
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      drawer: _buildCommonDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.table_view), label: '時間割'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'スケジュール'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: '持ち物'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'ホーム';
      case 1:
        return '時間割';
      case 2:
        return 'スケジュール';
      case 3:
        return '持ち物';
      default:
        return '';
    }
  }

  Widget _buildCommonDrawer(BuildContext context) {
    ThemeMode currentThemeMode = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      currentThemeMode = ThemeMode.system;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'メニュー',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('ホーム'),
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.table_view),
            title: Text('時間割'),
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('スケジュール'),
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books),
            title: Text('持ち物'),
            onTap: () {
              _onItemTapped(3);
              Navigator.pop(context);
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('テーマ', style: TextStyle(fontSize: 16)),
                DropdownButton<ThemeMode>(
                  value: currentThemeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      widget.onThemeModeChanged(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('システムテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('ライトテーマ'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('ダークテーマ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
