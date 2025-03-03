import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  Future<void> _clearInquiryHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      inquiryHistory.clear();
    });
    await prefs.remove('inquiryHistory');
  }

  final List<Map<String, dynamic>> supportOptions = [
    {
      'title': '문의하기',
      'icon': Icons.chat,
      'action': (BuildContext context, Function saveInquiry) => _handleChat(context, saveInquiry)
    },
    {
      'title': 'FAQ 보기',
      'icon': Icons.help,
      'action': (BuildContext context, Function saveInquiry) => _handleFaq(context)
    },
    {
      'title': '이메일 보내기',
      'icon': Icons.email,
      'action': (BuildContext context, Function saveInquiry) => _handleEmail(context, saveInquiry)
    },
    {
      'title': '전화 상담',
      'icon': Icons.phone,
      'action': (BuildContext context, Function saveInquiry) => _handleCall(context)
    },
    {
      'title': '카카오톡 상담',
      'icon': Icons.message,
      'action': (BuildContext context, Function saveInquiry) => _handleKakao(context)
    },
    {
      'title': '웹사이트 방문',
      'icon': Icons.public,
      'action': (BuildContext context, Function saveInquiry) => _handleWebsite(context)
    },
    {
      'title': '문의 기록 보기',
      'icon': Icons.history,
      'action': (BuildContext context, Function saveInquiry) => _handleInquiryHistory(context)
    },
  ];

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
              Expanded(
                child: ListView.builder(
                  itemCount: supportOptions.length,
                  itemBuilder: (context, index) {
                    final option = supportOptions[index];
                    return GestureDetector(
                      onTap: () => (option['action'] as Function)(context, _saveInquiry),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
}
