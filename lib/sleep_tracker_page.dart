import 'package:flutter/material.dart';
import 'common_layout.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  String goalTime = "08:00";

  /// 🔥 목표 입력 다이얼로그 (시간/분 따로 입력)
  Future<void> _openGoalDialog() async {
    final parts = goalTime.split(":");
    TextEditingController hourController =
    TextEditingController(text: parts[0]);
    TextEditingController minuteController =
    TextEditingController(text: parts[1]);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            "목표 수면 시간 입력",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "시간",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller: minuteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "분",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              child: const Text("취소"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("저장"),
              onPressed: () {
                setState(() {
                  String h = hourController.text.padLeft(2, '0');
                  String m = minuteController.text.padLeft(2, '0');
                  goalTime = "$h:$m";
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      currentIndex: 2,
      title: "sleep tracker",

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ---------------- Goal Button ----------------
                Expanded(
                  child: GestureDetector(
                    onTap: _openGoalDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(158, 158, 158, 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "목표 수면 시간",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            goalTime,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------------- Quality Button (UI만) ----------------
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(158, 158, 158, 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "Quality",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "--",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
