import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

// 以下、コメントアウトされた元のコード
/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

String? _errorMessage;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // FirebaseAuth インスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ログイン状態を保持する変数
  User? _user;

  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    // ログイン状態の変化を監視
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: Text("Item 1"),
              trailing: const Icon(Icons.arrow_forward),
            ),
            ListTile(
              title: Text("Item 2"),
              trailing: const Icon(Icons.arrow_forward),
            ),
            if (_user != null) // ログインしている場合のみ表示
              ListTile(
                title: const Text("Sign Out"),
                onTap: _signOut,
              ),
          ],
        ),
      ),
      body: _user == null ? _buildSignInForm() : _buildUserInfo(),
    );
  }

  Widget _buildSignInForm() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // メールアドレス入力用テキストフィールド
            TextFormField(
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              onChanged: (String value) {
                setState(() {
                  _email = value;
                });
              },
            ),
            // パスワード入力用テキストフィールド
            TextFormField(
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
              onChanged: (String value) {
                setState(() {
                  _password = value;
                });
              },
            ),
            // ログインボタン
            ElevatedButton(
              child: const Text('ログイン'),
              onPressed: () async {
                try {
                  // メール/パスワードでログイン
                  await _auth.signInWithEmailAndPassword(
                    email: _email,
                    password: _password,
                  );
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString(); // エラーメッセージを保持
                    _error_log();
                  });
                  print(e);
                }
              },
            ),
            ElevatedButton(
              child: const Text('ユーザ登録'),
              onPressed: () async {
                try {
                  final UserCredential userCredential = await FirebaseAuth
                      .instance
                      .createUserWithEmailAndPassword(
                    email: _email,
                    password: _password,
                  );
                  final User? user = userCredential.user;
                  if (user != null) {
                    print("ユーザ登録しました ${user.email} , ${user.uid}");
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString(); // エラーメッセージを保持
                  });
                  print(e);
                }
              },
            ),
            ElevatedButton(
                child: const Text('パスワードリセット'),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: _email);
                    print("パスワードリセット用のメールを送信しました");
                  } catch (e) {
                    print(e);
                    setState(() {
                      _errorMessage = e.toString(); // エラーメッセージを保持
                      _error_log();
                    });
                  }
                }),
            _error_log()
          ],
        ),
      ),
    );
  }

  Widget _error_log() {
    if (_errorMessage != null) {
      return Text(_errorMessage.toString(),
          style: TextStyle(color: Colors.red));
    }
    // エラーメッセージが null の場合は何も返さない
    return SizedBox(); // または適切な空のウィジェットを返す
  }

  Widget _buildUserInfo() {
    return Center(
      child: Text(
        'ようこそ ${_user!.email} さん',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  // サインアウト処理
  void _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
*/