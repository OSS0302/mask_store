// ContactUsScreen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedType = '기능 문의';
  bool _includeLogs = false;
  bool _agree = false;
  File? _attachedImage;
  String _appVersion = '...';

  final List<Map<String, dynamic>> _previousInquiries = [];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _attachedImage = File(picked.path);
      });
    }
  }

  void _submitInquiry() {
    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보 처리방침에 동의해주세요.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('문의 전송'),
        content: const Text('입력한 내용을 전송하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('전송'),
            onPressed: () {
              Navigator.pop(context);
              _sendInquiry();
            },
          ),
        ],
      ),
    );
  }

  void _sendInquiry() {
    final inquiry = {
      'date': DateTime.now().toString().substring(0, 16),
      'type': _selectedType,
      'message': _messageController.text,
      'log': _includeLogs,
      'image': _attachedImage != null,
    };

    setState(() {
      _previousInquiries.insert(0, inquiry);
      _messageController.clear();
      _includeLogs = false;
      _attachedImage = null;
      _agree = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('문의가 전송되었습니다.'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () {
            setState(() {
              _previousInquiries.remove(inquiry);
            });
          },
        ),
      ),
    );
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case '오류 신고':
        return const Icon(Icons.bug_report, color: Colors.red);
      case '개선 제안':
        return const Icon(Icons.lightbulb_outline, color: Colors.orange);
      case '기타':
        return const Icon(Icons.more_horiz, color: Colors.grey);
      default:
        return const Icon(Icons.help_outline, color: Colors.blue);
    }
  }

  void _showInquiryDetail(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(entry['type']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('날짜: ${entry['date']}'),
            const SizedBox(height: 8),
            Text('내용:\n${entry['message']}'),
            const SizedBox(height: 8),
            Text('앱 로그 첨부: ${entry['log'] ? '예' : '아니오'}'),
            Text('스크린샷 첨부: ${entry['image'] ? '예' : '아니오'}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        centerTitle: true,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('앱 버전: $_appVersion', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: ['기능 문의', '오류 신고', '개선 제안', '기타']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                    decoration: const InputDecoration(
                      labelText: '문의 유형',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '문의 내용',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? '문의 내용을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: _includeLogs,
                        onChanged: (val) => setState(() => _includeLogs = val!),
                      ),
                      const Text('앱 로그 첨부'),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('스크린샷 첨부'),
                        onPressed: _pickImage,
                      ),
                      const SizedBox(width: 8),
                      if (_attachedImage != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (val) => setState(() => _agree = val!),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _agree = !_agree),
                          child: const Text(
                            '문의 전송을 위해 개인정보 처리방침에 동의합니다.',
                            style: TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('문의 전송'),
                    onPressed: _submitInquiry,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),
            Text('이전 문의 내역', style: theme.textTheme.titleMedium),

            if (_previousInquiries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('문의 내역이 없습니다.'),
              ),

            ..._previousInquiries.asMap().entries.map((entry) {
              final index = entry.key;
              final inquiry = entry.value;

              return Dismissible(
                key: ValueKey(inquiry['date']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() => _previousInquiries.removeAt(index));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('문의 내역이 삭제되었습니다.')),
                  );
                },
                child: Card(
                  child: ListTile(
                    leading: _getTypeIcon(inquiry['type']),
                    title: Text(inquiry['type']),
                    subtitle: Text(inquiry['message'], maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (inquiry['log'])
                          const Tooltip(message: '앱 로그 첨부됨', child: Icon(Icons.bug_report, size: 18)),
                        if (inquiry['image'])
                          const Tooltip(message: '이미지 첨부됨', child: Icon(Icons.image, size: 18)),
                      ],
                    ),
                    onTap: () => _showInquiryDetail(inquiry),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
