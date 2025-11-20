import 'package:flutter/material.dart';
import 'alarm_page.dart';
import 'firestore_service.dart'; // ✅ FirestoreService import 추가
import 'dart:math' as math;                    // pi, sin, cos
import 'dart:convert';                         // jsonEncode, jsonDecode
import 'package:http/http.dart' as http;       // http.post
import 'package:intl/intl.dart';               // DateFormat
import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore
import 'package:firebase_auth/firebase_auth.dart';     // 로그인 uid



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
                  final user = FirebaseAuth.instance.currentUser!;
                  final String userId = user.displayName!;

                  //최근 7일 성공률 데이터 가져오기
                  final predictionsRef = FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
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

                  //----firestore에서 알람 목록 불러오기----
                  final alarmSnap = await FirebaseFirestore.instance
                    .collection("users_kim")
                    .doc(userId)
                    .collection("users_info")
                    .doc("alarms")
                    .collection("alarms")
                    .get();

                  if (alarmSnap.docs.isEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("먼저 알람을 하나 이상 등록해주세요.")),
                    );
                    return;
                  }

                  //요일 한글 이름 맞추기
                  const weekDays = ['월', '화', '수', '목', '금', '토', '일'];

                  final now = DateTime.now();
                  final todayIndex = now.weekday - 1;

                  DateTime? nearestAlarm; //가장 가까운 알람 시각
                  for (final doc in alarmSnap.docs) {
                    final data = doc.data();

                    final bool isEnabled = data["isEnabled"] ?? true;
                    if (!isEnabled) continue;

                    final int hour = data["hour"] ?? 7;
                    final int minute = data["minute"] ?? 0;
                    final List<String> days = List<String>.from(data["days"] ?? []);

                    //알람이 울릴 시각 (날짜는 오늘 기준)
                    final baseTodayAlarm = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      hour,
                      minute,
                    );
                    //알람 설정 시 요일 설정 안했으면 매일 울리는 알람
                    if (days.isEmpty) {
                      DateTime candidate = baseTodayAlarm;

                      // 이미 오늘 그 시간이 지났으면 내일로
                      if (candidate.isBefore(now)) {
                        candidate = candidate.add(const Duration(days: 1));
                      }

                      if (nearestAlarm == null || candidate.isBefore(nearestAlarm!)){
                        nearestAlarm = candidate;
                      }
                      continue;
                    }

                    //요일이 지정된 알람
                    for (final dayLabel in days) {
                      final idx = weekDays.indexOf(dayLabel);
                      if (idx == -1) continue;

                      //오늘 기준으로 며칠 뒤인지 계산
                      int diff = idx - todayIndex;

                      final nowMinutes = now.hour * 60 + now.minute;
                      final alarmMinutes = hour * 60 + minute;

                      // 같은 요일인데 이미 시간이 지났으면 +7일 (다음 주)
                      if (diff < 0 || (diff == 0 && alarmMinutes <= nowMinutes)){
                        diff += 7;
                      }

                      final candidate = baseTodayAlarm.add(Duration(days: diff));

                      if (nearestAlarm == null || candidate.isBefore(nearestAlarm!)){
                        nearestAlarm = candidate;
                      }
                    }
                  }

                  // 유효한 알람이 하나도 없을 때
                  if (nearestAlarm == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("켜진 알람이 없습니다.")),
                    );
                    return;
                  }

                  final alarmDateTime = nearestAlarm;

                  //요일
                  final Weekday = now.weekday % 7;
                  //취침 시각
                  final bedhour = now.hour + (now.minute / 60.0);
                  final bedangle = (bedhour / 24.0) * 2 * math.pi;
                  final Bed_sin = math.sin(bedangle);
                  final Bed_cos = math.cos(bedangle);

                  //기상 시각(알람 설정 페이지에서 불러오기)
                  final Wakehour = alarmDateTime.hour + (alarmDateTime.minute / 60.0);
                  final WakeAngle = (Wakehour / 24.0) * 2 * math.pi;
                  final Wake_sin = math.sin(WakeAngle);
                  final Wake_cos = math.cos(WakeAngle);

                  //날짜(Sleep)
                  final dayOfYear = int.parse(DateFormat("D").format(now));
                  final dateAngle = (dayOfYear / 365.0) * 2 * math.pi;
                  final Sleep_date_sin = math.sin(dateAngle);
                  final Sleep_date_cos = math.cos(dateAngle);

                  //날짜(Wake)
                  final dayWakeOfyear = int.parse(DateFormat("D").format(alarmDateTime));
                  final WakeDateAngle = (dayWakeOfyear / 365.0) * 2 * math.pi;
                  final Wake_date_sin = math.sin(WakeDateAngle);
                  final Wake_date_cos = math.cos(WakeDateAngle);

                  //수면 시간
                  final Sleep_duration = alarmDateTime.difference(now).inMinutes / 60.0;

                  //firestore에서 사용자 개인 설정값 가져오기
                  final userData = await FirebaseFirestore.instance
                      .collection('users_kim')
                      .doc(userId)
                      .collection('users_info')
                      .doc('basic')
                      .get();

                  final basic_data = userData.data() ?? {};
                  final Awakenings = (basic_data["Awakenings"] ?? 0) as int;
                  final Irregular_flag = (basic_data["Irregular_flag"] ?? 0) as int;

                  final inputData = {
                    "user_id": userId,
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
                            //******모델의 출력 알람 강도를 사용하고 싶으면 생성자 생성 *******
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
        },
      ),
    );
  }
}