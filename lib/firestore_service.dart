import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 관련 패키지
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Firebase Auth 관련 패키지

class FirestoreService {
  // 🔹 Firebase 인스턴스 초기화, Firestore에 수면 기록(start/end)을 관리하는 역할
  final FirebaseAuth _auth = FirebaseAuth.instance; // [Auth] 사용자 인증용
  final FirebaseFirestore _db = FirebaseFirestore.instance; // [DB] Firestore 접근용

  //현재 로그인한 유저 ID 가져오기
  String get currentUid {
    final user = _auth.currentUser;
    if (user == null){
      throw Exception("로그인된 사용자가 없습니다.");
    }
    return user.uid;
  }

  // // 사용자 기본 정보 저장
  // Future<void> saveUserInfo({
  //   required int Awakenings,
  //   required int Irregular_flag,
  // }) async {
  //   final uid = currentUid;
  //
  //   await _db
  //       .collection('users_kim')
  //       .doc(uid)
  //       .collection('users_info')
  //       .doc('basic')
  //       .set({
  //     'user_id': uid,
  //     'Awakenings': Awakenings,
  //     'Irregular_flag': Irregular_flag
  //   }, SetOptions(merge: true));
  // }

  // ✅ 취침 시작 기록 함수
  Future<void> startSleep({
    required Map<String, dynamic> sleepData,
  }) async {
    final uid = currentUid;
    // 오늘 날짜 기준 문서 키 생성 → "2025-11-19"
    final dateKey = DateTime.now().toIso8601String().substring(0, 10);

    await _db
      .collection('users_kim')        // users_kim이 아니라 실제 협업용 users
      .doc(uid)
      .collection('Sleep_data')
      .doc(dateKey)
      .set({
        ...sleepData,             // 여기서 입력된 sleepData를 그대로 저장
        'start_time': DateTime.now(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));   // 기존 필드 있으면 유지 + 새로운 데이터만 병합
  }
  //알람 저장
  Future<String> saveAlarm(String uid, Map<String, dynamic> alarmData) async {
    final ref = _db
        .collection("users_kim")
        .doc(uid)
        .collection("users_info")
        .doc("alarms")
        .collection("alarms")
        .doc();
    await ref.set(alarmData);
    return ref.id;
  }

  //알람 불러오기
  Future<List<Map<String, dynamic>>> loadAlarms(String uid) async {
    final snap = await _db
        .collection("users_kim")
        .doc(uid)
        .collection("users_info")
        .doc("alarms")
        .collection("alarms")
        .get();

    return snap.docs.map((doc) {
        final data = doc.data();
        data["id"] = doc.id;
        return data;
    }).toList();
  }
  // 알람 수정
  Future<void> updateAlarm(String uid, String alarmId, Map<String, dynamic> alarmData) async {
    await _db
        .collection("users_kim")
        .doc(uid)
        .collection("users_info")
        .doc("alarms")
        .collection("alarms")
        .doc(alarmId)
        .update(alarmData);
  }

  // 알람 삭제
  Future<void> deleteAlarm(String uid, String alarmId) async {
    await _db.collection("users_kim")
        .doc(uid)
        .collection("users_info")
        .doc("alarms")
        .collection("alarms")
        .doc(alarmId).delete();
  }
  //즉시 갱신
  Stream<List<Map<String, dynamic>>> streamAlarms(String uid) {
    return _db
      .collection("users_kim")
      .doc(uid)
      .collection("users_info")
      .doc("alarms")
      .collection("alarms")
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) {
            final data = doc.data();
            data["id"] = doc.id;
            return data;
          }).toList()
      );
  }
  // 🔹 Firebase Auth + Firestore 회원가입 함수
  Future<String?> registerUser({
    required String userId,
    required String email,
    required String password,
  }) async {
    try {
      // ✅ [1️⃣ Firebase Authentication - 사용자 등록]
      // 이메일과 비밀번호로 Firebase Auth에 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(userId);

      // Firestore 'users_kim/{uid}/user_info/basic'
      await _db
          .collection('users_kim')
          .doc(userId)
          .collection('users_info')
          .doc('information')
          .set({
        'user_id': userId,
        'email': email,
      });

      return null; // null이면 성공 (에러 없음)
    } on FirebaseAuthException catch (e) {
      // ❌ [Auth 에러 발생] (예: 이메일 중복, 비밀번호 짧음 등)
      return e.message;
    } catch (e) {
      // ❌ [Firestore 또는 기타 에러]
      return e.toString(); //
    }
  }

  //개인 정보 저장
  Future<void> saveUserInformation({
    required String name,
    required String gender,
    required int age,
    required int awakenings,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    if(user==null){
      throw Exception("로그인된 사용자가 없습니다.");
    }

    final String? userId = user.displayName;
    await _db
        .collection('users_kim')
        .doc(userId)
        .collection('users_info')
        .doc('information')
        .set({
      'name': name,
      'gender': gender,
      'age': age,
      'awakenings': awakenings,
      'time_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}