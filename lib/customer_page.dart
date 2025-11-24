import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:flutter/services.dart';
import 'firestore_service.dart';

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
  String? sleepPattern;   // 규칙적/불규칙적 수면 패턴

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    irregularController.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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

                        const SizedBox(height: 16),

                        // 성별 선택 드롭다운
                        DropdownButtonFormField<String>(
                          value: selectedGender,
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        const SizedBox(height: 16),

                        // 나이 입력 (한 번만!)
                        TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null &&
                                (intValue < 1 || intValue > 150)) {
                              ageController.clear();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('유효하지 않은 나이'),
                                  content: const Text(
                                      '나이는 1세 이상 150세 이하만 입력 가능해요.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            labelText: '나이',
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

                        const SizedBox(height: 16),

                        // 수면 패턴
                        DropdownButtonFormField<String>(
                          value: sleepPattern,
                          items: const [
                            DropdownMenuItem(
                              value: '규칙적',
                              child: Text('규칙적'),
                            ),
                            DropdownMenuItem(
                              value: '불규칙적',
                              child: Text('불규칙적'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              sleepPattern = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: '수면 패턴',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        const SizedBox(height: 16),

                        // 수면 중 깨는 횟수
                        DropdownButtonFormField<String>(
                          value: irregularController.text.isNotEmpty
                              ? irregularController.text
                              : null,
                          items: List.generate(5, (index) {
                            final value = index.toString();
                            final label =
                            (index == 4) ? '4회 이상' : value;
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
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        const SizedBox(height: 24),

                        // 다음 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final ageText = ageController.text.trim();
                              final irregularText =
                              irregularController.text.trim();

                              if (name.isEmpty ||
                                  selectedGender == null ||
                                  sleepPattern == null ||
                                  ageText.isEmpty ||
                                  irregularText.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('입력 누락'),
                                    content: const Text(
                                        '모든 정보를 입력해주세요.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // 문자열 -> 정수 변환
                              final age = int.tryParse(ageText);
                              final awakenings =
                              int.tryParse(irregularText);

                              if (age == null || awakenings == null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('입력 오류'),
                                    content: const Text(
                                        '나이와 깨는 횟수는 숫자만 입력해주세요.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              final int irregularFlag = (sleepPattern == '불규칙적') ? 1 : 0;


                              final service = FirestoreService();

                              try {
                                await service.saveUserInformation(
                                  name: name,
                                  gender: selectedGender!,
                                  age: age,
                                  // sleepPattern도 Firestore에 저장하려면
                                  // saveUserInformation에 sleepPattern 파라미터 추가해서 같이 넘겨줘야 함
                                  awakenings: awakenings,
                                  irregularFlag: irregularFlag,
                                );

                                if (!context.mounted) return;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const HomePage(),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('저장 실패'),
                                    content: Text(
                                      '사용자 정보를 저장하는 중 오류가 발생했습니다.\n$e',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              '다음',
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
