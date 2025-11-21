import 'dart:async';
import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // 1초마다 현재 시간 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    // yyyy-MM-dd (요일) 형식
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[(dt.weekday - 1) % 7];

    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');

    return '$y-$m-$d ($weekday)';
  }

  String _formatTime(DateTime dt) {
    // 24시간 → 12시간 (15시 = 3시), 초 제거 (h:mm)
    final h24 = dt.hour;
    int h12 = h24 % 12;
    if (h12 == 0) h12 = 12;

    final m = dt.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 위 여백 (날짜/시간 조금 내리기용)
              const SizedBox(height: 60),

              // 날짜 + 시간
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(_now),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_now),
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // 날짜/시간과 버튼 사이의 공간
              const Spacer(),

              // 하단 버튼 블럭 (위로 조금 끌어올리기 위해 bottom padding 줄이고 Spacer 하나만 사용)
              Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 알람 미루기 버튼 (위, 조금 더 작게)
                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 알람 미루기 로직 추가
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          '알람 미루기',
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), //버튼 사이 간격

                    // 끄기 버튼 (아래, 좀 더 큼)
                    SizedBox(
                      width: 330,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 실제 알람 끄기(사운드 정지 등) 로직 추가
                          Navigator.of(context).maybePop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text(
                          '알람 끄기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
