import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _messageController.addListener(_autoInsertTag);
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
      _messageController.removeListener(_autoInsertTag);
      _messageController.text = '$tag$currentText'.trim();
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
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

    final uri = Uri(
      scheme: 'mailto',
      path: emailRecipients.join(','),
      queryParameters: {
        'subject': '[문의] $_selectedType',
        'body': emailBody,
      },
    );

    await launchUrl(uri);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('문의하기'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text('앱 버전: $_appVersion', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  // ... 생략된 UI 코드 ...
                  ..._filteredInquiries.map((entry) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: _getTypeIcon(entry['type']),
                      title: Text(entry['type']),
                      subtitle: Text(entry['date']),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry['message']),
                              if (entry['reply'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('관리자 응답: ${entry['reply']}'),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (entry['log']) const Icon(Icons.bug_report),
                                  if (entry['image'] != null)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.image),
                                    ),
                                  if (entry['file'] != null)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.attach_file),
                                    ),
                                ],
                              ),
                              if (entry['image'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.file(entry['image'], height: 100),
                                ),
                              if (entry['file'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Text('첨부 파일: ${entry['file'].name}'),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final file = entry['file'];
                                          final filePath = file is PlatformFile ? file.path : null;
                                          if (filePath != null) {
                                            await OpenFile.open(filePath);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('파일 경로를 찾을 수 없습니다. 해당 플랫폼에서는 파일 열기가 지원되지 않을 수 있습니다.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.download),
                                        label: const Text('열기'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )),
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
