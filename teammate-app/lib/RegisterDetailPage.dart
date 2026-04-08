import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class RegisterDetailPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RegisterDetailPage({super.key, required this.userData});

  @override
  State<RegisterDetailPage> createState() => _RegisterDetailPageState();
}

class _RegisterDetailPageState extends State<RegisterDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _githubController = TextEditingController();
  final _introController = TextEditingController();
  bool _isLoading = false;

  FilePickerResult? _pickedPortfolioFile;

  Future<void> _pickPortfolio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        _pickedPortfolioFile = result;
      });
    }
  }

  // Simulate AI grading based on user data and job type
  Future<Map<String, dynamic>> _getAIGrade(String job) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    final random = Random();
    final score = 60 + random.nextInt(41); // 60-100

    switch (job) {
      case '개발자':
        return {
          'code_score': score,
          'code_comment': '생성된 코드의 품질이 전반적으로 우수하며, 최신 Flutter 관행을 잘 따르고 있습니다. 몇몇 부분에서 위젯 트리를 최적화할 수 있는 여지가 보입니다.',
        };
      case '디자이너':
        return {
          'design_score': score,
          'design_comment': '제출된 포트폴리오의 색상 조합과 레이아웃 구성이 매우 인상적입니다. 사용자 경험에 대한 깊은 이해가 느껴집니다.',
        };
      case '기획자':
        return {
          'plan_score': score,
          'plan_comment': '기획서의 논리 구조가 명확하고, 비즈니스 목표와 사용자 요구사항을 균형 있게 고려한 점이 돋보입니다.',
        };
      default:
        return {};
    }
  }

  void _registerClicked() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.userData['email']!,
        password: widget.userData['password']!,
      );

      if (credential.user != null) {
        final newUser = {
          ...widget.userData,
          'uid': credential.user!.uid,
          'github': _githubController.text,
          'introduction': _introController.text,
        };

        String? portfolioUrl;
        if (_pickedPortfolioFile != null) {
          final file = _pickedPortfolioFile!.files.first;
          final ref = FirebaseStorage.instance
              .ref('portfolios/${credential.user!.uid}/${file.name}');

          UploadTask uploadTask;
          if (kIsWeb) {
            final fileBytes = file.bytes;
            uploadTask = ref.putData(fileBytes!);
          } else {
            final filePath = file.path;
            uploadTask = ref.putFile(File(filePath!));
          }
          final snapshot = await uploadTask;
          portfolioUrl = await snapshot.ref.getDownloadURL();
        }

        if (portfolioUrl != null) {
          newUser['portfolio_url'] = portfolioUrl;
        }

        // Get AI Grade based on job and add it to the user data
        final aiData = await _getAIGrade(newUser['job']);
        newUser.addAll(aiData);

        // Remove password before saving to firestore
        newUser.remove('password');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser);

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? '회원가입에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추가 정보 입력'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("간단한 자기소개를 적어주세요."),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _introController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '자기소개',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '자기소개를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (widget.userData['job'] == '개발자') ...[
                    const Text("깃허브 닉네임을 적어주세요."),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _githubController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'your-username',
                      ),
                    ),
                  ] else if (widget.userData['job'] == '디자이너' ||
                      widget.userData['job'] == '기획자') ...[
                    const Text("포트폴리오를 업로드해주세요 (이미지 또는 PDF).."),
                    const SizedBox(height: 8.0),
                    ElevatedButton.icon(
                      onPressed: _pickPortfolio,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('파일 선택'),
                    ),
                    if (_pickedPortfolioFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            '선택된 파일: ${_pickedPortfolioFile!.files.first.name}'),
                      ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerClicked,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('회원가입'),
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
}
