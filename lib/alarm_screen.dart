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
    // HH:mm:ss 형식
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 중앙 상단: 현재 날짜 & 시간
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
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const Spacer(),

            // 가운데 안내 텍스트
            const Text(
              '알람 울리는 중',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // 중앙 하단: 알람 미루기 + 끄기 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 알람 미루기 버튼 (UI만, 로직 없음)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 알람 미루기 로직 추가
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      '알람 미루기',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 끄기 버튼 (중앙 하단)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 실제 알람 끄기(사운드 정지 등) 로직 추가
                      Navigator.of(context).maybePop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      '끄기',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
