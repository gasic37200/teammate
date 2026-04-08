import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';

class PlannerScorePage extends StatefulWidget {
  const PlannerScorePage({super.key});

  @override
  State<PlannerScorePage> createState() => _PlannerScorePageState();
}

class _PlannerScorePageState extends State<PlannerScorePage> {
  List<XFile> _files = [];
  bool _analyzing = false;
  Map<String, dynamic>? _result;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true);
    if (res != null) setState(() { _files = res.files.map((e) => e.xFile).toList(); _result = null; });
  }

  void _analyze() async {
    if (_files.isEmpty) return;
    setState(() => _analyzing = true);

    // 이곳에 ai 검사 로직을 넣으시면 됩니다
    await Future.delayed(const Duration(seconds: 2));

    final mock = {"total_score": 88, "summary": "기획 의도가 명확하고 논리적 구조가 탄탄합니다."};

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'plan_score': mock['total_score'],
        'plan_comment': mock['summary'],
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
            const Text("DOCUMENTATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            const Text("기획서(PDF)\n업로드", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
            const SizedBox(height: 40),

            DropTarget(
              onDragDone: (d) {
                final pdfs = d.files.where((f) => f.name.toLowerCase().endsWith('.pdf')).toList();
                if (pdfs.isNotEmpty) setState(() { _files = pdfs; _result = null; });
              },
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: _files.isEmpty
                      ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_upload_outlined, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("PDF 선택 (DRAG & DROP)", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0))
                      ]
                  ))
                      : ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (c, i) => ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.black),
                          title: Text(_files[i].name, style: const TextStyle(fontWeight: FontWeight.bold))
                      )
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
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
                    : Text("논리 분석 (${_files.length})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 60),
              const Divider(color: Colors.black),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("LOGIC SCORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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