import 'package:flutter/material.dart';
import 'customer_page.dart';

class SignUpPage extends StatelessWidget {
  // 각 입력 필드(TextField)의 값을 가져오기 위한 컨트롤러 선언
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold의 배경색을 밝은 핑크 톤으로 설정 (사용자 지정 색상)
      backgroundColor: Color(0xFFFDF6FC),

      body: SafeArea( // 노치 영역을 피해서 UI가 그려지도록 보장
        child: Center(
          child: SingleChildScrollView( // 키보드가 올라와도 스크롤되게 함 (오버플로우 방지)
            padding: const EdgeInsets.all(20), // 외부 패딩
            child: Column(
              children: [
                SizedBox(height: 10), // 위쪽 여백

                // 로고 이미지
                SizedBox(
                  height: 70,
                  child: Image.asset('assets/Title.png'),
                ),

                SizedBox(height: 40), // 타이틀 아래 여백

                // 카드 형태 UI: 그림자와 모서리 둥근 박스 안에 모든 입력 필드 포함
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // 카드 모서리 둥글게
                  ),
                  elevation: 8, // 그림자 깊이 (높을수록 입체감 ↑)
                  child: Padding(
                    padding: const EdgeInsets.all(20.0), // 카드 내부 여백
                    child: Column(
                      children: [
                        // ID 입력 필드
                        TextField(
                          controller: idController, // 입력값 제어
                          decoration: InputDecoration(
                            labelText: 'ID', // 필드에 레이블 텍스트
                            border: OutlineInputBorder( // 기본 테두리 스타일
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder( // 포커스(클릭 시) 테두리 스타일
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber, // 노란색 포커스 테두리
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16), // 입력 필드 간 간격

                        // Email 입력 필드
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress, // 이메일 키보드
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Password 입력 필드
                        TextField(
                          controller: passwordController,
                          obscureText: true, // 비밀번호 숨김 처리 (●●●●)
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Confirm Password 입력 필드
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // 회원가입 버튼
                        SizedBox(
                          width: double.infinity, // 버튼 너비를 가득 채움
                          height: 50, // 버튼 높이
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber, // 노란색 배경
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // 모서리 둥글게
                              ),
                            ),
                            onPressed: () {
                              final id = idController.text.trim();
                              final email = emailController.text.trim();
                              final password = passwordController.text;
                              final confirmPassword = confirmPasswordController.text;

                              // 입력값이 하나라도 비어 있으면 알림 표시
                              if (id.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('입력 누락'),
                                    content: Text('모든 정보를 입력해주세요.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // 비밀번호 불일치 시 알림
                              if (password != confirmPassword) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('비밀번호 불일치'),
                                    content: Text('비밀번호와 확인 비밀번호가 일치하지 않습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // 모든 조건이 만족되면 다음 페이지로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Customerpage()),
                              );
                            },


                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: Colors.black, // 버튼 텍스트 색
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
