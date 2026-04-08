import 'package:flutter/material.dart';
import 'DeveloperScorePage.dart';
import 'DesignerScorePage.dart';
import 'PlannerScorePage.dart';

class AIScorePage extends StatelessWidget {
  const AIScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('DIAGNOSIS', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI 역량 진단을\n시작합니다.", // 멘트 변경 완료
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, height: 1.3, color: Colors.black, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Container(width: 40, height: 2, color: Colors.black),
            const SizedBox(height: 60),

            _buildGalleryCard(
              context,
              number: "01",
              title: "DEVELOPER",
              desc: "코드 품질 & 아키텍처 분석",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeveloperScorePage())),
            ),
            const SizedBox(height: 24),

            _buildGalleryCard(
              context,
              number: "02",
              title: "DESIGNER",
              desc: "시각적 조화 & 트렌드 분석",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DesignerScorePage())),
            ),
            const SizedBox(height: 24),

            _buildGalleryCard(
              context,
              number: "03",
              title: "PLANNER",
              desc: "논리 구조 & 기획력 검증",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannerScorePage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, {required String number, required String title, required String desc, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
}