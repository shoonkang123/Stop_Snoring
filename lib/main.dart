import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // 알림 권한 요청용
import 'package:alarm/alarm.dart'; // 알람 플러그인

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'alarm_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔑 알람 울릴 때 어디서든 화면 띄우기 위한 전역 navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔢 AlarmSettings(볼륨, 사운드 파일) → 강도(1~5)로 역변환
int _strengthFromAlarmSettings(AlarmSettings s) {
  final String path = s.assetAudioPath;
  // volume 이 double? 이라서 기본값(1.0) 주고 받기
  final double v = s.volume ?? 1.0;

  // 4, 5는 사운드 파일로 구분
  if (path.endsWith('siren5.mp3')) {
    return 5;
  } else if (path.endsWith('siren4.mp3')) {
    return 4;
  }

  // 나머지(1,2,3)는 good_morning1 + 볼륨으로 구분
  // 1 → 0.4, 2 → 0.6, 3 → 0.8 로 예약해놨으니까 대략 범위로 나눔
  if (v <= 0.5) return 1;   // 0.4 근처
  if (v <= 0.7) return 2;   // 0.6 근처
  return 3;                 // 그 외는 3 (0.8)
}

/// 🔢 AlarmSettings.notificationBody → snoozeCount(0~3)로 역변환
int _snoozeFromAlarmSettings(AlarmSettings s) {
  final String body = s.notificationBody ?? '';
  const String prefix = 'SNOOZE:';

  final int idx = body.indexOf(prefix);
  if (idx == -1) return 0; // SNOOZE: 가 없으면 0으로 간주

  final int start = idx + prefix.length;
  int end = body.indexOf('|', start);
  if (end == -1) end = body.length;

  final String numStr = body.substring(start, end);
  final int? parsed = int.tryParse(numStr);

  if (parsed == null || parsed < 0) return 0;
  if (parsed > 3) return 3;
  return parsed;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 alarm 플러그인 초기화 (runApp 전에)
  await Alarm.init();

  // 🔔 안드로이드 알림 권한 요청
  await _requestNotificationPermission();

  // 🔔 알람이 실제로 울릴 때마다 호출되는 스트림 리스너
  Alarm.ringStream.stream.listen((AlarmSettings alarmSettings) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // 알람 설정에서 초기 강도 / 스누즈 횟수 계산
    final int initialStrength = _strengthFromAlarmSettings(alarmSettings);
    final int initialSnoozeCount = _snoozeFromAlarmSettings(alarmSettings);

    // 알람 울리면 AlarmScreen을 전체화면으로 띄우기 (기존 화면 위에만 올림)
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AlarmScreen(
          initialStrength: initialStrength,
          initialSnoozeCount: initialSnoozeCount,
        ),
        fullscreenDialog: true, // 선택사항: 위에서 슬라이드되는 느낌 (iOS)
      ),
    );
  });

  runApp(const MyApp());
}

/// 안드로이드 알림 권한 요청 함수
Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted) {
      // 아직 허용 안 되어 있으면 요청
      await Permission.notification.request();
    }
    // 필요하면 permanentlyDenied일 때 openAppSettings()로
    // 설정 화면 여는 것도 가능
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,          // 🔑 AlarmScreen 띄우는 용도
      debugShowCheckedModeBanner: false,  // DEBUG 리본 제거

      //  한국어 로케일 적용
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoginPage(),
      // const LoginPage(),  // 로그인 페이지로 시작
      // const AlarmScreen(), // (테스트용) 알람 화면으로 바로 시작

      routes: {
        '/alarm': (context) => const AlarmScreen(),
      },
    );
  }
}

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  String? errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _handleLogin() async {
    String userid = _idController.text.trim();
    String pw = _pwController.text.trim();

    // 비어 있는지 체크
    if (userid.isEmpty || pw.isEmpty) {
      setState(() {
        errorMessage = '아이디와 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    try {
      final doc = await _db
          .collection("users_kim")
          .doc(userid)
          .collection("users_info")
          .doc("information")
          .get();

      if (!doc.exists) {
        setState(() {
          errorMessage = '존재하지 않는 아이디입니다.';
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        setState(() {
          errorMessage = "계정 데이터가 비어 있습니다.";
        });
        return;
      }

      final email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        setState(() {
          errorMessage = "이 아이디에 연결된 이메일 정보가 없습니다.";
        });
        return;
      }

      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final user = cred.user;
      if (user == null) {
        setState(() {
          errorMessage = "로그인에 실패했습니다. 다시 시도해주세요.";
        });
        return;
      }

      setState(() {
        errorMessage = null;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == "user-not-found") {
        msg = '존재하지 않는 계정입니다.';
      } else if (e.code == 'wrong-password') {
        msg = '비밀번호가 틀렸습니다.';
      } else if (e.code == 'invalid-email') {
        msg = '올바른 이메일 형식이 아닙니다.';
      } else {
        msg = '로그인에 실패했습니다.';
      }
      setState(() {
        errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        errorMessage = '로그인 중 알 수 없는 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_title_icon.png',
                  height: 64,
                ),
                const SizedBox(width: 6),
                const Text(
                  "AI ALARM",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF55506B),
                    letterSpacing: 1.0,
                    height: 1.1,
                  ),
                ),
              ],
            ),

              const SizedBox(height: 40),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            labelText: 'ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _pwController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleLogin,
                            child: const Text(
                              '로그인',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amber),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.amber[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
