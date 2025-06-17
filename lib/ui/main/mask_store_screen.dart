import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedType = '기능 문의';
  bool _includeLogs = false;
  bool _agree = false;
  bool _sendCopyToSelf = false;
  bool _isSending = false;
  bool _saveContactInfo = false;

  File? _attachedImage;
  PlatformFile? _attachedFile;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadSavedContactInfo();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _loadSavedContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _emailController.text = prefs.getString('email') ?? '';
    _nameController.text = prefs.getString('name') ?? '';
    _phoneController.text = prefs.getString('phone') ?? '';
  }

  Future<void> _saveContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
    await prefs.setString('name', _nameController.text);
    await prefs.setString('phone', _phoneController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연락처 정보가 저장되었습니다.')),
    );
  }

  void _clearContactInfo() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연락처 정보가 초기화되었습니다.')),
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('문의 미리 보기'),
        content: SingleChildScrollView(
          child: Text('''
문의 유형: $_selectedType
이름: ${_nameController.text}
이메일: ${_emailController.text}
전화번호: ${_phoneController.text}
로그 포함: $_includeLogs

내용:
${_messageController.text}
'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _attachedImage = File(picked.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachedFile = result.files.first);
    }
  }

  void _removeAttachments() {
    setState(() {
      _attachedImage = null;
      _attachedFile = null;
    });
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보 수집에 동의해주세요.')),
      );
      return;
    }

    if (_saveContactInfo) {
      await _saveContactInfo();
    }

    setState(() => _isSending = true);

    final subject = '[문의] $_selectedType';
    final body = '''
문의 유형: $_selectedType
앱 버전: $_appVersion
이름: ${_nameController.text}
이메일: ${_emailController.text}
전화번호: ${_phoneController.text}
로그 포함: $_includeLogs

내용:
${_messageController.text}
''';

    final recipients = ['support@example.com'];
    if (_sendCopyToSelf && _emailController.text.isNotEmpty) {
      recipients.add(_emailController.text);
    }

    final mailtoUri = Uri.parse(
      'mailto:${recipients.join(',')}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (!await launchUrl(mailtoUri)) {
        throw '메일 앱을 열 수 없습니다';
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Expanded(child: Text('메일 앱을 열 수 없습니다. 내용을 복사하세요.')),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: body));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('문의 내용이 복사되었습니다.')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    setState(() {
      _isSending = false;
      _messageController.clear();
      _emailController.clear();
      _nameController.clear();
      _phoneController.clear();
      _attachedImage = null;
      _attachedFile = null;
      _agree = false;
      _sendCopyToSelf = false;
      _includeLogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('앱 버전: $_appVersion'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '문의 유형'),
                items: ['기능 문의', '오류 신고', '개선 제안', '기타']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '전화번호'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '문의 내용',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? '내용을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('이미지 첨부'),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('파일 첨부'),
                    onPressed: _pickFile,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('첨부 제거'),
                    onPressed: _removeAttachments,
                  ),
                ],
              ),
              if (_attachedImage != null)
                Text('첨부 이미지: ${_attachedImage!.path.split('/').last}'),
              if (_attachedFile != null)
                Text('첨부 파일: ${_attachedFile!.name}'),
              CheckboxListTile(
                title: const Text('앱 로그 포함'),
                value: _includeLogs,
                onChanged: (val) => setState(() => _includeLogs = val!),
              ),
              CheckboxListTile(
                title: const Text('본인에게도 복사 보내기'),
                value: _sendCopyToSelf,
                onChanged: (val) => setState(() => _sendCopyToSelf = val!),
              ),
              CheckboxListTile(
                title: const Text('개인정보 수집에 동의합니다'),
                value: _agree,
                onChanged: (val) => setState(() => _agree = val!),
              ),
              CheckboxListTile(
                title: const Text('연락처 정보 저장'),
                value: _saveContactInfo,
                onChanged: (val) => setState(() => _saveContactInfo = val!),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _submitInquiry,
                      child: _isSending
                          ? const CircularProgressIndicator()
                          : const Text('문의 보내기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _showPreviewDialog,
                    child: const Text('미리 보기'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearContactInfo,
                    child: const Text('초기화'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
