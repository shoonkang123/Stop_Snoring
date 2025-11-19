import 'package:flutter/material.dart';
import 'alarm_page.dart';
import 'firestore_service.dart'; // ✅ FirestoreService import 추가

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
        preferredSize: const Size.fromHeight(50), // AppBar 높이 설정

        child: AppBar(
          leading: Image.asset('assets/MoonIcon.png'),
          title: const Text(
            'Home',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
              color: Colors.black,
            ),
          ],
        ),
      ),

      // ✅ 중앙 화면 본문 구성
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '주무시겠습니까?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // 🔘 Start 버튼
            ElevatedButton(
                onPressed: () async {
                  final uid = 'test_user'; // 나중에 로그인한 UID로 변경

                  //최근 7일 성공률 데이터 가져오기
                  final predictionsRef = FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("predictions")
                    .orderBy("timestamp", descending: true)
                    .limit(7);

                  final snap = await predictionsRef.get();
                  double AvgSuccessrate = 0.52;

                  if (snap.docs.isNotEmpty) {
                    final rates = snap.docs.map((doc) {
                    return (doc.data()["success_rate"] ?? 0.52).toDouble();
                  }).toList();

                  AvgSuccessrate = rates.reduce((a,b) => a + b) / rates.length;

                  }

                    // 1) 알람 시각 설정 여부
                    if (wakeSin == null || wakeCos == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("알람 시각을 먼저 설정하세요!")),
                    );
                    return;
                    }
                    // 2) 알람 ON 여부
                    if (!alarmEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("알람을 켜야 취침 시작할 수 있어요.")),
                        );
                        return;
                    }

                    final now = DateTime.now();
                    DateTime alarmDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        selectedTime.hour,
                        selectedTime.minute,
                    );
                    // 저녁 11시 반에 버튼 클릭 -> 알람 시각 오전 7시 즉 이미 지난 시간으로 판단
                    // 알람 기상 시각을 다음 날로 넘김
                    if (alarmDateTime.isBefore(now)) {
                      alarmDateTime = alarmDateTime.add(Duration(days: 1));
                    }

                    int alarmWeekday = alarmDate.weekday % 7;
                    if (!alarms[WeekdayNames[alarmWeekday - 1]]["enabled"]){
                      showSnackBar("해당 요일에는 알람이 설정되어 있지 않습니다.");
                      return;
                    }

                    //요일
                    final Weekday = now.weekday % 7;
                    //취침 시각
                    final hour = now.hour + (now.minute / 60.0);
                    final angle = (hour / 24.0) * 2 * pi;
                    final Bed_sin = sin(angle);
                    final Bed_cos = cos(angle);

                    //기상 시각(알람 설정 페이지에서 불러오기)
                    final Wakehour = alarmDateTime.hour + (alarmDateTime.minute / 60.0);
                    final WakeAngle = (Wakehour / 24.0) * 2 * pi;
                    final Wake_sin = sin(WakeAngle);
                    final Wake_cos = cos(WakeAngle);

                    //날짜(Sleep)
                    final dayOfYear = int.parse(DateFormat("D").format(now));
                    final dateAngle = (dayOfYear / 365.0) * 2 * pi;
                    final Sleep_date_sin = sin(dateAngle);
                    final Sleep_date_cos = cos(dateAngle);

                    //날짜(Wake)
                    final dayWakeOfyear = int.parse(DateFormat("D").format(alarmDateTime));
                    final WakeDateAngle = (dayWakeOfyear / 365.0) * 2 * pi;
                    final Wake_date_sin = sin(WakeDateAngle);
                    final Wake_date_cos = cos(WakeDateAngle);

                    //수면 시간
                    final Sleep_duration = alarmDateTime.difference(now).inMinutes / 60.0;

                    //firestore에서 사용자 개인 설정값 가져오기
                    final userData = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get();

                    final Awakenings = userData["Awakenings"];
                    final Irregular_flag = userData["Irregular_flag"];

                    final inputData = {
                        "user_id": uid,
                        "Bed_sin": Bed_sin,
                        "Bed_cos": Bed_cos,
                        "Wake_sin": Wake_sin,
                        "Wake_cos": Wake_cos,
                        "Sleep_duration": Sleep_duration,
                        "Sleep_date_sin": Sleep_date_sin,
                        "Sleep_date_cos": Sleep_date_cos,
                        "Wake_date_sin": Wake_date_sin,
                        "Wake_date_cos": Wake_date_cos,
                        "Weekday": Weekday,
                        "Awakenings": Awakenings,
                        "Irregular_flag": Irregular_flag,
                        "Alarm_success_rate": AvgSuccessrate,
                    };

                    // 1) Firestore에 수면 데이터 기록
                    await FirestoreService().startSleep(
                        uid:uid,
                        sleepData:inputData,
                    );

                    // 2) FastAPI 호출
                    try {
                    // 서버 주소 입력 (예: http://YOUR_SERVER/predict_firestore/test_user)
                    final url = Uri.parse("http://127.0.0.1:8000/Predict");
                    //FastAPi로 앱 데이터(json) post로 보내기
                    final response = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(inputData),
                    );
                    //Fastapi가 반환한 알람 강도 및 모델 명
                    if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        // 예측값 꺼내기
                        final model_used = data["model_used"];
                        final strength = data["strength"];
                        // Snackbar + 화면이 아직 살아있는지 체크
                        if (!context.mounted) return;
                        // 예측 결과 출력
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("AI 예측 알람 강도: $strength")),
                        );
                        //AlarmPage로 강도 전달
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlarmPage(
                              predictedStrength: strength,
                            ),
                          ),
                        );
                    }
                    else {
                        throw Exception("FastAPI 요청 실패");
                    }
                    }
                    catch (e) {
                        print("FastAPI 호출 오류: $e");
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("서버 오류: $e")),
                        );
                    }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[400],
                    shape: const CircleBorder(
                        side: BorderSide(width: 4, color: Colors.black),
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
        },
      ),
    );
  }
}