import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' as main;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        main.uid = user?.uid ?? '';
      });
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    setState(() {
      main.uid = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('ようこそ、${_user?.email ?? 'ゲスト'}さん'),
            const SizedBox(height: 16),
            Text('ユーザーUID: ${main.uid}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signOut,
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }
}