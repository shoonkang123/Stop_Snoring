import 'package:flutter/material.dart';
import 'common_layout.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  int goalHour = 8;
  int goalMinute = 0;


  final FocusNode hourFocus = FocusNode();
  final FocusNode minuteFocus = FocusNode();

  @override
  void dispose() {
    hourFocus.dispose();
    minuteFocus.dispose();
    super.dispose();
  }

  String formatTime(int h, int m) {
    return "${h.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')}";
  }

  Future<void> _openGoalDialog() async {
    TextEditingController hourController =
    TextEditingController(text: goalHour.toString());
    TextEditingController minuteController =
    TextEditingController(text: goalMinute.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "목표 수면 시간 설정!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hourController,
                          focusNode: hourFocus,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "시간",
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: hourFocus.hasFocus
                                    ? Colors.amber
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onTap: () => setStateDialog(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minuteController,
                          focusNode: minuteFocus,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "분",
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: minuteFocus.hasFocus
                                    ? Colors.amber
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onTap: () => setStateDialog(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("취소"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "저장",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    int h = int.tryParse(hourController.text) ?? goalHour;
                    int m = int.tryParse(minuteController.text) ?? goalMinute;

                    /// 범위 보정
                    if (h < 0) h = 0;
                    if (h > 23) h = 23;
                    if (m < 0) m = 0;
                    if (m > 59) m = 59;

                    setState(() {
                      goalHour = h;
                      goalMinute = m;
                    });

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: "Sleep tracker",
      currentIndex: 2,
      body: Column(
        children: [
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _openGoalDialog,
            child: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "목표 수면 시간",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatTime(goalHour, goalMinute),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
