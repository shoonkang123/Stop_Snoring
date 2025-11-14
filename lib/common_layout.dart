import 'package:flutter/material.dart';
import 'home_page.dart';
import 'alarm_page.dart';
import 'sleep_page.dart';

class CommonLayout extends StatelessWidget {
  final Widget body;       // 페이지 body
  final String title;      // 상단 제목
  final int currentIndex;  // 네비 인덱스

  const CommonLayout({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FC),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          bottom: false, // 아래만 SafeArea 제외
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,

            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Image.asset(
                'assets/MoonIcon.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),

            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.black,
                onPressed: () {},
              )
            ],
          ),
        ),
      ),

      body: SafeArea(child: body),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber[700],
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,

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

        onTap: (i) {
          if (i == currentIndex) return;

          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlarmPage()),
            );
          }
          else if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          else if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SleepPage()),
            );
          }
        },
      ),
    );
  }
}
