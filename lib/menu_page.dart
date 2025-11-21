import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.avgBedTime,
    required this.avgWakeTime,
  });

  // 나중에 Firebase에서 받아서 넘겨줄 값들
  final String name;
  final int age;
  final String gender;
  final String avgBedTime;   // 예: '23:30'
  final String avgWakeTime;  // 예: '07:30'

  // 배경색(살짝 핑크 톤) 상수로 빼두기
  static const Color _bgColor = Color(0xFFFFF1F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor, // 배경과 동일한 색
        elevation: 0, // 앱바와 배경 사이 경계선 제거
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(); // 뒤로가기
          },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UserInfoCard(
              name: name,
              age: age,
              gender: gender,
            ),
            const SizedBox(height: 16),
            SleepPatternCard(
              avgBedTime: avgBedTime,
              avgWakeTime: avgWakeTime,
            ),
          ],
        ),
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
        color: Colors.white, // 카드 배경
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
          // 제목 영역
          const Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.amber, // 포인트 컬러
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

          // 내용 (Firebase 값 바인딩)
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
            '나이 : $age세',
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

  final String avgBedTime;   // 예: '23:30'
  final String avgWakeTime;  // 예: '07:30'

  @override
  State<SleepPatternCard> createState() => _SleepPatternCardState();
}

class _SleepPatternCardState extends State<SleepPatternCard> {
  // 드롭다운 옵션 (수면 중 깨는 횟수)
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
        color: Colors.white, // 카드 배경
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
          // 제목 영역
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

          // 평균 자는 시간 (수평 정렬)
          _buildLabelValueRow(
            label: '평균 자는 시간',
            value: widget.avgBedTime, // 🔹 Firebase 값 바인딩 예정
          ),
          const SizedBox(height: 6),

          // 평균 일어나는 시간 (수평 정렬)
          _buildLabelValueRow(
            label: '평균 일어나는 시간',
            value: widget.avgWakeTime, // 🔹 Firebase 값 바인딩 예정
          ),
          const SizedBox(height: 12),

          // 수면 중 깨는 횟수 (드롭다운)
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

  /// 라벨 + 값 한 줄 수평 정렬용 헬퍼
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
