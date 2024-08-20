import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'home.dart';
import '../main.dart' as main;
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const WelcomeScreen({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  bool _isMainScreen = true;

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      setState(() {
        main.uid = userCredential.user?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Googleログインエラー: $e')),
      );
    }
  }

  Future<void> _signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedAnonymousUid = prefs.getString('anonymousUid');

      if (storedAnonymousUid != null) {
        // 既存の匿名アカウントでサインイン
        await _auth.signInAnonymously();
      } else {
        // 新しい匿名アカウントを作成
        final UserCredential userCredential = await _auth.signInAnonymously();
        final String? newAnonymousUid = userCredential.user?.uid;
        if (newAnonymousUid != null) {
          await prefs.setString('anonymousUid', newAnonymousUid);
        }
      }

      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ゲストログインエラー: $e')),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインエラー: $e')),
      );
    }
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが一致しません')),
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        main.uid = _auth.currentUser?.uid ?? '';
      });
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アカウント作成エラー: $e')),
      );
    }
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

  void _navigateToHome() {
    widget.onLoginSuccess();
  }

  Widget _buildMainScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ようこそ remind dev へ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SignInButton(
          Buttons.email,
          text: "メールで続行",
          onPressed: () => setState(() => _isMainScreen = false),
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(height: 16),
        SignInButton(
          Buttons.google,
          text: "Googleで続行",
          onPressed: _signInWithGoogle,
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(height: 16),
        SignInButton(
          Buttons.anonymous,
          text: "ゲストモードで続行",
          onPressed: _signInAsGuest,
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  Widget _buildEmailAuthScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        if (!_isLogin)
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'パスワード（確認）'),
            obscureText: true,
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLogin ? _signInWithEmail : _signUp,
          child: Text(_isLogin ? 'ログイン' : 'アカウント作成'),
        ),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? 'アカウントを作成' : 'ログイン画面に戻る'),
        ),
        if (_isLogin)
          TextButton(
            onPressed: _resetPassword,
            child: const Text('パスワードをリセット'),
          ),
        TextButton(
          onPressed: () => setState(() => _isMainScreen = true),
          child: const Text('戻る'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: _isMainScreen ? _buildMainScreen() : _buildEmailAuthScreen(),
          ),
        ),
      ),
    );
  }

  
}
