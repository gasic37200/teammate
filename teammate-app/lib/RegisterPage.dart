import 'package:flutter/material.dart';
import 'package:teammate_app/RegisterDetailPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['남성', '여성'];

  bool _isPasswordVisible = false;

  void _nextClicked() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
        'birthdate': _birthdateController.text,
        'gender': _selectedGender,
        'job': '미설정',
      };

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => RegisterDetailPage(userData: userData),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.ease));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _birthdateController.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('JOIN US', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("기본 정보 입력", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    cursorColor: Colors.black,
                    decoration: _inputDecoration("이메일", Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '이메일을 입력해주세요';
                      if (!value.contains('@') || !value.contains('.')) return '올바른 이메일 형식이 아닙니다';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    cursorColor: Colors.black,
                    decoration: _inputDecoration("비밀번호", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
                      if (value.length < 6) return '비밀번호는 6자리 이상이어야 합니다';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildInput(_nameController, "이름", Icons.person_outline),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _birthdateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    cursorColor: Colors.black,
                    decoration: _inputDecoration("생년월일", Icons.calendar_today),
                    validator: (v) => v!.isEmpty ? '생년월일을 선택해주세요' : null,
                  ),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    dropdownColor: Colors.white,
                    items: _genders.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                    decoration: _inputDecoration("성별", Icons.wc),
                    validator: (v) => v == null ? '성별을 선택해주세요' : null,
                  ),

                  const SizedBox(height: 50),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextClicked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('다음 단계', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      cursorColor: Colors.black,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? '$label을 입력해주세요' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.black, size: 20),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
    );
  }
}