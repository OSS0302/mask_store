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
    setState(() {
      _previousInquiries.insert(0, {
        'date': DateTime.now().toString().substring(0, 16),
        'type': _selectedType,
        'message': _messageController.text,
        'log': _includeLogs,
        'image': _attachedImage != null,
      });

      _messageController.clear();
      _includeLogs = false;
      _attachedImage = null;
      _agree = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의가 전송되었습니다.')),
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

            ..._previousInquiries.map((entry) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(entry['type']),
                subtitle: Text(entry['message']),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (entry['log']) const Icon(Icons.bug_report, size: 16),
                    if (entry['image']) const Icon(Icons.image, size: 16),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
