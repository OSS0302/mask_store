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

  void _handleChat(BuildContext context, Function saveInquiry) {
    saveInquiry('채팅 문의');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅 기능 준비 중입니다.')));
  }

  void _handleFaq(BuildContext context) {
    launchUrl(Uri.parse(supportWebsite));
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

  void _handleCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
    if (!await launchUrl(phoneUri)) {
      Clipboard.setData(ClipboardData(text: supportPhone));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전화를 걸 수 없습니다. 번호가 복사되었습니다: $supportPhone')),
      );
    }
  }

  void _handleKakao(BuildContext context) async {
    if (!await launchUrl(Uri.parse(supportKakao))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오톡을 열 수 없습니다. 링크를 복사했습니다: $supportKakao')),
      );
    }
  }

  void _handleWebsite(BuildContext context) async {
    if (!await launchUrl(Uri.parse(supportWebsite))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('웹사이트를 열 수 없습니다. 링크를 복사했습니다: $supportWebsite')),
      );
    }
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
    );
  }
}
