import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  String goalTime = "08:00";

  // 0:월 ~ 6:일
  List<double> sleepData = List<double>.filled(7,0.0);

  //달성률 계산에 사용할 가장 최근 수면 시간
  double last_Sleep_duration_hours = 0.0;

  // 주간 수면 데이터(시간 단위, 0.0~12.0)
  final List<String> week = ["월", "화", "수", "목", "금", "토", "일"];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 목표 수면 시간 로드
    _loadGoalTimeFromFirestore();
    // firestore에 수면 데이터 가져오기
    _loadSleepFromFirestore();
  }

  Future<void> _loadGoalTimeFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String userId = user.displayName!;

      final infoRef = FirebaseFirestore.instance
        .collection("users_kim")
        .doc(userId)
        .collection("users_info")
        .doc("information");

      final snap = await infoRef.get();
      if (!snap.exists) return;

      final data = snap.data();
      final stored = data?["goal_sleep_time"] as String?;

      if (stored != null && stored.isNotEmpty) {
        setState(() {
          goalTime = stored; // 예: "07:30"
        });
      }
    } catch (e) {
      print("load goal_sleep_time error: $e");
    }
  }

  Future<void> _saveGoalTimeToFirestore(String hhmm) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String userId = user.displayName!;

      final infoRef = FirebaseFirestore.instance
          .collection("users_kim")
          .doc(userId)
          .collection("users_info")
          .doc("information");

      await infoRef.set(
        {"goal_sleep_time": hhmm},
        SetOptions(merge: true),
      );
    } catch (e) {
      print("save goal_sleep_time error: $e");
    }
  }

  //수면 데이터 불러오기 + 해당 요일 한개 + 그 주 데이터 가져오기
  Future<void> _loadSleepFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final String userId = user.displayName!;

      final colRef = FirebaseFirestore.instance
          .collection("users_kim")
          .doc(userId)
          .collection("Sleep_data");

      // 가장 최근 수면 1개 가져오기
      final lastSnap = await colRef
          .orderBy("created_at", descending: true)
          .limit(1)
          .get();
      // 기록이 하나도 없으면 -> 전부 0
      if (lastSnap.docs.isEmpty) {
        setState(() {
          sleepData = List<double>.filled(7, 0.0);
          last_Sleep_duration_hours = 0.0;
          _isLoading = false;
        });
        return;
      }

      final lastDoc = lastSnap.docs.first;
      final lastData = lastDoc.data();

      //crated_at에서 dataTime 뽑기
      final Timestamp ts = lastData["created_at"] as Timestamp;
      final DateTime created = ts.toDate();

      // 가장 최근 수면시간(Sleep_duration) 달성률 박스에 사용
      final durAny = lastData["Sleep_duration"] ?? lastData["sleep_duration"];
      double lastSleepHours = 0.0;
      if (durAny is num){
        lastSleepHours = durAny.toDouble();
      }

      // created가 속하 "주"의 월요일 0시~ 다음 주 월요일 0시 계산
      final dayOnly = DateTime(created.year, created.month, created.day);
      final int weekday = dayOnly.weekday;
      final DateTime weekStart = dayOnly.subtract(Duration(days: weekday - 1));
      final DateTime weekEnd = weekStart.add(const Duration(days: 7)); // 다음주 월요일 0시

      // 3) 그 주에 속한 모든 수면 기록 가져오기
      final weekSnap = await colRef
          .where("created_at",
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where("created_at",
            isLessThan: Timestamp.fromDate(weekEnd))
          .orderBy("created_at")
          .get();

      // 요일별로 값 채우기 (0:월 ~ 6:일)
      final List<double> weekData = List<double>.filled(7, 0.0);

      for (final doc in weekSnap.docs) {
        final data = doc.data();
        final w = data["Weekday"] ?? data["weekday"];
        final d = data["Sleep_duration"] ?? data["sleep_duration"];

        if (w is num && d is num) {
          final idx = w.toInt() % 7;   // 0~6
          weekData[idx] = d.toDouble();  // 그 요일의 가장 최근 값으로 덮어씀
        }
      }

      setState(() {
        sleepData = weekData;
        last_Sleep_duration_hours = lastSleepHours;
        _isLoading = false;
      });
    } catch (e) {
      print("sleep data load error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _recentHours() => last_Sleep_duration_hours;

  // 두 카드(버튼) 동일 높이 — 살짝 키워 오버플로우 방지
  static const double cardHeight = 140.0;

  Future<void> _openGoalDialog() async {
    final parts = goalTime.split(":");
    final hourController = TextEditingController(text: parts[0]);
    final minuteController = TextEditingController(text: parts[1]);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          title: const Text("목표 수면 시간 입력", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "시간", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: TextField(
                  controller: minuteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "분", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                final newGoal = "${hourController.text.padLeft(2, '0')}:${minuteController.text.padLeft(2, '0')}";
                setState(() {
                  goalTime = newGoal;
                });

                await _saveGoalTimeToFirestore(newGoal);
                Navigator.pop(context);
              },
              child: const Text("저장"),
            ),
          ],
        );
      },
    );
  }

  // "HH:MM" -> double(시간)
  double _goalToHours(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    return h + (m / 60.0);
  }

  // 품질(달성률) 퍼센트 "87%" (목표 0이면 "--%")
  String _qualityPercent() {
    final recent = _recentHours();
    final goal = _goalToHours(goalTime);
    if (goal <= 0.0) return "--%";
    final pct = (recent / goal) * 100.0;
    final clamped = pct.isFinite ? pct.clamp(0.0, 9999.0) : 0.0;
    return "${clamped.round()}%";
  }

  // 7.5 -> "7h 30m", 7.0 -> "7h"
  String _fmtHMOneLine(double v) {
    final h = v.floor();
    int m = ((v - h) * 60.0).round();
    if (m == 60) return "${h + 1}h";
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  // 시간(double) -> 라벨 2줄: ["7h"] 또는 ["7h","30m"]
  List<String> _formatHM2Lines(double value) {
    final int h = value.floor();
    int m = ((value - h) * 60.0).round();
    if (m == 60) return ['${h + 1}h']; // 반올림 보정
    if (m == 0) return ['${h}h'];
    return ['${h}h', '${m}m'];
  }

  // 막대 + 내부 두 줄 라벨
  Widget _bar(double hours, double barHeight) {
    const double maxH = 12.0;
    final double ratio = (hours / maxH).clamp(0.0, 1.0);
    final double fillH = barHeight * ratio;
    final lines = _formatHM2Lines(hours);

    // 라벨을 채움 높이 중앙쯤에, 오버플로우 방지 보정
    final double desiredBottom = (fillH / 2.0) - 14.0;
    final double bottom = desiredBottom.clamp(6.0, barHeight - 28.0);

    return SizedBox(
      width: 27.0,
      height: barHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 회색 배경 막대
          Container(
            width: 27.0,
            height: barHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          // 노란 채움
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: fillH,
              width: 27.0,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
          // 내부 라벨(두 줄)
          Positioned(
            bottom: bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lines[0], // '7h'
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2.0, color: Colors.black26)],
                  ),
                ),
                if (lines.length > 1)
                  Text(
                    lines[1], // '30m'
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black26)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double desiredBarHeight = 350.0;  // 그래프 최대 높이
    const double weekdayLabelHeight = 22.0; // 요일 텍스트 높이
    const double gapBarToWeek = 6.0;        // 막대-요일 간격
    const double leftAxisWidth = 36.0;      // 왼쪽 눈금 폭

    final recentStr = _fmtHMOneLine(_recentHours());
    final goalStr = _fmtHMOneLine(_goalToHours(goalTime));
    final qualityStr = _qualityPercent();

    return CommonLayout(
      currentIndex: 2,
      title: "sleep tracker",
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10.0),

              // 그래프 섹션(오버플로우 방지)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double available = constraints.maxHeight;
                    final double barHeight = math.max<double>(
                      160.0,
                      math.min<double>(
                        desiredBarHeight,
                        available - weekdayLabelHeight - gapBarToWeek,
                      ),
                    );

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 눈금 + 막대
                        SizedBox(
                          height: barHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 왼쪽 눈금(등간격, 막대와 동일 높이)
                              SizedBox(
                                width: leftAxisWidth,
                                height: barHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text("12h"),
                                    Text("10h"),
                                    Text("8h"),
                                    Text("6h"),
                                    Text("4h"),
                                    Text("2h"),
                                    Text("0h"),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12.0),

                              // 막대들
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(
                                    sleepData.length,
                                        (i) => _bar(sleepData[i], barHeight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: gapBarToWeek),

                        // 요일(그래프 밖, 각 막대 아래)
                        Row(
                          children: [
                            SizedBox(width: leftAxisWidth + 12.0),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  week.length,
                                      (i) => SizedBox(
                                    width: 27.0,
                                    height: weekdayLabelHeight,
                                    child: Text(
                                      week[i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20.0),

              // 하단 카드(동일 높이 + FittedBox로 자동 축소)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 목표 수면 시간 카드
                  Expanded(
                    child: GestureDetector(
                      onTap: _openGoalDialog,
                      child: SizedBox(
                        height: cardHeight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          margin: const EdgeInsets.only(right: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(158, 158, 158, 0.25),
                                blurRadius: 6.0,
                                offset: Offset(0.0, 3.0),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "목표 수면 시간",
                                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  goalTime,
                                  style: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Quality 카드
                  Expanded(
                    child: SizedBox(
                      height: cardHeight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        margin: const EdgeInsets.only(left: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(158, 158, 158, 0.25),
                              blurRadius: 6.0,
                              offset: Offset(0.0, 3.0),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "달성률",
                                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                qualityStr, // 예: "75%"
                                style: const TextStyle(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "최근: $recentStr / 목표: $goalStr",
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
