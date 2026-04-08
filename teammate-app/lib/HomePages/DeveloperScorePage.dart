import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeveloperScorePage extends StatefulWidget {
  const DeveloperScorePage({super.key});

  @override
  State<DeveloperScorePage> createState() => _DeveloperScorePageState();
}

class _DeveloperScorePageState extends State<DeveloperScorePage> {
  final TextEditingController _urlController = TextEditingController();

  // 상태 변수들
  bool _isAnalyzing = false;
  bool _showResult = false;
  double _totalScore = 0.0;
  List<Map<String, dynamic>> _analysisItems = [];

  // 영문 키를 한글로 변환하는 헬퍼 함수 (필요에 따라 케이스 추가)
  String _translateKey(String key) {
    switch (key) {
      case 'readability': return '코드 가독성';
      case 'modularity': return '모듈화 구조';
      case 'efficiency': return '알고리즘 효율';
      case 'error_handling': return '예외 처리';
      case 'convention': return '코딩 컨벤션';
      default: return key; // 매칭 안되면 원래 키 반환
    }
  }

  void _startAnalysis() async {
    if (_urlController.text.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    // 1. 서버 주소 설정 (안드로이드 에뮬레이터라면 localhost 대신 10.0.2.2 사용 권장)
    final url = Uri.parse('http://localhost:8000/grading/developer');
    final githubName = _urlController.text;

    try {
      // 2. 실제 서버 요청
      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'github_name': githubName,
          })
      );

      if (response.statusCode == 200) {
        // 3. 데이터 파싱
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final resultData = responseData['result'] as Map<String, dynamic>;
        final finalScore = responseData['final_score'] as num? ?? 0.0;

        // 세부 항목 리스트 변환
        List<Map<String, dynamic>> items = [];
        String summaryText = ""; // Firebase에 저장할 요약 멘트 생성용

        resultData.forEach((key, value) {
          String kName = _translateKey(key);
          String reason = value['reason'] as String? ?? '내용 없음';

          items.add({
            'name': kName,
            'score': value['score'] as num? ?? 0,
            'reason': reason,
          });

          if(summaryText.length < 100) { // 요약이 너무 길지 않게 앞부분만 연결
            summaryText += "$kName: $reason\n";
          }
        });

        // 4. Firebase Firestore 업데이트
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'code_score': finalScore,       // 실제 점수
            'code_comment': summaryText,    // 실제 분석 내용 (요약)
            'github': githubName,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        // 5. UI 상태 업데이트
        if (mounted) {
          setState(() {
            _totalScore = finalScore.toDouble();
            _analysisItems = items;
            _showResult = true;
          });
        }
      } else {
        print('서버 에러: ${response.statusCode}, ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('분석 중 오류가 발생했습니다.')));
        }
      }
    } catch (e) {
      print('요청 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('서버에 연결할 수 없습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("REPOSITORY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            const Text("Github 코드\n정밀 분석", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
            const SizedBox(height: 50),

            TextField(
              controller: _urlController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                labelText: "Github ID / URL",
                labelStyle: TextStyle(color: Colors.grey),
                hintText: "Github 아이디를 입력하세요",
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            const SizedBox(height: 60),

            // 분석 버튼
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: _isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1))
                    : const Text("분석 시작", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ),
            ),

            // 결과 표시 영역
            if (_showResult) ...[
              const SizedBox(height: 60),
              const Divider(color: Colors.black, thickness: 1),
              const SizedBox(height: 30),

              // 총점 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL SCORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Text(_totalScore.toStringAsFixed(1), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w100)),
                ],
              ),
              const SizedBox(height: 40),

              const Text("DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 20),

              // 세부 분석 항목 리스트
              ListView.builder(
                shrinkWrap: true, // ScrollView 안에 있으므로 필수
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _analysisItems.length,
                itemBuilder: (context, index) {
                  final item = _analysisItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("${item['score']}점", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['reason'], style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}