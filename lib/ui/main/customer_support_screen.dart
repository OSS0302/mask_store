import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  final String supportEmail = 'support@maskstore.com';
  final String supportPhone = '123-456-7890';
  final String supportKakao = 'https://pf.kakao.com/_supportchat';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> supportOptions = [
      {
        'title': '문의하기',
        'icon': Icons.chat,
        'action': (BuildContext context) => _handleChat(context)
      },
      {
        'title': 'FAQ 보기',
        'icon': Icons.help,
        'action': (BuildContext context) => _handleFaq(context)
      },
      {
        'title': '이메일 보내기',
        'icon': Icons.email,
        'action': (BuildContext context) => _handleEmail(context)
      },
      {
        'title': '전화 상담',
        'icon': Icons.phone,
        'action': (BuildContext context) => _handleCall(context)
      },
      {
        'title': '카카오톡 상담',
        'icon': Icons.message,
        'action': (BuildContext context) => _handleKakao(context)
      },
    ];

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
              Expanded(
                child: ListView.builder(
                  itemCount: supportOptions.length,
                  itemBuilder: (context, index) {
                    final option = supportOptions[index];
                    return GestureDetector(
                      onTap: () => (option['action'] as Function)(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option['icon'] as IconData?,
                              size: 36,
                              color: isDarkMode ? Colors.tealAccent : Colors.teal.shade800,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              option['title'] as String,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('실시간 문의는 준비 중입니다.'),
      ),
    );
  }

  void _handleFaq(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('자주 묻는 질문'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                title: Text('Q1: 배송은 얼마나 걸리나요?'),
                subtitle: Text('보통 3~5일 이내에 배송됩니다.'),
              ),
              ListTile(
                title: Text('Q2: 반품 정책은 어떻게 되나요?'),
                subtitle: Text('상품 수령 후 7일 이내에 반품 요청이 가능합니다.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _handleEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=고객 문의&body=안녕하세요,',
    );
    if (!await launchUrl(emailUri)) {
      Clipboard.setData(ClipboardData(text: supportEmail));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일 앱을 열 수 없습니다. 이메일 주소가 복사되었습니다: $supportEmail'),
        ),
      );
    }
  }

  void _handleCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
    if (!await launchUrl(phoneUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전화 앱을 열 수 없습니다. 직접 전화해 주세요: $supportPhone'),
        ),
      );
    }
  }

  void _handleKakao(BuildContext context) async {
    if (!await launchUrl(Uri.parse(supportKakao))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카카오톡을 열 수 없습니다.'),
        ),
      );
    }
  }
}
