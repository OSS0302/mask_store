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
  List<Map<String, dynamic>> inquiryList = [];

  @override
  void initState() {
    super.initState();
    fetchInquiries();
  }

  Future<void> fetchInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? inquiriesJson = prefs.getString('inquiries');
    if (inquiriesJson != null) {
      setState(() {
        inquiryList = List<Map<String, dynamic>>.from(json.decode(inquiriesJson));
      });
    }
  }

  Future<void> deleteInquiry(int index) async {
    setState(() {
      inquiryList.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inquiries', json.encode(inquiryList));
  }

  Future<void> saveInquiry(String title, String content) async {
    final newInquiry = {
      'title': title,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      inquiryList.add(newInquiry);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inquiries', json.encode(inquiryList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('문의 내역')),
      body: inquiryList.isEmpty
          ? Center(child: Text('문의 내역이 없습니다.'))
          : ListView.builder(
        itemCount: inquiryList.length,
        itemBuilder: (context, index) {
          final inquiry = inquiryList[index];
          return ListTile(
            title: Text(inquiry['title']),
            subtitle: Text(inquiry['content']),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteInquiry(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => saveInquiry('새 문의', '문의 내용 입력'),
        child: Icon(Icons.add),
      ),
    );
  }
}
