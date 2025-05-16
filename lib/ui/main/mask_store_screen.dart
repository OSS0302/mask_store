import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  final _appInfoController = TextEditingController();

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
    _loadAppInfo();
    _loadTempData();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    _appInfoController.text =
    '버전 ${info.version} (Build ${info.buildNumber}) - ${Platform.operatingSystem}';
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final ext = file.path.split('.').last.toLowerCase();
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        _showSnack('5MB 이하 파일만 첨부 가능합니다.');
      } else if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        _showSnack('JPG, JPEG, PNG만 첨부 가능합니다.');
      } else {
        setState(() => _selectedFile = file);
      }
    }
  }

  Future<void> _saveTempData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_name', _nameController.text);
    await prefs.setString('temp_email', _emailController.text);
    await prefs.setString('temp_message', _messageController.text);
    await prefs.setString('temp_type', _selectedType ?? '');
  }

  Future<void> _loadTempData() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('temp_name') ?? '';
    _emailController.text = prefs.getString('temp_email') ?? '';
    _messageController.text = prefs.getString('temp_message') ?? '';
    setState(() {
      _selectedType = prefs.getString('temp_type');
    });
  }

  double _progress() {
    int filled = 0;
    if (_nameController.text.isNotEmpty) filled++;
    if (_emailController.text.isNotEmpty) filled++;
    if (_selectedType != null) filled++;
    if (_messageController.text.isNotEmpty) filled++;
    return filled / 4;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_isAgreed) {
      _showSnack('모든 항목을 작성하고 동의해주세요.');
      return;
    }

    final result = await (Connectivity().checkConnectivity());
    if (result == ConnectivityResult.none) {
      _showSnack('인터넷 연결이 필요합니다.');
      return;
    }

    final confirm = await _showConfirmDialog();
    if (!confirm) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);

    _showSnack('문의가 성공적으로 전송되었습니다.');

    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    setState(() {
      _selectedType = null;
      _selectedFile = null;
      _isAgreed = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> _showConfirmDialog() async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전송 확인'),
        content: const Text('입력하신 문의 내용을 전송하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    )) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  String? _required(String? val) => val == null || val.trim().isEmpty ? '필수 항목입니다.' : null;

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요.';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return !regex.hasMatch(val) ? '이메일 형식이 올바르지 않습니다.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: isDark ? Colors.black87 : Colors.cyan,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        onLongPress: _pickFile, // 길게 누르면 이미지 첨부
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: _saveTempData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('문의 내용을 작성해주세요', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress()),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('이름'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('이메일'),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _inquiryTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  decoration: _inputDecoration('문의 유형'),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      if (_messageController.text.trim().isEmpty && value != null) {
                        _messageController.text = '문의 유형: $value\n\n';
                      }
                    });
                  },
                  validator: (v) => v == null ? '문의 유형을 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  decoration: _inputDecoration('문의 내용'),
                  validator: _required,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _appInfoController,
                  readOnly: true,
                  decoration: _inputDecoration('앱 정보'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('파일 첨부'),
                    ),
                    const SizedBox(width: 10),
                    if (_selectedFile != null)
                      Expanded(
                        child: Row(
                          children: [
                            Image.file(_selectedFile!, height: 40),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (v) => setState(() => _isAgreed = v ?? false),
                    ),
                    const Expanded(child: Text('개인정보 수집 및 이용에 동의합니다.')),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? '전송 중...' : '문의 전송'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: isDark ? Colors.tealAccent : Colors.cyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
