import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart' as alarm; // 🔔 실제 기기 알람용
import 'common_layout.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 알람 데이터 모델
class Alarm {
  String? id;          // Firestore 문서 ID
  TimeOfDay time;      // 시간
  bool isEnabled;      // 알람 활/비활성
  List<String> days;   // 요일
  String label;        // 알람 이름
  bool vibrate;        // 진동

  Alarm({
    this.id,
    required this.time,
    this.isEnabled = true,
    required this.days,
    this.label = '',
    this.vibrate = true,
  });
}

class AlarmPage extends StatefulWidget {
  final int? alarm_strength;   // 1~4 강도 (볼륨용, 선택사항)

  const AlarmPage({
    super.key,
    this.alarm_strength,
  });

  @override
  State<AlarmPage> createState() => AlarmPageState();
}

class AlarmPageState extends State<AlarmPage> {
  final List<Alarm> alarmList = []; // 설정한 알람
  final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  // 여러 알람 쉽게 삭제
  bool _isEditing = false;
  final Set<int> selectedIndexes = {};

  /// 강도(1~4)에 따라 볼륨(0.0~1.0) 결정
  double get _volumeFromStrength {
    final s = widget.alarm_strength ?? 3;
    if (s <= 1) return 0.4;
    if (s == 2) return 0.6;
    if (s == 3) return 0.8;
    return 1.0;
  }

  @override
  void initState() {
    super.initState();
    _loadAlarmsFromFirestore();
  }

  /// Firestore에서 알람 불러오고 → OS 알람과 동기화
  Future<void> _loadAlarmsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser!;
    final String userId = user.displayName ?? user.uid;
    final dataList = await FirestoreService().loadAlarms(userId);

    final List<Alarm> loaded = [];

    for (final data in dataList) {
      loaded.add(
        Alarm(
          id: data["id"],
          time: TimeOfDay(
            hour: data["hour"],
            minute: data["minute"],
          ),
          isEnabled: data["isEnabled"] ?? true,
          label: data["label"] ?? "",
          vibrate: data["vibrate"] ?? true,
          days: List<String>.from(data["days"] ?? []),
        ),
      );
    }

    setState(() {
      alarmList
        ..clear()
        ..addAll(loaded);
    });

    // 👉 Firestore 상태에 맞춰 실제 기기 알람도 설정/해제
    for (final a in alarmList) {
      if (a.isEnabled) {
        await _scheduleDeviceAlarm(a);
      } else {
        await _cancelDeviceAlarm(a);
      }
    }
  }

  /// 실제 안드로이드/아이폰 알람 예약
  Future<void> _scheduleDeviceAlarm(Alarm alarmModel) async {
    if (alarmModel.id == null || !alarmModel.isEnabled) return;

    final now = DateTime.now();
    // 요일 설정 안 했으면 매일 울리게
    final activeDays =
    alarmModel.days.isEmpty ? List<String>.from(weekDays) : alarmModel.days;

    DateTime? nextDateTime;

    // 앞으로 7일 중 가장 가까운 울릴 시간 찾기
    for (int add = 0; add < 7; add++) {
      final date = now.add(Duration(days: add));
      final dayKor = weekDays[date.weekday - 1];
      if (!activeDays.contains(dayKor)) continue;

      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        alarmModel.time.hour,
        alarmModel.time.minute,
      );

      if (candidate.isAfter(now)) {
        if (nextDateTime == null || candidate.isBefore(nextDateTime)) {
          nextDateTime = candidate;
        }
      }
    }

    if (nextDateTime == null) return;

    // alarm 패키지에 쓸 고유 ID (문자열 hash)
    final int alarmId = alarmModel.id.hashCode & 0x7fffffff;

    final settings = alarm.AlarmSettings(
      id: alarmId,
      dateTime: nextDateTime,
      assetAudioPath: 'assets/good_morning1.mp3',
      loopAudio: true,
      vibrate: alarmModel.vibrate,
      volume: _volumeFromStrength,
      fadeDuration: 0.0,
      notificationTitle:
      alarmModel.label.isEmpty ? '알람' : alarmModel.label,
      notificationBody: '일어날 시간입니다.',
      enableNotificationOnKill: false,
      androidFullScreenIntent: true,
    );

    await alarm.Alarm.set(alarmSettings: settings);
  }

  /// 예약된 기기 알람 취소
  Future<void> _cancelDeviceAlarm(Alarm alarmModel) async {
    if (alarmModel.id == null) return;
    final int alarmId = alarmModel.id.hashCode & 0x7fffffff;
    await alarm.Alarm.stop(alarmId);
  }

  /// 알람 추가·수정 바텀시트 (UI는 네 코드 그대로)
  Future<void> _showAddAlarmSheet({Alarm? existingAlarm, int? index}) async {
    int hour = existingAlarm?.time.hourOfPeriod ?? 7;
    int minute = existingAlarm?.time.minute ?? 0;
    bool isAm = (existingAlarm?.time.period ?? DayPeriod.am) == DayPeriod.am;
    bool vibrate = existingAlarm?.vibrate ?? true;
    List<String> selectedDays = List.from(existingAlarm?.days ?? []);

    final TextEditingController labelController =
    TextEditingController(text: existingAlarm?.label ?? '');

    final hourController =
    FixedExtentScrollController(initialItem: 600 + (hour - 1));
    final minuteController =
    FixedExtentScrollController(initialItem: 3000 + minute);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF6FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 20,
                  left: 16,
                  right: 16,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "알람 설정",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        /// 알람 이름
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            labelText: "알람 이름",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 시간 Picker
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 70,
                              left: 0,
                              right: 0,
                              child:
                              Container(height: 1.2, color: Colors.black12),
                            ),
                            Positioned(
                              bottom: 70,
                              left: 0,
                              right: 0,
                              child:
                              Container(height: 1.2, color: Colors.black12),
                            ),
                            SizedBox(
                              height: 180,
                              child: Row(
                                children: [
                                  /// AM / PM
                                  Expanded(
                                    child: CupertinoPicker(
                                      itemExtent: 40,
                                      scrollController:
                                      FixedExtentScrollController(
                                          initialItem: isAm ? 0 : 1),
                                      onSelectedItemChanged: (i) =>
                                          setDialogState(() => isAm = i == 0),
                                      children: const [
                                        Center(
                                            child: Text("오전",
                                                style:
                                                TextStyle(fontSize: 22))),
                                        Center(
                                            child: Text("오후",
                                                style:
                                                TextStyle(fontSize: 22))),
                                      ],
                                    ),
                                  ),

                                  /// Hour
                                  Expanded(
                                    child: CupertinoPicker.builder(
                                      itemExtent: 40,
                                      scrollController: hourController,
                                      useMagnifier: true,
                                      onSelectedItemChanged: (i) {
                                        hour = (i % 12) + 1;
                                        if (i < 10 || i > 1190) {
                                          Future.microtask(() =>
                                              hourController.jumpToItem(
                                                  600 + (i % 12)));
                                        }
                                      },
                                      childCount: 1200,
                                      itemBuilder: (_, i) {
                                        return Center(
                                          child: Text(
                                            ((i % 12) + 1).toString(),
                                            style:
                                            const TextStyle(fontSize: 26),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const Text(":",
                                      style: TextStyle(fontSize: 26)),

                                  /// Minute
                                  Expanded(
                                    child: CupertinoPicker.builder(
                                      itemExtent: 40,
                                      scrollController: minuteController,
                                      useMagnifier: true,
                                      onSelectedItemChanged: (i) {
                                        minute = i % 60;
                                        if (i < 100 || i > 5900) {
                                          Future.microtask(() =>
                                              minuteController.jumpToItem(
                                                  3000 + (i % 60)));
                                        }
                                      },
                                      childCount: 6000,
                                      itemBuilder: (_, i) {
                                        return Center(
                                          child: Text(
                                            (i % 60)
                                                .toString()
                                                .padLeft(2, '0'),
                                            style:
                                            const TextStyle(fontSize: 26),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// 진동
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('진동 사용',
                                style: TextStyle(fontSize: 16)),
                            Switch(
                              value: vibrate,
                              onChanged: (v) =>
                                  setDialogState(() => vibrate = v),
                              thumbColor:
                              WidgetStateProperty.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? Colors.amber
                                    : Colors.grey;
                              }),
                              trackColor:
                              WidgetStateProperty.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? Colors.amber.withAlpha(120)
                                    : Colors.grey.withAlpha(120);
                              }),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// 요일 선택
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: weekDays.map((day) {
                            final selected = selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selected
                                      ? selectedDays.remove(day)
                                      : selectedDays.add(day);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.amber[600]
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: selected
                                          ? Colors.amber
                                          : Colors.grey,
                                      width: 1.5),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        /// 저장 / 취소 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.black,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  "취소",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final user =
                                  FirebaseAuth.instance.currentUser!;
                                  final String userId =
                                      user.displayName ?? user.uid;
                                  final hour24 =
                                  isAm ? hour % 12 : (hour % 12) + 12;

                                  if (selectedDays.isEmpty) {
                                    selectedDays = List.from(weekDays);
                                  }

                                  final alarmData = {
                                    "hour": hour24,
                                    "minute": minute,
                                    "days": selectedDays,
                                    "label":
                                    labelController.text.trim(),
                                    "vibrate": vibrate,
                                    "isEnabled":
                                    existingAlarm?.isEnabled ?? true,
                                  };

                                  if (index != null) {
                                    final alarmId = alarmList[index].id!;
                                    await FirestoreService().updateAlarm(
                                        userId, alarmId, alarmData);
                                  } else {
                                    // 새 알람 저장(반환값이 ID일 가능성 높지만,
                                    // 여기서는 일단 저장만 하고 다시 전체 로드해서 ID 채움)
                                    await FirestoreService()
                                        .saveAlarm(userId, alarmData);
                                  }

                                  await _loadAlarmsFromFirestore();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  "저장",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 다음 울릴 알람 계산 (요일 + 'n일 후' + 1분 이내 표현까지)
  String? getNextAlarmText() {
    // 켜져 있는 알람만 가져오기
    final enabled = alarmList.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;

    final now = DateTime.now();

    int? minDiffSeconds; // 가장 가까운 알람까지 남은 시간(초)

    final Map<String, int> weekdayIndex = {
      '월': DateTime.monday,
      '화': DateTime.tuesday,
      '수': DateTime.wednesday,
      '목': DateTime.thursday,
      '금': DateTime.friday,
      '토': DateTime.saturday,
      '일': DateTime.sunday,
    };

    for (final alarm in enabled) {
      // 요일 선택 안 했으면 매일 울리는 알람으로 간주
      final List<String> alarmDays =
      alarm.days.isEmpty ? weekDays : alarm.days;

      for (final dayLabel in alarmDays) {
        final int? targetWeekday = weekdayIndex[dayLabel];
        if (targetWeekday == null) continue;

        int dayDiff = targetWeekday - now.weekday;
        if (dayDiff < 0) {
          dayDiff += 7;
        }

        DateTime candidate = DateTime(
          now.year,
          now.month,
          now.day,
          alarm.time.hour,
          alarm.time.minute,
        ).add(Duration(days: dayDiff));

        Duration diff = candidate.difference(now);

        // 오늘 이미 지난 시간이면 다음 주 같은 시간으로
        if (diff.inSeconds <= 0) {
          diff = diff + const Duration(days: 7);
        }

        final int diffSeconds = diff.inSeconds;

        if (minDiffSeconds == null || diffSeconds < minDiffSeconds!) {
          minDiffSeconds = diffSeconds;
        }
      }
    }

    if (minDiffSeconds != null) {
      final int totalSeconds = minDiffSeconds!;
      final int days = totalSeconds ~/ (24 * 60 * 60); // 며칠 후인지
      final int afterDays = totalSeconds % (24 * 60 * 60);
      final int hours = afterDays ~/ 3600;
      final int afterHours = afterDays % 3600;
      final int minutes = afterHours ~/ 60;
      final int seconds = afterHours % 60;

      // ✅ 1일 이상 남았을 때
      if (days > 0) {
        if (hours > 0 && minutes > 0) {
          return "${days}일 ${hours}시간 ${minutes}분 후에 울려요";
        } else if (hours > 0) {
          return "${days}일 ${hours}시간 후에 울려요";
        } else if (minutes > 0) {
          return "${days}일 ${minutes}분 후에 울려요";
        } else {
          // 정확히 n일 뒤 (예: 24시간, 48시간 딱 맞을 때)
          return "${days}일 후에 울려요";
        }
      }

      // ✅ 하루 이내
      if (hours > 0) {
        if (minutes > 0) {
          return "${hours}시간 ${minutes}분 후에 울려요";
        } else {
          return "${hours}시간 후에 울려요";
        }
      }

      // ✅ 1시간 이내
      if (minutes > 0) {
        return "${minutes}분 후에 울려요";
      }

      // ✅ 1분 미만
      if (seconds > 0) {
        return "1분 이내에 울려요";
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: "Alarm",
      currentIndex: 0,
      body: Stack(
        children: [
          Column(
            children: [
              /// 다음 알람 + 휴지통
              Padding(
                padding: const EdgeInsets.only(
                    top: 10, left: 16, right: 16, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        getNextAlarmText() ?? "등록된 알람이 없어요.",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.delete,
                        color: Colors.black,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          selectedIndexes.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

              /// 알람 리스트
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      top: 0, left: 16, right: 16, bottom: 16),
                  itemCount: alarmList.length,
                  itemBuilder: (_, i) {
                    final alarm = alarmList[i];
                    final period =
                    alarm.time.period == DayPeriod.am ? "오전" : "오후";
                    final hour = alarm.time.hourOfPeriod;
                    final minute =
                    alarm.time.minute.toString().padLeft(2, '0');

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        onTap: () {
                          if (_isEditing) {
                            setState(() {
                              selectedIndexes.contains(i)
                                  ? selectedIndexes.remove(i)
                                  : selectedIndexes.add(i);
                            });
                          } else {
                            _showAddAlarmSheet(
                                existingAlarm: alarm, index: i);
                          }
                        },

                        leading: const Icon(Icons.access_alarm,
                            color: Colors.black87),

                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (alarm.label.isNotEmpty)
                              Text(
                                alarm.label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                      text: "$period ",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: "$hour:$minute",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: weekDays.map((day) {
                            final isSelected = alarm.days.contains(day);
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                day,
                                style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey),
                              ),
                            );
                          }).toList(),
                        ),

                        trailing: _isEditing
                            ? Checkbox(
                          value: selectedIndexes.contains(i),
                          onChanged: (checked) {
                            setState(() {
                              checked == true
                                  ? selectedIndexes.add(i)
                                  : selectedIndexes.remove(i);
                            });
                          },
                        )
                            : Switch(
                          value: alarm.isEnabled,
                          onChanged: (v) async {
                            // 로컬 UI 업데이트
                            setState(() => alarm.isEnabled = v);

                            // Firestore 업데이트
                            final user =
                            FirebaseAuth.instance.currentUser!;
                            final String userId =
                                user.displayName ?? user.uid;
                            await FirestoreService().updateAlarm(
                              userId,
                              alarm.id!, // Firestore 문서 ID
                              {"isEnabled": v},
                            );

                            // 실제 기기 알람 설정/해제
                            if (v) {
                              await _scheduleDeviceAlarm(alarm);
                            } else {
                              await _cancelDeviceAlarm(alarm);
                            }

                            setState(() {});
                          },
                          thumbColor:
                          WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? Colors.amber
                              : Colors.grey),
                          trackColor:
                          WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? Colors.amber.withAlpha(128)
                              : Colors.grey.withAlpha(128)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          /// 선택 삭제 버튼
          if (_isEditing && selectedIndexes.isNotEmpty)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser!;
                  final String userId = user.displayName ?? user.uid;
                  final toDelete = selectedIndexes.toList()
                    ..sort((a, b) => b.compareTo(a));

                  // 1) Firestore 삭제 + OS 알람 취소
                  for (final idx in toDelete) {
                    final alarm = alarmList[idx];
                    if (alarm.id != null) {
                      await FirestoreService()
                          .deleteAlarm(userId, alarm.id!);
                      await _cancelDeviceAlarm(alarm);
                    }
                  }

                  setState(() {
                    for (final idx in toDelete) {
                      alarmList.removeAt(idx);
                    }
                    selectedIndexes.clear();
                    _isEditing = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("선택한 알람이 삭제되었습니다.")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "선택한 알람 삭제",
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          /// + 버튼
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _showAddAlarmSheet(),
              backgroundColor: Colors.amber,
              shape: const CircleBorder(),
              child: const Icon(Icons.add,
                  color: Colors.black, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
