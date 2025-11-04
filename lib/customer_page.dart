import 'package:flutter/material.dart';
import 'home_page.dart';

class Customerpage extends StatefulWidget {
  const Customerpage({super.key});

  @override
  State<Customerpage> createState() => _CustomerpageState();
}

class _CustomerpageState extends State<Customerpage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController irregularController = TextEditingController();

  String? selectedGender; // 남/여 선택용 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                SizedBox(height: 70, child: Image.asset('assets/Title.png')),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // 이름 입력
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: '이름',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amber, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 성별 선택 드롭다운
                        DropdownButtonFormField<String>(
                          initialValue: selectedGender,
                          items: const [
                            DropdownMenuItem(value: '남', child: Text('남')),
                            DropdownMenuItem(value: '여', child: Text('여')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: '성별',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), // 기존 TextField와 동일
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amber, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            // ✅ 배경 제거: 아래 두 줄 주석 처리 또는 제거
                            // filled: true,
                            // fillColor: Color(0xFFFDF6FC),
                          ),
                          borderRadius: BorderRadius.circular(12), // 드롭다운 펼침 메뉴도 둥글게
                        ),


                        const SizedBox(height: 16),

                        // 나이 입력
                        TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '나이',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amber, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 수면 중 깨는 횟수
                        DropdownButtonFormField<String>(
                          initialValue: irregularController.text.isNotEmpty ? irregularController.text : null,
                          items: List.generate(5, (index) {
                            final value = index.toString();
                            final label = (index == 4) ? '4회 이상' : value;
                            return DropdownMenuItem(
                              value: value,
                              child: Text(label),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              irregularController.text = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: '수면 중 깨는 횟수',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amber, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),


                        const SizedBox(height: 24),

                        // Next 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final name = nameController.text.trim();
                              final age = ageController.text.trim();
                              final irregular = irregularController.text.trim();

                              if (name.isEmpty || selectedGender == null || age.isEmpty || irregular.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('입력 누락'),
                                    content: const Text('모든 정보를 입력해주세요.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // 다음 페이지로 이동
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                            },
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.black,
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
