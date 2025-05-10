import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

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
  String? _selectedPharmacy;
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

  final List<String> _pharmacies = [
    '한솔약국',
    '건강한약국',
    '우리들약국',
    '편한약국',
    '자주 가는 약국 없음',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersionController.text = info.version;
    });
  }

  double _calculateProgress() {
    int filled = 0;
    if (_nameController.text.isNotEmpty) filled++;
    if (_emailController.text.isNotEmpty) filled++;
    if (_selectedType != null) filled++;
    if (_messageController.text.isNotEmpty) filled++;
    return filled / 4;
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final size = await file.length();
      final ext = file.path.split('.').last.toLowerCase();
      if (size > 5 * 1024 * 1024) {
        _showSnack('파일 크기는 5MB 이하만 가능합니다.');
      } else if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        _showSnack('허용된 형식: JPG, JPEG, PNG');
      } else {
        setState(() => _selectedFile = file);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || !_isAgreed) {
      _showSnack('모든 필드를 작성하고 동의해주세요.');
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);

    _showSnack('문의가 전송되었습니다!');
    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    setState(() {
      _selectedType = null;
      _selectedPharmacy = null;
      _selectedFile = null;
      _isAgreed = false;
    });
  }

  Future<bool> _showConfirmationDialog() async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전송 확인'),
        content: const Text('작성하신 내용을 전송하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.cyan,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(colors: [Colors.black, Colors.grey[900]!])
              : LinearGradient(colors: [Colors.white, Colors.teal[50]!]),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('문의 내용을 입력해주세요', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _calculateProgress(),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.teal[100],
                  color: isDark ? Colors.tealAccent : Colors.cyan,
                ),
                const SizedBox(height: 16),
                _buildField(_nameController, '이름', '이름을 입력하세요', isDark, validator: _required),
                const SizedBox(height: 12),
                _buildField(_emailController, '이메일', 'example@email.com', isDark,
                    validator: _validateEmail),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _inquiryTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  decoration: _dropdownDecoration('문의 유형'),
                  onChanged: (value) => setState(() => _selectedType = value),
                  validator: (value) => value == null ? '문의 유형을 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPharmacy,
                  items: _pharmacies
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  decoration: _dropdownDecoration('관련 약국 (선택)'),
                  onChanged: (value) => setState(() => _selectedPharmacy = value),
                ),
                const SizedBox(height: 12),
                _buildField(_messageController, '문의 내용', '내용을 입력해주세요', isDark,
                    maxLines: 5, validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _appVersionController,
                  readOnly: true,
                  decoration: _readonlyDecoration('앱 버전'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('파일 첨부'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.tealAccent : Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_selectedFile != null)
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
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
                    const Expanded(
                      child: Text('개인정보 수집 및 이용에 동의합니다.'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? '전송 중...' : '문의 전송'),
                    style: ElevatedButton.styleFrom(
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

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  InputDecoration _readonlyDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    fillColor: Colors.grey[200],
    filled: true,
  );

  Widget _buildField(TextEditingController controller, String label, String hint, bool darkMode,
      {String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: darkMode ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _required(String? val) => val == null || val.trim().isEmpty ? '필수 항목입니다.' : null;

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요.';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return !emailRegex.hasMatch(val) ? '올바른 이메일 형식이 아닙니다.' : null;
  }
}
