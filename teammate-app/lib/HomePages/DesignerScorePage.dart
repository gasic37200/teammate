import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';

class DesignerScorePage extends StatefulWidget {
  const DesignerScorePage({super.key});

  @override
  State<DesignerScorePage> createState() => _DesignerScorePageState();
}

class _DesignerScorePageState extends State<DesignerScorePage> {
  List<XFile> _files = [];
  bool _analyzing = false;
  Map<String, dynamic>? _result;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (res != null) setState(() { _files = res.files.map((e) => e.xFile).toList(); _result = null; });
  }

  void _analyze() async {
    if (_files.isEmpty) return;
    setState(() => _analyzing = true);

    // 이곳에 ai 검사 로직을 넣으시면 됩니다
    await Future.delayed(const Duration(seconds: 2));

    final mock = {"total_score": 92, "summary": "색채 조화와 레이아웃 균형이 탁월합니다. 트렌디한 디자인입니다."};

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'design_score': mock['total_score'],
        'design_comment': mock['summary'],
        'portfolio_url': 'https://via.placeholder.com/400',
      });
    }

    if (mounted) setState(() { _analyzing = false; _result = mock; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PORTFOLIO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            const Text("작품 업로드", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
            const SizedBox(height: 40),

            DropTarget(
              onDragDone: (d) => setState(() { _files = d.files; _result = null; }),
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  width: double.infinity,
                  height: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: _files.isEmpty
                      ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("이미지 선택 (DRAG & DROP)", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.0))
                      ]
                  ))
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _files.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: kIsWeb ? Image.network(_files[i].path) : Image.file(File(_files[i].path)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_files.isEmpty || _analyzing) ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: _analyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1))
                    : Text("분석하기 (${_files.length})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 60),
              const Divider(color: Colors.black),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("VISUAL SCORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                Text("${_result!['total_score']}", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w100)),
              ]),
              const SizedBox(height: 20),
              Text(_result!['summary'], style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}