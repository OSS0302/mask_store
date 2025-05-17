import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _appVersionController = TextEditingController();

  String? _selectedType;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isAgreed = false;

  final List<String> _inquiryTypes = [
    '일반 문의',
    '즐겨찾기 오류',
    '재고 정보 오류',
    '가장 가까운 약국 오류',
    '음성 안내 문제',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _restoreDraft();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    _appVersionController.text = info.version;
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('draft_name') ?? '';
      _emailController.text = prefs.getString('draft_email') ?? '';
      _messageController.text = prefs.getString('draft_msg') ?? '';
      _selectedType = prefs.getString('draft_type');
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_name', _nameController.text);
    await prefs.setString('draft_email', _emailController.text);
    await prefs.setString('draft_msg', _messageController.text);
    if (_selectedType != null) await prefs.setString('draft_type', _selectedType!);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final size = await file.length();
      final ext = file.path.split('.').last.toLowerCase();
      if (size > 5 * 1024 * 1024) {
        _showSnack('5MB 이하만 첨부 가능합니다.');
      } else if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        _showSnack('JPG, JPEG, PNG만 지원됩니다.');
      } else {
        setState(() => _selectedFile = file);
      }
    }
  }

  void _autoFillMessage(String? type) {
    final examples = {
      '즐겨찾기 오류': '즐겨찾기 기능이 동작하지 않아요. 오류가 발생하는 상황은...',
      '재고 정보 오류': '실제 약국의 재고와 앱 정보가 달라요. 약국 이름은...',
      '가장 가까운 약국 오류': '근처 약국 안내가 잘못된 것 같아요. 현재 위치는...',
    };
    if (type != null && examples.containsKey(type)) {
      _messageController.text = examples[type]!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_isAgreed) {
      _showSnack('필수 항목을 작성하고 동의해주세요.');
      return;
    }

    final confirm = await _showPreviewDialog();
    if (!confirm) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);

    _showSnack('문의가 전송되었습니다!');
    Clipboard.setData(ClipboardData(text: _emailController.text));
    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    _selectedFile = null;
    _selectedType = null;
    _isAgreed = false;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('draft_name');
    prefs.remove('draft_email');
    prefs.remove('draft_msg');
    prefs.remove('draft_type');
  }

  Future<bool> _showPreviewDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('문의 미리보기'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('이름: ${_nameController.text}'),
              Text('이메일: ${_emailController.text}'),
              Text('문의 유형: $_selectedType'),
              const SizedBox(height: 8),
              const Text('내용:'),
              Text(_messageController.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    ) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _saveDraft();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImage,
        icon: const Icon(Icons.attach_file),
        label: const Text('파일 첨부'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                child: Column(
                  children: [
                    _buildField(_nameController, '이름', validator: _required),
                    const SizedBox(height: 12),
                    _buildField(_emailController, '이메일', validator: _validateEmail),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _inquiryTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedType = val);
                        _autoFillMessage(val);
                      },
                      decoration: const InputDecoration(labelText: '문의 유형'),
                      validator: (val) => val == null ? '선택해주세요' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(_messageController, '문의 내용',
                        validator: _required, maxLines: 5),
                    const SizedBox(height: 12),
                    _buildField(_appVersionController, '앱 버전', readOnly: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedFile != null)
                Text('첨부됨: ${_selectedFile!.path.split('/').last}',
                    style: const TextStyle(fontSize: 14)),
              CheckboxListTile(
                value: _isAgreed,
                onChanged: (v) => setState(() => _isAgreed = v ?? false),
                title: const Text('개인정보 수집 및 이용에 동의합니다.'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? '전송 중...' : '문의 전송'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark ? Colors.tealAccent : Colors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool readOnly = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _required(String? val) =>
      val == null || val.trim().isEmpty ? '필수 항목입니다.' : null;

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요.';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return !regex.hasMatch(val) ? '이메일 형식이 잘못되었습니다.' : null;
  }
}
