import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/cart_screen.dart';
import 'package:mask_store/ui/main/favorites_screen.dart';
import 'package:mask_store/ui/main/home_screen.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/setting/settings_screen.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class CustomerSupportScreen extends StatelessWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> supportOptions = [
      {'title': '문의하기', 'icon': Icons.chat_bubble_outline, 'action': (BuildContext context) => _handleChat(context)},
      {'title': 'FAQ 보기', 'icon': Icons.help_outline, 'action': (BuildContext context) => _handleFaq(context)},
      {'title': '이메일 보내기', 'icon': Icons.email_outlined, 'action': (BuildContext context) => _handleEmail(context)},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '고객 지원',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어떻게 도와드릴까요?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: supportOptions.length,
                  itemBuilder: (context, index) {
                    final option = supportOptions[index];
                    return GestureDetector(
                      onTap: () => (option['action'] as Function)(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option['icon'] as IconData?,
                              size: 32,
                              color: isDarkMode ? Colors.tealAccent : Colors.teal.shade800,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              option['title'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.headset_mic_outlined,
                    size: 100,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal.shade800,
                  ),
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
          content: const Text('현재 FAQ 데이터가 없습니다.'),
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

  void _handleEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'support@maskstore.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이메일 주소가 복사되었습니다: support@maskstore.com'),
      ),
    );
  }
}
