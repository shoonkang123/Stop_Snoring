import 'package:flutter/material.dart';
import 'alarm_page.dart';

// ✅ 홈 화면을 담당하는 StatelessWidget 클래스
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 📌 전체 배경색 설정 (연한 분홍색)
      backgroundColor: const Color(0xFFFDF6FC),

      // ✅ 상단 앱바 구성
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // AppBar의 높이를 80으로 설정

        child: AppBar(
          // 🟡 AppBar 기본 설정
          leading: Image.asset('MoonIcon.png'), // 왼쪽 아이콘 (앱 로고 등)
          title: Text(
            'Home', // 앱바 제목
            style: TextStyle(
              color: Colors.black, // 텍스트 색상
              fontWeight: FontWeight.bold, // 굵은 텍스트
            ),
          ),
          centerTitle: true, // 제목을 중앙 정렬
          actions: [
            // 우측 메뉴 아이콘 버튼
            IconButton(
              icon: const Icon(Icons.menu), // 메뉴 아이콘
              onPressed: () {
                // 누를 때 동작 (아직 없음)
              },
              color: Colors.black, // 아이콘 색상
            )
          ],
        ),
      ),

      // ✅ 중앙 화면 본문 구성
      body: Center(
        // 세로로 배치하기 위해 Column 사용
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로 방향 가운데 정렬
          children: [
            const Text(
              '주무시겠습니까?', // 안내 문구
              style: TextStyle(
                fontSize: 18, // 폰트 크기
                fontWeight: FontWeight.w500, // 약간 굵게
              ),
            ),

            const SizedBox(height: 24), // 텍스트와 버튼 사이의 공간

            // 🔘 Start 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AlarmPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[400], // 노란 배경색
                shape: const CircleBorder(
                  side: BorderSide(
                    width: 4, // 테두리 두께
                    color: Colors.black, // 테두리 색상
                  ),
                ),
                padding: const EdgeInsets.all(40), // 버튼 크기를 키우기 위해 내부 여백 설정
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 20, // 텍스트 크기
                  fontWeight: FontWeight.bold, // 텍스트 굵기
                  color: Colors.black, // 텍스트 색상
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE3E3EA), // 회색 배경색
        selectedItemColor: Colors.amber[700], // 선택된 아이콘 색상 (노란색 계열)
        unselectedItemColor: Colors.grey, // 선택 안된 아이콘 색상
        currentIndex: 1, // 현재 선택된 탭 인덱스 (1 = Home)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm), // 왼쪽 아이콘 (알람)
            label: '', // 텍스트 라벨 없음
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // 가운데 아이콘 (홈)
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay), // 오른쪽 아이콘 (밤)
            label: '',
          ),
        ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AlarmPage()),
              );
            } else if (index == 1) {
              // 이미 Home이므로 아무 것도 안 함
              return;
            }
          }
      ),
    );
  }
}
