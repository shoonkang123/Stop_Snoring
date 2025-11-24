import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart' as alarm; // 🔔 알람 정지/재설정용

class AlarmScreen extends StatefulWidget {
  /// 처음 알람 강도 (1~5)
  final int initialStrength;

  /// 지금까지 미룬 횟수 (0~3)
  final int initialSnoozeCount;

  const AlarmScreen({
    super.key,
    this.initialStrength = 1,
    this.initialSnoozeCount = 0,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late DateTime _now;
  Timer? _timer;

  /// ✅ 알람을 미룬 횟수 (최대 3번까지)
  late int snoozeCount;

  /// ✅ 현재 알람 강도 (1~5)
  late int _currentStrength;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // 초기 강도 세팅 (1~5 범위로 보정)
    int s = widget.initialStrength;
    if (s < 1) s = 1;
    if (s > 5) s = 5;
    _currentStrength = s;

    // 지금까지 미룬 횟수 세팅 (0~3 범위로 보정)
    int sc = widget.initialSnoozeCount;
    if (sc < 0) sc = 0;
    if (sc > 3) sc = 3;
    snoozeCount = sc;

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
    // 24시간 → 12시간, 초 제거 (h:mm)
    final h24 = dt.hour;
    int h12 = h24 % 12;
    if (h12 == 0) h12 = 12;

    final m = dt.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  /// ✅ 강도(1~5)에 따른 볼륨(0.0~1.0)
  double _volumeFromStrength(int s) {
    if (s <= 1) return 0.4; // 40%
    if (s == 2) return 0.6; // 60%
    if (s == 3) return 0.8; // 80%
    // 4,5 → 100%
    return 1.0;
  }

  /// ✅ 강도(1~5)에 따른 알람 사운드
  String _audioFromStrength(int s) {
    if (s == 4) {
      return 'assets/siren4.mp3';
    } else if (s >= 5) {
      return 'assets/siren5.mp3';
    } else {
      // 1, 2, 3
      return 'assets/good_morning1.mp3';
    }
  }

  /// ✅ 5분 고정 미루기 로직
  /// - snoozeCount >= 3 이면 더 이상 미루기 X
  /// - 미룰 때마다 snoozeCount++, 강도 +1 (최대 5)
  Future<void> _onSnoozePressed() async {
    // 이미 3번 미뤘으면 더 이상 미루지 않음
    if (snoozeCount >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알람은 최대 3번까지만 미룰 수 있어요.'),
          ),
        );
      }
      return;
    }

    // 1) 스누즈 카운트 + 강도 +1
    setState(() {
      snoozeCount += 1; // 🔢 1~3까지 올라감
      if (_currentStrength < 5) {
        _currentStrength += 1;
      }
    });

    // 2) 지금 울리는 알람 모두 정지
    await alarm.Alarm.stopAll();

    // 3) 5분 뒤로 새 알람 예약
    final DateTime newTime =
    DateTime.now().add(const Duration(minutes: 5));
    //  테스트용 5초로 쓰고 싶으면 위 줄 대신 아래 주석 풀기
     //final DateTime newTime =
         //DateTime.now().add(const Duration(seconds: 5));

    final int newId =
    DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

    final double volume = _volumeFromStrength(_currentStrength);
    final String audioPath = _audioFromStrength(_currentStrength);

    // notificationBody 에 snoozeCount를 같이 넣어둔다.
    // ringStream 에서 다시 꺼내서 다음 AlarmScreen 으로 넘길 것.
    final String bodyText =
        'SNOOZE:$snoozeCount|알람이 5분 뒤에 다시 울립니다.';

    final newSettings = alarm.AlarmSettings(
      id: newId,
      dateTime: newTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      volume: volume,
      fadeDuration: 0.0,
      notificationTitle: '알람',
      notificationBody: bodyText,
      enableNotificationOnKill: false,
      androidFullScreenIntent: true,
    );

    await alarm.Alarm.set(alarmSettings: newSettings);

    // 4) 현재 알람 화면 닫기
    if (mounted) {
      Navigator.of(context).pop();
    }
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
              const SizedBox(height: 60),

              // 날짜 + 시간
              Column(
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

              const Spacer(),

              // 하단 버튼들
              Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 알람 미루기
                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        onPressed: _onSnoozePressed,
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
                    const SizedBox(height: 60),

                    // 알람 끄기
                    SizedBox(
                      width: 330,
                      child: ElevatedButton(
                        onPressed: () async {
                          await alarm.Alarm.stopAll();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          '알람 끄기',
                          style: TextStyle(
                            fontSize: 19,
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
