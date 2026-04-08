import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _introController;
  late TextEditingController _githubController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _introController = TextEditingController(text: widget.user['introduction']);
    _githubController = TextEditingController(text: widget.user['github']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/user_db.json');
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final dbFile = await _localFile;
      List<dynamic> users = [];
      if (await dbFile.exists()) {
        users = jsonDecode(await dbFile.readAsString());
      }

      final updatedUser = {
        ...widget.user,
        'name': _nameController.text,
        'introduction': _introController.text,
        'github': _githubController.text,
      };

      final userIndex = users.indexWhere((user) => user['email'] == widget.user['email']);
      if (userIndex != -1) {
        users[userIndex] = updatedUser;
      }

      await dbFile.writeAsString(jsonEncode(users));

      // Update shared preferences if user is logged in
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('isLoggedIn') ?? false) {
        await prefs.setString('user', jsonEncode(updatedUser));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );

      Navigator.pop(context, updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _introController,
                decoration: const InputDecoration(labelText: '자기소개'),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              if (widget.user['job'] == '개발자')
                TextFormField(
                  controller: _githubController,
                  decoration: const InputDecoration(labelText: 'GitHub 링크'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
