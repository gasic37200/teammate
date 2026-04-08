import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ProfileWidget.dart';

class MateListPage extends StatefulWidget {
  const MateListPage({super.key});

  @override
  State<MateListPage> createState() => _MateListPageState();
}

class _MateListPageState extends State<MateListPage> {
  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '개발자', '디자이너', '기획자'];

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('MEMBERS', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                String label = filter;
                if(filter == '전체') label = "ALL";
                else if(filter == '개발자') label = "DEV";
                else if(filter == '디자이너') label = "DESIGN";
                else if(filter == '기획자') label = "PLAN";

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                        borderRadius: BorderRadius.zero, // 직각 디자인
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading data'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((doc) => doc.id != myUid).toList();

                if (_selectedFilter != '전체') {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['job'] == _selectedFilter;
                  }).toList();
                }

                // Helper function to get the relevant score for a user
                num? getScore(Map<String, dynamic> data) {
                  switch (data['job']) {
                    case '개발자':
                      return data['code_score'] as num?;
                    case '디자이너':
                      return data['design_score'] as num?;
                    case '기획자':
                      return data['plan_score'] as num?;
                    default:
                      return null;
                  }
                }

                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final scoreA = getScore(dataA);
                  final scoreB = getScore(dataB);

                  if (scoreA != null && scoreB != null) {
                    return scoreB.compareTo(scoreA); // Descending order
                  } else if (scoreA != null) {
                    return -1; // A has score, B doesn't. A comes first.
                  } else if (scoreB != null) {
                    return 1;  // B has score, A doesn't. B comes first.
                  } else {
                    return 0;  // Both have no score. Keep original order.
                  }
                });

                if (docs.isEmpty) return const Center(child: Text("목록이 비어있습니다."));

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildMemberCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Unknown';
    final String job = data['job'] ?? 'None';
    final String? photoUrl = data['photoURL'];

    return GestureDetector(
      onTap: () {
        // 카드 전체 클릭 시 프로필로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileWidget(user: data, onProfileUpdated: (updatedUser) {})),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[100],
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(job, style: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.0)),
                ],
              ),
            ),

            // AI Grade/Score Badge
            if (data['job'] == "개발자" && data['code_score'] != null)
              _buildScoreBadge(data['code_score'])
            else if (data['job'] == "디자이너" && data['design_score'] != null)
              _buildScoreBadge(data['design_score'])
            else if (data['job'] == "기획자" &&data['plan_score'] != null)
              _buildScoreBadge(data['plan_score']),

            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(dynamic score) {
    String grade;
    Color gradeColor;

    if (score >= 95) {
      grade = '오리진 마스터';
      gradeColor = Colors.purpleAccent;
    } else if (score >= 90) {
      grade = '스페셜티 그레이드';
      gradeColor = Colors.lightBlue;
    } else if (score >= 80) {
      grade = '시그니처 블렌더';
      gradeColor = Colors.green;
    } else if (score >= 70) {
      grade = '브루잉 마스터';
      gradeColor = Colors.orange;
    } else {
      grade = '아메리카노';
      gradeColor = Colors.pink;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("$score", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(
          grade,
          style: TextStyle(
            fontSize: 15,
            color: gradeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
