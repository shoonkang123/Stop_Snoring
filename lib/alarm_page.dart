import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'common_layout.dart';

/// 알람 데이터 모델
class Alarm {
  TimeOfDay time;
  bool isEnabled;
  List<String> days;
  String label;
  bool vibrate;

  Alarm({
    required this.time,
    this.isEnabled = true,
    required this.days,
    this.label = '',
    this.vibrate = true,
  });
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => AlarmPageState();
}

class AlarmPageState extends State<AlarmPage> {
  final List<Alarm> alarmList = [];
  final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  bool _isEditing = false;
  final Set<int> selectedIndexes = {};

  /// 알람 추가·수정 바텀시트
  Future<void> _showAddAlarmSheet({Alarm? existingAlarm, int? index}) async {
    int hour = existingAlarm?.time.hourOfPeriod ?? 8;
    int minute = existingAlarm?.time.minute ?? 0;
    bool isAm = existingAlarm?.time.period == DayPeriod.am;
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
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          child: Container(height: 1.2, color: Colors.black12),
                        ),
                        Positioned(
                          bottom: 70,
                          left: 0,
                          right: 0,
                          child: Container(height: 1.2, color: Colors.black12),
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
                                            style: TextStyle(fontSize: 22))),
                                    Center(
                                        child: Text("오후",
                                            style: TextStyle(fontSize: 22))),
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
                                      Future.microtask(() => hourController
                                          .jumpToItem(600 + (i % 12)));
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

                              const Text(":", style: TextStyle(fontSize: 26)),

                              /// Minute
                              Expanded(
                                child: CupertinoPicker.builder(
                                  itemExtent: 40,
                                  scrollController: minuteController,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (i) {
                                    minute = i % 60;
                                    if (i < 100 || i > 5900) {
                                      Future.microtask(() => minuteController
                                          .jumpToItem(3000 + (i % 60)));
                                    }
                                  },
                                  childCount: 6000,
                                  itemBuilder: (_, i) {
                                    return Center(
                                      child: Text(
                                        (i % 60).toString().padLeft(2, '0'),
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
                        const Text('진동 사용', style: TextStyle(fontSize: 16)),
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
                            duration:
                            const Duration(milliseconds: 200),
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

                    /// 저장 / 취소 버튼 (동일 디자인)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            onPressed: () {
                              final hour24 =
                              isAm ? hour % 12 : (hour % 12) + 12;

                              if (selectedDays.isEmpty) {
                                selectedDays = List.from(weekDays);
                              }

                              setState(() {
                                final newAlarm = Alarm(
                                  time: TimeOfDay(
                                      hour: hour24, minute: minute),
                                  days: selectedDays,
                                  label: labelController.text.trim(),
                                  vibrate: vibrate,
                                );

                                if (index != null) {
                                  alarmList[index] = newAlarm;
                                } else {
                                  alarmList.add(newAlarm);
                                }
                              });

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                  )
              )
            );
          },
        );
      },
    );
  }

  /// 다음 울릴 알람 계산
  String? getNextAlarmText() {
    final enabled =
    alarmList.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;

    final now = TimeOfDay.now();
    final nowTotal = now.hour * 60 + now.minute;

    int? minDiff;

    for (final alarm in enabled) {
      final total = alarm.time.hour * 60 + alarm.time.minute;
      int diff = total - nowTotal;
      if (diff < 0) diff += 1440;

      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
      }
    }

    if (minDiff != null) {
      final h = minDiff ~/ 60;
      final m = minDiff % 60;

      if (h > 0 && m > 0) return "$h시간 $m분 후에 울려요";
      if (h > 0) return "$h시간 후에 울려요";
      return "$m분 후에 울려요";
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
                    Text(
                      getNextAlarmText() ?? "등록된 알람이 없어요.",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
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
                      margin:
                      const EdgeInsets.symmetric(vertical: 10),
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                            final isSelected =
                            alarm.days.contains(day);
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 4),
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
                          onChanged: (v) => setState(
                                  () => alarm.isEnabled = v),
                          thumbColor: WidgetStateProperty
                              .resolveWith((states) =>
                          states.contains(
                              WidgetState.selected)
                              ? Colors.amber
                              : Colors.grey),
                          trackColor: WidgetStateProperty
                              .resolveWith((states) =>
                          states.contains(
                              WidgetState.selected)
                              ? Colors.amber.withAlpha(128)
                              : Colors.grey
                              .withAlpha(128)),
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
                onPressed: () {
                  setState(() {
                    final sorted =
                    selectedIndexes.toList()
                      ..sort((a, b) => b.compareTo(a));

                    for (final idx in sorted) {
                      alarmList.removeAt(idx);
                    }

                    selectedIndexes.clear();
                    _isEditing = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text("선택한 알람이 삭제되었습니다.")),
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
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
