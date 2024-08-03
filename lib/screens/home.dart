import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart' as main;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインエラー: $e')),
      );
    }
  }

  Future<void> _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アカウント作成エラー: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    setState(() {
      main.uid = '';
    });
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスを入力してください')),
      );
      return;
    }
    
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードリセットメールを送信しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('パスワードリセットエラー: $e')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      setState(() {
        main.uid = userCredential.user?.uid ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Googleログインエラー: $e')),
      );
    }
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
        ),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'パスワード'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _signIn,
          child: const Text('ログイン'),
        ),
        ElevatedButton(
          onPressed: _signUp,
          child: const Text('アカウント作成'),
        ),
        TextButton(
          onPressed: _resetPassword,
          child: const Text('パスワードを忘れた場合'),
        ),
        ElevatedButton(
          onPressed: _signInWithGoogle,
          child: const Text('Googleでログイン'),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Text('ようこそ、${_user?.email}さん'),
        const SizedBox(height: 16),
        Text('ユーザーUID: ${main.uid}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _signOut,
          child: const Text('ログアウト'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _user == null ? _buildAuthForm() : _buildHomeContent(),
      ),
    );
  }
}