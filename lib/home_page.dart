import 'package:flutter/material.dart';
import 'common_layout.dart';
import 'alarm_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: "Home",
      currentIndex: 1,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '주무시겠습니까?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            /// Start 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlarmPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[400],
                shape: const CircleBorder(
                  side: BorderSide(
                    width: 4,
                    color: Colors.black,
                  ),
                ),
                padding: const EdgeInsets.all(40),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
