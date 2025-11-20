import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common_layout.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  String goalTime = "08:00";

  // 주간 수면 데이터(시간 단위, 0.0~12.0)
  final List<double> sleepData = [7.0, 6.5, 8.0, 5.5, 9.0, 7.6, 12.0];
  final List<String> week = ["월", "화", "수", "목", "금", "토", "일"];

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
              onPressed: () {
                setState(() {
                  goalTime =
                  "${hourController.text.padLeft(2, '0')}:${minuteController.text.padLeft(2, '0')}";
                });
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

  // 최근 수면시간(배열 마지막, 데이터 없으면 0)
  double _recentHours() => sleepData.isNotEmpty ? sleepData.last : 0.0;

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
                                "Quality",
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
