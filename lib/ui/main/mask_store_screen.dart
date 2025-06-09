import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedType = '기능 문의';
  bool _includeLogs = false;
  bool _agree = false;
  File? _attachedImage;
  PlatformFile? _attachedFile;
  File? _autoCapturedScreenshot;
  String _appVersion = '...';
  bool _isSending = false;
  bool _sendCopyToSelf = false;

  final ScreenshotController _screenshotController = ScreenshotController();
  final List<Map<String, dynamic>> _previousInquiries = [];

  List<Map<String, dynamic>> get _recentInquiries {
    return _previousInquiries.take(3).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _messageController.addListener(_autoInsertTag);
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  void _autoInsertTag() {
    final tag = '#$_selectedType ';
    final currentText = _messageController.text;

    if (!currentText.startsWith(tag)) {
      final previousSelection = _messageController.selection;
      final newText = '$tag$currentText';

      _messageController.removeListener(_autoInsertTag);
      _messageController.text = newText;

      final newOffset = previousSelection.baseOffset + tag.length;
      _messageController.selection = TextSelection.collapsed(
        offset: newOffset.clamp(0, _messageController.text.length),
      );

      _messageController.addListener(_autoInsertTag);
    }
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFile = result.files.first;
      });
    }
  }

  Future<void> _captureScreenshotIfNeeded() async {
    if (_selectedType == '오류 신고') {
      final image = await _screenshotController.capture();
      if (image != null) {
        final tempDir = Directory.systemTemp;
        final file = await File('${tempDir.path}/screenshot.png').writeAsBytes(image);
        setState(() {
          _autoCapturedScreenshot = file;
        });
      }
    }
  }

  void _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보 처리방침에 동의해주세요.')),
      );
      return;
    }

    await _captureScreenshotIfNeeded();

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
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

  void _sendInquiry() async {
    setState(() => _isSending = true);

    await Future.delayed(const Duration(seconds: 1));

    final emailBody = '''
문의 유형: $_selectedType
앱 버전: $_appVersion
문의 내용:
${_messageController.text}

앱 로그 포함 여부: $_includeLogs
''';

    final emailRecipients = <String>['support@example.com'];
    if (_sendCopyToSelf) {
      emailRecipients.add('user@example.com');
    }

    final subject = '[문의] $_selectedType';
    final body = emailBody;
    final recipients = emailRecipients.join(',');

    final mailtoUri = Uri.parse(
      'mailto:$recipients?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (!await launchUrl(mailtoUri)) {
        throw '메일 앱 실행 실패';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메일 앱을 열 수 없습니다. 메시지를 복사해 직접 보내주세요.')),
      );
    }

    setState(() {
      _previousInquiries.insert(0, {
        'date': DateTime.now().toString().substring(0, 16),
        'type': _selectedType,
        'message': _messageController.text,
        'log': _includeLogs,
        'image': _attachedImage ?? _autoCapturedScreenshot,
        'file': _attachedFile,
        'reply': '안녕하세요. 문의해주셔서 감사합니다. 곧 답변드리겠습니다.',
      });

      _messageController.clear();
      _includeLogs = false;
      _attachedImage = null;
      _attachedFile = null;
      _autoCapturedScreenshot = null;
      _agree = false;
      _sendCopyToSelf = false;
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의가 전송되었습니다.')),
    );
  }

  List<Map<String, dynamic>> get _filteredInquiries {
    final query = _searchController.text.toLowerCase();
    return _previousInquiries.where((entry) {
      return entry['message'].toLowerCase().contains(query) ||
          entry['type'].toLowerCase().contains(query);
    }).toList();
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case '오류 신고':
        return const Icon(Icons.bug_report, color: Colors.redAccent);
      case '개선 제안':
        return const Icon(Icons.lightbulb, color: Colors.amber);
      case '기타':
        return const Icon(Icons.help_outline, color: Colors.grey);
      default:
        return const Icon(Icons.build, color: Colors.blueAccent);
    }
  }

  String _removeTag(String message, String type) {
    final tag = '#$type ';
    return message.startsWith(tag) ? message.replaceFirst(tag, '') : message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context);

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(locale.contactUs, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text('${locale.appVersion}: $_appVersion', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: locale.searchInquiry,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      fillColor: isDark ? Colors.grey[800] : null,
                      filled: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentInquiries.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('최근 문의', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._recentInquiries.map((entry) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: _getTypeIcon(entry['type']),
                            title: Text(entry['type']),
                            subtitle: Text(entry['date']),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(entry['type']),
                                  content: Text(_removeTag(entry['message'], entry['type'])),
                                  actions: [
                                    TextButton(
                                      child: const Text('닫기'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: '문의 유형'),
                          items: [
                            '기능 문의',
                            '오류 신고',
                            '개선 제안',
                            '기타',
                          ].map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                              });
                              _autoInsertTag();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: '문의 내용',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '문의 내용을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('이미지 첨부'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('파일 첨부'),
                            ),
                          ],
                        ),
                        if (_attachedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('이미지 첨부됨: ${_attachedImage!.path.split('/').last}'),
                          ),
                        if (_attachedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('파일 첨부됨: ${_attachedFile!.name}'),
                          ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _includeLogs,
                          onChanged: (val) => setState(() => _includeLogs = val ?? false),
                          title: const Text('앱 로그 포함'),
                        ),
                        CheckboxListTile(
                          value: _sendCopyToSelf,
                          onChanged: (val) => setState(() => _sendCopyToSelf = val ?? false),
                          title: const Text('나에게도 사본 보내기'),
                        ),
                        CheckboxListTile(
                          value: _agree,
                          onChanged: (val) => setState(() => _agree = val ?? false),
                          title: const Text('개인정보 처리방침에 동의합니다.'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitInquiry,
                            child: const Text('문의 전송'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isSending)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}