import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 사용자 기본 정보
  String? _name;
  int? _age;
  String? _gender;

  // 수면 패턴 정보
  String _avgBedTime = '--:--';
  String _avgWakeTime = '--:--';
  String _wakeCountLabel = '0회';

  // Firestore 업데이트용 키
  String? _userDocId;        // users_kim/{userId}
  String? _latestSleepDocId; // Sleep_data/{docId}

  bool _loading = true;
  String? _errorMsg;

  static const Color _bgColor = Color(0xFFFFF1F5);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMsg = '로그인된 사용자가 없습니다.';
          _loading = false;
        });
        return;
      }

      // displayName 에 user_id("kksy0317")가 들어있다고 가정
      final String userId = user.displayName!;
      _userDocId = userId;

      await _loadUserInfo(userId);   // 이름/나이/성별 + awakenings(초기값)
      await _loadSleepStats(userId); // 최근 7일 sin/cos → 시간 평균

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _loading = false;
      });
    }
  }

  /// users_kim/{userId}/users_info/information 에서 기본 정보 + awakenings
  Future<void> _loadUserInfo(String userId) async {
    final infoSnap = await _db
        .collection('users_kim')
        .doc(userId)
        .collection('users_info')
        .doc('information')
        .get();

    if (!infoSnap.exists) {
      _errorMsg ??= '사용자 정보(information) 문서를 찾을 수 없습니다.';
      return;
    }

    final data = infoSnap.data()!;
    _name = data['name'] as String? ?? '';
    _age = (data['age'] as num?)?.toInt();
    _gender = data['gender'] as String? ?? '';

    // 🔹 깨어남 횟수 초기값 (소문자 awakenings)
    final awNum = (data['awakenings'] as num?)?.toInt() ?? 0;
    _wakeCountLabel = _intToWakeLabel(awNum);
  }

  /// Sleep_data 에서 최근 7개의 Bed/Wake sin-cos 평균
  Future<void> _loadSleepStats(String userId) async {
    final querySnap = await _db
        .collection('users_kim')
        .doc(userId)
        .collection('Sleep_data')
        .orderBy('created_at', descending: true) // timestamp 대신 날짜 필드 사용해도 됨
        .limit(7)
        .get();

    if (querySnap.docs.isEmpty) return;

    double sumBedSin = 0;
    double sumBedCos = 0;
    double sumWakeSin = 0;
    double sumWakeCos = 0;
    int count = 0;

    // 가장 최근 문서 id (필요하면 여기 것도 같이 업데이트 가능)
    final latestDoc = querySnap.docs.first;
    _latestSleepDocId = latestDoc.id;

    for (final doc in querySnap.docs) {
      final data = doc.data();

      final bedSin = (data['Bed_sin'] as num?)?.toDouble();
      final bedCos = (data['Bed_cos'] as num?)?.toDouble();
      final wakeSin = (data['Wake_sin'] as num?)?.toDouble();
      final wakeCos = (data['Wake_cos'] as num?)?.toDouble();

      if (bedSin == null ||
          bedCos == null ||
          wakeSin == null ||
          wakeCos == null) {
        continue;
      }

      sumBedSin += bedSin;
      sumBedCos += bedCos;
      sumWakeSin += wakeSin;
      sumWakeCos += wakeCos;
      count++;
    }

    if (count == 0) return;

    final avgBedSin = sumBedSin / count;
    final avgBedCos = sumBedCos / count;
    final avgWakeSin = sumWakeSin / count;
    final avgWakeCos = sumWakeCos / count;

    _avgBedTime = _timeFromSinCos(avgBedSin, avgBedCos);
    _avgWakeTime = _timeFromSinCos(avgWakeSin, avgWakeCos);
  }

  /// sin, cos → HH:mm
  String _timeFromSinCos(double sinVal, double cosVal) {
    final angle = math.atan2(sinVal, cosVal); // -pi ~ pi
    final twoPi = 2 * math.pi;
    double norm = angle < 0 ? angle + twoPi : angle; // 0 ~ 2pi
    final fracOfDay = norm / twoPi; // 0 ~ 1

    final totalMinutes = (fracOfDay * 24 * 60).round();
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 숫자 → 드롭다운 라벨
  String _intToWakeLabel(int n) {
    if (n <= 0) return '0회';
    if (n == 1) return '1회';
    if (n == 2) return '2회';
    if (n == 3) return '3회';
    return '4회 이상';
  }

  /// 드롭다운 라벨 → 숫자 (Firestore에 저장용)
  int _wakeLabelToInt(String label) {
    switch (label) {
      case '0회':
        return 0;
      case '1회':
        return 1;
      case '2회':
        return 2;
      case '3회':
        return 3;
      case '4회 이상':
        return 4;
      default:
        return 0;
    }
  }

  /// 드롭다운 변경 시 호출: users_info + (선택) Sleep_data 최신 문서 업데이트
  Future<void> _updateWakeCountOnFirestore(String newLabel) async {
    if (_userDocId == null) return;

    final newVal = _wakeLabelToInt(newLabel);
    final userRef = _db.collection('users_kim').doc(_userDocId);

    // 1) 개인정보 쪽 업데이트 (users_info/information.awakenings)
    await userRef
        .collection('users_info')
        .doc('information')
        .update({'awakenings': newVal});

    // 2) 원하면 Sleep_data 최신 문서도 같이 업데이트
    if (_latestSleepDocId != null) {
      await userRef
          .collection('Sleep_data')
          .doc(_latestSleepDocId)
          .update({'Awakenings': newVal});
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
            avgBedTime: _avgBedTime,
            avgWakeTime: _avgWakeTime,
            initialWakeLabel: _wakeCountLabel,
            onWakeLabelChanged: (label) async {
              setState(() {
                _wakeCountLabel = label;
              });
              await _updateWakeCountOnFirestore(label);
            },
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
    required this.initialWakeLabel,
    required this.onWakeLabelChanged,
  });

  final String avgBedTime;       // 평균 자는 시간
  final String avgWakeTime;      // 평균 일어나는 시간
  final String initialWakeLabel; // '0회' ~ '4회 이상'
  final ValueChanged<String> onWakeLabelChanged;

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

  late String _wakeCount;

  @override
  void initState() {
    super.initState();
    _wakeCount = widget.initialWakeLabel;
  }

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
            label: '평균 취침 시간',
            value: widget.avgBedTime,
          ),
          const SizedBox(height: 6),
          _buildLabelValueRow(
            label: '평균 기상 시간',
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
                  widget.onWakeLabelChanged(value); // 상위에 알림 → Firestore 업데이트
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
