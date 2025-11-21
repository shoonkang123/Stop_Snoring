import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    required this.avgBedTime,
    required this.avgWakeTime,
  });

  final String avgBedTime;   // 예: '23:30'
  final String avgWakeTime;  // 예: '07:30'

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Firestore / Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore에서 가져올 값들
  String? _name;
  int? _age;
  String? _gender;

  bool _loading = true;
  String? _errorMsg;

  // 배경색(살짝 핑크 톤)
  static const Color _bgColor = Color(0xFFFFF1F5);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final String userId = user.displayName!;

      // 🔹 Firestore 경로:
      // users_kim / {displayName} / users_info / information
      final infoSnap = await FirebaseFirestore.instance
          .collection('users_kim')
          .doc(userId)
          .collection('users_info')
          .doc('information')
          .get();

      if (!infoSnap.exists) {
        setState(() {
          _errorMsg = '사용자 정보(information) 문서를 찾을 수 없습니다.';
          _loading = false;
        });
        return;
      }

      final data = infoSnap.data()!;
      print('information data = $data'); // 디버그용

      setState(() {
        _name   = data['name'] as String? ?? '';
        _age    = (data['age'] as num?)?.toInt();
        _gender = data['gender'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyChild;

    if (_loading) {
      bodyChild = const Center(child: CircularProgressIndicator());
    } else if (_errorMsg != null) {
      bodyChild = Center(
        child: Text(
          _errorMsg!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    } else {
      bodyChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserInfoCard(
            name: _name ?? '-',
            age: _age ?? 0,
            gender: _gender ?? '-',
          ),
          const SizedBox(height: 16),
          SleepPatternCard(
            avgBedTime: widget.avgBedTime,
            avgWakeTime: widget.avgWakeTime,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '메뉴',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bodyChild,
      ),
    );
  }
}

/// 사용자 정보 카드
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
  });

  final String name;
  final int age;
  final String gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.black12,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.amber,
              ),
              SizedBox(width: 8),
              Text(
                '사용자 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Colors.black12,
            thickness: 1,
          ),
          const SizedBox(height: 12),
          Text(
            '이름 : $name',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '나이 : ${age}세',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '성별 : $gender',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// 수면 패턴 카드
class SleepPatternCard extends StatefulWidget {
  const SleepPatternCard({
    super.key,
    required this.avgBedTime,
    required this.avgWakeTime,
  });

  final String avgBedTime;
  final String avgWakeTime;

  @override
  State<SleepPatternCard> createState() => _SleepPatternCardState();
}

class _SleepPatternCardState extends State<SleepPatternCard> {
  final List<String> _wakeOptions = [
    '0회',
    '1회',
    '2회',
    '3회',
    '4회 이상',
  ];

  String _wakeCount = '0회';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.black12,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.nightlight_round,
                color: Colors.amber,
              ),
              SizedBox(width: 8),
              Text(
                '수면 패턴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Colors.black12,
            thickness: 1,
          ),
          const SizedBox(height: 12),
          _buildLabelValueRow(
            label: '평균 자는 시간',
            value: widget.avgBedTime,
          ),
          const SizedBox(height: 6),
          _buildLabelValueRow(
            label: '평균 일어나는 시간',
            value: widget.avgWakeTime,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  '수면 중 깨는 횟수',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _wakeCount,
                borderRadius: BorderRadius.circular(12),
                items: _wakeOptions
                    .map(
                      (opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _wakeCount = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildLabelValueRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
