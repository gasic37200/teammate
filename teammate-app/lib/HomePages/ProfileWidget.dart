import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';

class ProfileWidget extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>)? onProfileUpdated;
  final bool isReadOnly;

  const ProfileWidget({
    super.key,
    required this.user,
    this.onProfileUpdated,
    this.isReadOnly = false,
  });

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _introController;
  late TextEditingController _githubController;

  String? _selectedJob;
  final List<String> _jobOptions = ['개발자', '디자이너', '기획자'];

  XFile? _pickedProfileImage; // 프로필 사진
  XFile? _pickedPortfolioFile; // 포트폴리오 파일 (이미지 or PDF)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _introController = TextEditingController(text: widget.user['introduction']);
    _githubController = TextEditingController(text: widget.user['github']);

    _selectedJob = widget.user['job'];
  }

  // 프로필 이미지 선택 (갤러리)
  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _pickedProfileImage = pickedFile);
  }

  // 포트폴리오 파일 선택 (직군에 따라 다름)
  Future<void> _pickPortfolioFile() async {
    if (_selectedJob == '디자이너') {
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      if (res != null) setState(() => _pickedPortfolioFile = res.files.single.xFile);
    } else if (_selectedJob == '기획자') {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res != null) setState(() => _pickedPortfolioFile = res.files.single.xFile);
    }
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);

    String? photoURL = widget.user['photoURL'];
    String? portfolioURL = widget.user['portfolio_url'];

    // 1. 프로필 이미지 업로드
    if (_pickedProfileImage != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_images/${widget.user['uid']}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if(kIsWeb) await ref.putData(await _pickedProfileImage!.readAsBytes()); else await ref.putFile(File(_pickedProfileImage!.path));
      photoURL = await ref.getDownloadURL();
    }

    // 2. 포트폴리오 파일 업로드 (디자이너/기획자)
    if (_pickedPortfolioFile != null) {
      // 파일 확장자 추출
      String ext = _pickedPortfolioFile!.name.split('.').last;
      final ref = FirebaseStorage.instance.ref().child('portfolios/${widget.user['uid']}_${DateTime.now().millisecondsSinceEpoch}.$ext');

      if(kIsWeb) await ref.putData(await _pickedPortfolioFile!.readAsBytes());
      else await ref.putFile(File(_pickedPortfolioFile!.path));

      portfolioURL = await ref.getDownloadURL();
    }

    // 3. Firestore 업데이트 데이터 구성
    final updateData = {
      'name': _nameController.text,
      'introduction': _introController.text,
      'photoURL': photoURL,
      'job': _selectedJob ?? '미설정',
      'github': (_selectedJob == '개발자') ? _githubController.text : '',
      'portfolio_url': portfolioURL, // 포트폴리오 URL 업데이트
    };

    await FirebaseFirestore.instance.collection('users').doc(widget.user['uid']).update(updateData);

    if(widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(Map<String, dynamic>.from(widget.user)..addAll(updateData));
    }

    // 초기화
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _pickedPortfolioFile = null;
      _pickedProfileImage = null;
    });
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    String finalUrl = urlString.trim();
    if (!finalUrl.startsWith('http')) {
      finalUrl = 'https://$finalUrl';
    }
    final Uri url = Uri.parse(finalUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentJob = _selectedJob ?? '미설정';
    final bool isDeveloper = currentJob == '개발자';
    final bool isDesigner = currentJob == '디자이너';
    final bool isPlanner = currentJob == '기획자';

    // 기존 포트폴리오 URL 확인
    final bool hasPortfolio = widget.user['portfolio_url'] != null && widget.user['portfolio_url'].isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.isReadOnly ? 'MEMBER PROFILE' : (_isEditing ? 'EDIT PROFILE' : 'MY PROFILE'),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16)),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: widget.isReadOnly ? [] : [
          _isEditing
              ? IconButton(icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.blueAccent), onPressed: _isSaving ? null : _saveProfile)
              : IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.black), onPressed: () => setState(() => _isEditing = true)),
          if(!_isEditing) IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 프로필 상단 (이미지 & 이름 & 직군) ===
            Row(children: [
              GestureDetector(
                onTap: _isEditing ? _pickProfileImage : null,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!, width: 1)),
                  child: ClipOval(
                    child: _pickedProfileImage != null
                        ? (kIsWeb ? Image.network(_pickedProfileImage!.path, fit: BoxFit.cover) : Image.file(File(_pickedProfileImage!.path), fit: BoxFit.cover))
                        : (widget.user['photoURL'] != null ? Image.network(widget.user['photoURL'], fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.grey, size: 40)),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _isEditing
                    ? TextField(controller: _nameController, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "이름"))
                    : Text(widget.user['name'] ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                const SizedBox(height: 4),

                _isEditing
                    ? DropdownButton<String>(
                  value: _jobOptions.contains(currentJob) ? currentJob : null,
                  hint: const Text("직군을 선택하세요"),
                  isDense: true,
                  underline: Container(height: 1, color: Colors.grey),
                  items: _jobOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedJob = newValue;
                      _pickedPortfolioFile = null; // 직군 변경 시 선택된 파일 초기화
                    });
                  },
                )
                    : Text(currentJob, style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 1.0)),
              ]))
            ]),

            const SizedBox(height: 40),

            // === 소개글 ===
            const Text("INTRODUCTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _isEditing
                ? TextField(controller: _introController, maxLines: 4, decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()))
                : Text(widget.user['introduction'] ?? '등록된 소개가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),

            // === 개발자 Github 입력 (수정 모드) ===
            if (_isEditing && isDeveloper) ...[
              const SizedBox(height: 24),
              const Text("GITHUB URL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              TextField(controller: _githubController, decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
            ],

            const SizedBox(height: 40),
            const Divider(color: Colors.black, thickness: 1),
            const SizedBox(height: 40),

            // === AI 역량 점수 ===
            const Text("AI COMPETENCY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildStatBlock("CODE QUALITY", widget.user['code_score'], widget.user['code_comment']),
            const SizedBox(height: 30),
            _buildStatBlock("VISUAL SENSE", widget.user['design_score'], widget.user['design_comment']),
            const SizedBox(height: 30),
            _buildStatBlock("PLANNING LOGIC", widget.user['plan_score'], widget.user['plan_comment']),

            const SizedBox(height: 40),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 40),

            const Text("PORTFOLIO / LINK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 24),

            // === 포트폴리오 업로드 UI ===
            if (_isEditing) ...[
              if (isDesigner)
                GestureDetector(
                  onTap: _pickPortfolioFile,
                  child: Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey[300]!)),
                    child: _pickedPortfolioFile != null
                        ? (kIsWeb ? Image.network(_pickedPortfolioFile!.path, fit: BoxFit.cover) : Image.file(File(_pickedPortfolioFile!.path), fit: BoxFit.cover))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_photo_alternate_outlined, color: Colors.grey), SizedBox(height: 8), Text("새로운 디자인 이미지 업로드", style: TextStyle(color: Colors.grey))]),
                  ),
                )
              else if (isPlanner)
                GestureDetector(
                  onTap: _pickPortfolioFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    height: 80, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey[300]!)),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        const SizedBox(width: 16),
                        Expanded(child: Text(_pickedPortfolioFile != null ? "선택됨: ${_pickedPortfolioFile!.name}" : "새로운 기획서(PDF) 업로드", style: const TextStyle(fontWeight: FontWeight.bold))),
                        const Icon(Icons.upload_file, color: Colors.grey),
                      ],
                    ),
                  ),
                )
              else if (isDeveloper)
                  const Text("개발자는 위에서 Github 링크를 수정해주세요.", style: TextStyle(color: Colors.grey)),
            ]
            // == 저장된 포트폴리오 보기 ===
            else ...[
              if (isDeveloper && widget.user['github'] != null && widget.user['github'].isNotEmpty)
                InkWell(
                  onTap: () => _launchUrl(widget.user['github']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(children: [const Icon(Icons.link, size: 20, color: Colors.blueAccent), const SizedBox(width: 8), Expanded(child: Text(widget.user['github'], style: const TextStyle(fontSize: 16, color: Colors.blueAccent, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis))]),
                  ),
                )
              else if (isDesigner && hasPortfolio)
                _buildFadedImagePreview(widget.user['portfolio_url'])
              else if (isPlanner && hasPortfolio)
                  _buildFadedDocPreview()
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("등록된 포트폴리오가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 14))),
                  ),
            ],

            const SizedBox(height: 40),
            const Text("CONTACT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Text(widget.user['email'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, dynamic scoreRaw, String? comment) {
    num score = scoreRaw ?? 0;
    if (score == 0) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), Text("$score", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(0), child: LinearProgressIndicator(value: score / 100.0, backgroundColor: Colors.grey[200], color: Colors.black, minHeight: 4)),
      if (comment != null) ...[const SizedBox(height: 12), Text(comment, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5))]
    ]);
  }

  Widget _buildFadedImagePreview(String url) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.transparent], stops: [0.6, 1.0]).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
      blendMode: BlendMode.dstIn,
      child: Container(height: 250, width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover))),
    );
  }

  Widget _buildFadedDocPreview() {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.transparent], stops: [0.5, 1.0]).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
      blendMode: BlendMode.dstIn,
      child: Container(
        height: 100, width: double.infinity, color: Colors.grey[100], padding: const EdgeInsets.all(24),
        child: const Row(children: [Icon(Icons.picture_as_pdf, color: Colors.redAccent), SizedBox(width: 8), Text("PLANNING_DOC.pdf", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))]),
      ),
    );
  }
}