import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final String supportEmail = 'support@maskstore.com';
  final String supportPhone = '123-456-7890';
  final String supportKakao = 'https://pf.kakao.com/_supportchat';
  final String supportWebsite = 'https://www.maskstore.com/support';
  List<Map<String, String>> inquiryHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInquiryHistory();
  }

  Future<void> _loadInquiryHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedHistory = prefs.getStringList('inquiryHistory');
    if (storedHistory != null) {
      setState(() {
        inquiryHistory = storedHistory.map((e) => jsonDecode(e) as Map<String, String>).toList();
      });
    }
  }

  Future<void> _saveInquiry(String inquiry) async {
    final prefs = await SharedPreferences.getInstance();
    final newInquiry = {'inquiry': inquiry, 'date': DateTime.now().toString()};
    setState(() {
      inquiryHistory.insert(0, newInquiry);
    });
    await prefs.setStringList('inquiryHistory', inquiryHistory.map((e) => jsonEncode(e)).toList());
  }

  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  List<String> inquiryHistory = []; // 예제 데이터, 실제 사용 시 상태 변수로 관리

  Future<void> _clearInquiryHistory(BuildContext context) async {
    if (inquiryHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 문의 내역이 없습니다.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> backupHistory = List.from(inquiryHistory); // 백업 데이터 저장

    // 1️⃣ 삭제 확인 다이얼로그 (미리보기 포함)
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('문의 내역 삭제'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                const Text('모든 문의 내역을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: inquiryHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(inquiryHistory[index], maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    // 2️⃣ 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('문의 내역을 삭제하는 중...'),
            ],
          ),
        );
      },
    );

    try {
      // 3️⃣ 내역 삭제
      setState(() {
        inquiryHistory.clear();
      });
      await prefs.remove('inquiryHistory');

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      // 4️⃣ 실행 취소(Undo) 옵션 제공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('문의 내역이 삭제되었습니다.'),
          action: SnackBarAction(
            label: '실행 취소',
            onPressed: () async {
              setState(() {
                inquiryHistory = List.from(backupHistory);
              });
              await prefs.setStringList('inquiryHistory', inquiryHistory);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('삭제가 취소되었습니다.')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

// 🔹 특정 문의 내역만 삭제하는 기능 (실행 취소 지원)
  Future<void> _removeSingleInquiry(BuildContext context, String inquiry) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> backupHistory = List.from(inquiryHistory);

    setState(() {
      inquiryHistory.remove(inquiry);
    });

    await prefs.setStringList('inquiryHistory', inquiryHistory);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('문의 내역이 삭제되었습니다: $inquiry'),
        action: SnackBarAction(
          label: '실행 취소',
          onPressed: () async {
            setState(() {
              inquiryHistory = List.from(backupHistory);
            });
            await prefs.setStringList('inquiryHistory', inquiryHistory);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('삭제가 취소되었습니다.')),
            );
          },
        ),
      ),
    );
  }


  void _handleChat(BuildContext context, Function saveInquiry, {String? kakaoUrl, String? telegramUrl, String? email}) async {
    saveInquiry('채팅 문의');

    //  네트워크 상태 확인
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인터넷 연결이 없습니다. 네트워크 상태를 확인하세요.')),
      );
      return;
    }

    //  채팅 옵션 선택 다이얼로그 표시
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('앱 내 채팅'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _openInAppChat(context);
              },
            ),
            if (kakaoUrl != null)
              ListTile(
                leading: const Icon(Icons.message, color: Colors.yellow),
                title: const Text('카카오톡 문의'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _launchChatUrl(context, kakaoUrl, '카카오톡');
                },
              ),
            if (telegramUrl != null)
              ListTile(
                leading: const Icon(Icons.send, color: Colors.blue),
                title: const Text('텔레그램 문의'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _launchChatUrl(context, telegramUrl, '텔레그램');
                },
              ),
            if (email != null)
              ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('이메일 문의'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendEmail(context, email);
                },
              ),
          ],
        );
      },
    );
  }

// 앱 내 채팅 화면으로 이동하는 함수
  void _openInAppChat(BuildContext context) {
    // 여기에 앱 내 채팅 페이지로 이동하는 코드 추가
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('앱 내 채팅 기능 준비 중입니다.')));
  }

// 외부 URL을 여는 함수
  void _launchChatUrl(BuildContext context, String url, String platform) async {
    try {
      final Uri chatUri = Uri.parse(url);
      if (!await launchUrl(chatUri, mode: LaunchMode.externalApplication)) {
        throw '오류 발생';
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform을 열 수 없습니다. URL이 복사되었습니다: $url'),
        ),
      );
    }
  }

//이메일 전송 함수
  void _sendEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': '고객 문의', 'body': '문의 내용을 작성해주세요.'},
    );

    try {
      if (!await launchUrl(emailUri)) {
        throw '이메일 앱을 열 수 없습니다.';
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: email));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 앱을 열 수 없습니다. 이메일 주소가 복사되었습니다: $email')),
      );
    }
  }

  void _handleFaq(BuildContext context, Function saveInquiry, String supportWebsite, {bool useInAppWebView = false}) async {
    saveInquiry('FAQ 확인');

    final Uri faqUri = Uri.parse(supportWebsite);

    // 1️⃣ 네트워크 상태 확인
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인터넷 연결이 없습니다. 네트워크 상태를 확인하세요.')),
      );
      return;
    }

    // 2️⃣ 로딩 다이얼로그 표시 (비동기 처리)
    bool isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: true, // 사용자가 닫을 수 있도록 설정
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('FAQ 열기'),
              content: Row(
                children: [
                  if (isLoading) const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(isLoading ? 'FAQ 페이지를 여는 중입니다...' : 'FAQ 페이지 열기 실패'),
                ],
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _handleFaq(context, saveInquiry, supportWebsite, useInAppWebView: useInAppWebView); // 재시도
                    },
                    child: const Text('재시도'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      bool success = false;

      if (useInAppWebView) {
        // 3️⃣ 앱 내 웹뷰 사용 (기본 브라우저 대신)
        success = await launchUrl(faqUri, mode: LaunchMode.inAppWebView);
      } else {
        // 4️⃣ 기본 외부 브라우저에서 열기
        success = await launchUrl(faqUri, mode: LaunchMode.externalApplication);
      }

      if (!success) throw 'FAQ 페이지를 열 수 없습니다.';
    } catch (e) {
      isLoading = false; // 로딩 상태 종료
      Clipboard.setData(ClipboardData(text: supportWebsite));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FAQ 페이지를 열 수 없습니다. URL이 복사되었습니다: $supportWebsite'),
          action: SnackBarAction(
            label: '브라우저 열기',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: supportWebsite));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$supportWebsite를 브라우저에 붙여넣기하세요.')),
              );
            },
          ),
        ),
      );
    } finally {
      Navigator.of(context).pop(); // 5️⃣ 로딩 팝업 닫기
    }
  }
  void _handleEmail(BuildContext context, Function saveInquiry) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=고객 문의&body=안녕하세요,',
    );

    saveInquiry('이메일 문의: $supportEmail');

    if (!await launchUrl(emailUri)) {
      Clipboard.setData(ClipboardData(text: supportEmail));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 앱을 열 수 없습니다. 이메일 주소가 복사되었습니다: $supportEmail')),
      );
    }
  }

  void _handleCall(BuildContext context, Function saveInquiry, String supportPhone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);

    // 사용자에게 전화 걸기 여부 확인
    bool? confirmCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('전화 걸기'),
          content: Text('고객센터 ($supportPhone)로 전화를 거시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('통화'),
            ),
          ],
        );
      },
    );

    if (confirmCall == true) {
      saveInquiry('전화 문의: $supportPhone');

      try {
        if (!await launchUrl(phoneUri)) {
          throw '전화 걸기 실패';
        }
      } catch (e) {
        Clipboard.setData(ClipboardData(text: supportPhone));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전화를 걸 수 없습니다. 번호가 복사되었습니다: $supportPhone'),
            action: SnackBarAction(
              label: '전화 앱 열기',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: supportPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$supportPhone를 전화 앱에 붙여넣기하세요.')),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _handleKakao(BuildContext context, Function saveInquiry) async {
    saveInquiry('카카오톡 문의');

    final Uri kakaoAppUri = Uri.parse('kakaolink://home');
    final Uri kakaoWebUri = Uri.parse(supportKakao);
    final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=com.kakao.talk');
    final Uri appStoreUri = Uri.parse('https://apps.apple.com/app/kakaotalk/id362057947');

    if (await canLaunchUrl(kakaoAppUri)) {
      // 카카오톡 앱이 있으면 앱 실행
      await launchUrl(kakaoAppUri);
    } else if (await canLaunchUrl(kakaoWebUri)) {
      // 앱이 없으면 웹사이트 열기
      await launchUrl(kakaoWebUri);
    } else {
      // 앱도 웹도 안 될 경우, 클립보드 복사 후 스토어로 이동 안내
      Clipboard.setData(ClipboardData(text: supportKakao));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카카오톡을 열 수 없습니다. 링크를 복사했습니다: $supportKakao\n앱이 없다면 설치하세요.'),
          action: SnackBarAction(
            label: '설치하기',
            onPressed: () async {
              if (Theme.of(context).platform == TargetPlatform.android) {
                await launchUrl(playStoreUri);
              } else if (Theme.of(context).platform == TargetPlatform.iOS) {
                await launchUrl(appStoreUri);
              }
            },
          ),
        ),
      );
    }
  }

  void _handleWebsite(BuildContext context, Function saveInquiry) async {
    saveInquiry('웹사이트 방문');
    _launchURL(supportWebsite);
  }

  void _handleInquiryHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의 기록'),
        content: SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: inquiryHistory.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(inquiryHistory[index]['inquiry']!),
              subtitle: Text(inquiryHistory[index]['date']!),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _clearInquiryHistory(),
            child: const Text('기록 삭제'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> supportOptions = [];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '고객 지원',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 4,
        backgroundColor: isDarkMode ? Colors.black : Colors.teal.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어떻게 도와드릴까요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (inquiryHistory.isNotEmpty)
                Text('가장 최근: ${inquiryHistory[0]['inquiry']} - ${inquiryHistory[0]['date']}'),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: supportOptions.length,
                  itemBuilder: (context, index) {
                    final option = supportOptions[index];
                    return GestureDetector(
                      onTap: () => (option['action'] as Function)(context, _saveInquiry),
                      child: ListTile(
                        leading: Icon(option['icon'] as IconData?),
                        title: Text(option['title'] as String),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleChat(context, _saveInquiry), // 새 문의 제출
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다. URL이 복사되었습니다: $url')),
      );
    }
  }
}
