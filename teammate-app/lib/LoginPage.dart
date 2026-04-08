import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teammate_app/RegisterPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('remembered_email');
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  void _updateCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text);
    } else {
      await prefs.remove('remembered_email');
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.ease));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  void registerClicked() {
    Navigator.push(context, _createRoute(const RegisterPage()));
  }

  void loginClicked() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _updateCredentials();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '로그인 실패')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Image.asset(
                      "assets/images/g-logo.png",
                      fit: BoxFit.contain,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.hub, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("teammate_app", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4.0)),
                  const SizedBox(height: 8),
                  const Text("AI 기반 역량 분석 플랫폼", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.0)),
                  const SizedBox(height: 60),

                  _buildMinimalTextField(_emailController, "이메일", Icons.alternate_email),
                  const SizedBox(height: 20),
                  _buildMinimalTextField(_passwordController, "비밀번호", Icons.lock_outline, isObscure: true),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                          ),
                          const Text("로그인 유지", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("비밀번호 찾기", style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline)),
                      )
                    ],
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : loginClicked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1))
                          : const Text("로그인", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("처음 오셨나요? ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      GestureDetector(
                        onTap: registerClicked,
                        child: const Text("회원가입", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTextField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.black, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: (value) => (value == null || value.isEmpty) ? '$label을 입력해주세요.' : null,
    );
  }
}