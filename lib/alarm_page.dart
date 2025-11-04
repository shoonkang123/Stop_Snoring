import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

/// 알람 데이터 모델 (알람 이름 추가)
class Alarm {
  TimeOfDay time;
  bool isEnabled;
  List<String> days;
  String label;

  Alarm({required this.time, this.isEnabled = true, required this.days, this.label = ''});
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => AlarmPageState();
}

class AlarmPageState extends State<AlarmPage> {
  final List<Alarm> alarmList = [];
  final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  Future<void> _showAddAlarmSheet() async {
    int hour = 8;
    int minute = 0;
    bool isAm = true;
    List<String> selectedDays = [];
    final TextEditingController labelController = TextEditingController();

    final hourController = FixedExtentScrollController(initialItem: 600);
    final minuteController = FixedExtentScrollController(initialItem: 3000);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF6FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "알람 설정",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 16),

                /// 알람 이름 입력 필드
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: "알람 이름",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                const SizedBox(height: 20),

                // 시/분/오전오후 선택
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(top: 70, left: 0, right: 0, child: Container(height: 1.2, color: Colors.black12)),
                    Positioned(bottom: 70, left: 0, right: 0, child: Container(height: 1.2, color: Colors.black12)),
                    SizedBox(
                      height: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              itemExtent: 40,
                              scrollController: FixedExtentScrollController(initialItem: isAm ? 0 : 1),
                              onSelectedItemChanged: (index) => setStateDialog(() => isAm = index == 0),
                              children: const [
                                Center(child: Text("오전", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
                                Center(child: Text("오후", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker.builder(
                              itemExtent: 40,
                              scrollController: hourController,
                              useMagnifier: true,
                              onSelectedItemChanged: (index) {
                                hour = (index % 12) + 1;
                                if (index < 10 || index > 1190) {
                                  Future.microtask(() => hourController.jumpToItem(600 + (index % 12)));
                                }
                              },
                              childCount: 1200,
                              itemBuilder: (context, i) {
                                final display = ((i % 12) + 1).toString();
                                return Center(child: Text(display, style: const TextStyle(fontSize: 26, color: Colors.black)));
                              },
                            ),
                          ),
                          const Text(":", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: CupertinoPicker.builder(
                              itemExtent: 40,
                              scrollController: minuteController,
                              useMagnifier: true,
                              onSelectedItemChanged: (index) {
                                minute = index % 60;
                                if (index < 100 || index > 5900) {
                                  Future.microtask(() => minuteController.jumpToItem(3000 + (index % 60)));
                                }
                              },
                              childCount: 6000,
                              itemBuilder: (context, i) {
                                final display = (i % 60).toString().padLeft(2, '0');
                                return Center(child: Text(display, style: const TextStyle(fontSize: 26, color: Colors.black)));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// 요일 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          isSelected ? selectedDays.remove(day) : selectedDays.add(day);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber[600] : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                /// 저장 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final hour24 = isAm ? hour % 12 : (hour % 12) + 12;
                        if (selectedDays.isEmpty) {
                          selectedDays = List.from(weekDays);
                        }
                        setState(() {
                          alarmList.add(Alarm(
                            time: TimeOfDay(hour: hour24, minute: minute),
                            days: selectedDays,
                            label: labelController.text.trim(),
                          ));
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("저장", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  String? getNextAlarmText() {
    final enabled = alarmList.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;
    final now = TimeOfDay.now();
    final nowM = now.hour * 60 + now.minute;
    int? minDiff;
    for (var a in enabled) {
      final alarmM = a.time.hour * 60 + a.time.minute;
      int diff = alarmM - nowM;
      if (diff < 0) diff += 24 * 60;
      if (minDiff == null || diff < minDiff) minDiff = diff;
    }
    if (minDiff != null) {
      final h = minDiff ~/ 60;
      final m = minDiff % 60;
      if (h > 0 && m > 0) return "$h시간 $m분 후";
      if (h > 0) return "$h시간 후";
      return "$m분 후";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Alarm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Padding(padding: const EdgeInsets.only(left: 10), child: Image.asset('MoonIcon.png')),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.menu), color: Colors.black)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(getNextAlarmText() ?? "등록된 알람이 없어요.", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alarmList.length,
              itemBuilder: (context, i) {
                final alarm = alarmList[i];
                final period = alarm.time.period == DayPeriod.am ? '오전' : '오후';
                final hour = alarm.time.hourOfPeriod;
                final minute = alarm.time.minute.toString().padLeft(2, '0');

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: const Icon(Icons.access_alarm, color: Colors.black87),

                    /// 알람 이름 + 시간 표시
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alarm.label.isNotEmpty)
                          Text(
                            alarm.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: '$period ',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              TextSpan(
                                text: '$hour:$minute',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// 요일 표시
                    subtitle: Row(
                      children: weekDays.map((day) {
                        final isSelected = alarm.days.contains(day);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    trailing: Switch(
                      value: alarm.isEnabled,
                      onChanged: (v) => setState(() => alarm.isEnabled = v),
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? Colors.amber : Colors.grey),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? Colors.amber.withAlpha(128) : Colors.grey.withAlpha(128)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmSheet,
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber[700],
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // 현재 알람 탭이 선택된 상태
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: '알람',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay),
            label: '수면',
          ),
        ],
        onTap: (index) {
          if (index == 0) return; // 현재 페이지
          if (index == 1) {
            // 홈 페이지로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 2) {
            // 수면 모드 페이지로 이동
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SleepPage()));
          }
        },
      ),

    );
  }
}
