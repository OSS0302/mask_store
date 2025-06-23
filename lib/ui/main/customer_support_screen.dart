import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

/// Customer Support Inquiry Screen with advanced features:
/// 1. Category & Status filters
/// 2. Edit / Delete / Detail view
/// 3. CSV export (share)
/// 4. Optional image attachment per inquiry
/// 5. Enhanced search (title + content)
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> inquiryList = [];
  String sortOption = '최신순';
  String categoryFilter = '전체';
  String statusFilter = '전체';

  // 검색창 query 는 SearchDelegate 내부에서 관리 (검색 버튼 클릭 시).

  /// ===== LIFECYCLE =====
  @override
  void initState() {
    super.initState();
    fetchInquiries();
  }

  /// ===== PERSISTENCE =====
  Future<void> fetchInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('inquiries');
    if (saved != null) {
      setState(() {
        inquiryList = List<Map<String, dynamic>>.from(json.decode(saved));
        sortInquiries();
      });
    }
  }

  Future<void> saveInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inquiries', json.encode(inquiryList));
  }

  /// ===== CRUD =====
  void addInquiry({
    required String title,
    required String content,
    required String category,
    required String status,
    String? imagePath,
  }) {
    setState(() {
      inquiryList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'category': category,
        'status': status,
        'imagePath': imagePath,
        'timestamp': DateTime.now().toIso8601String(),
      });
      sortInquiries();
    });
    saveInquiries();
  }

  void updateInquiry(Map<String, dynamic> inquiry, {
    required String title,
    required String content,
    required String category,
    required String status,
    String? imagePath,
  }) {
    setState(() {
      inquiry['title'] = title;
      inquiry['content'] = content;
      inquiry['category'] = category;
      inquiry['status'] = status;
      inquiry['imagePath'] = imagePath;
      inquiry['timestamp'] = DateTime.now().toIso8601String();
    });
    saveInquiries();
  }

  void deleteInquiry(String id) {
    setState(() => inquiryList.removeWhere((inq) => inq['id'] == id));
    saveInquiries();
  }

  void clearAllInquiries() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 문의를 삭제하시겠습니까? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() => inquiryList.clear());
              saveInquiries();
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// ===== SORT & FILTER =====
  void sortInquiries() {
    if (sortOption == '최신순') {
      inquiryList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } else {
      inquiryList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    }
  }

  /// ===== CSV EXPORT =====
  Future<void> exportToCSV() async {
    const headers = ['제목', '내용', '카테고리', '상태', '작성일'];
    final rows = inquiryList.map((inq) => [
      inq['title'],
      inq['content'],
      inq['category'],
      inq['status'],
      inq['timestamp'],
    ]).toList();

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(headers.join(','));
    for (var row in rows) {
      csvBuffer.writeln(row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/inquiries_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvBuffer.toString(), flush: true);

    Share.shareXFiles([XFile(file.path)], text: '문의 내역 CSV 파일입니다');
  }

  /// ===== UI DIALOGS =====
  void _openAddDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = '일반 문의';
    String status = '대기';
    String? imagePath;

    Future<void> pickImage() async {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => imagePath = picked.path);
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('문의하기'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '제목')),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: '내용')),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        items: ['일반 문의', '주문', '배송', '환불', '기타']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => category = v ?? category),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        items: ['대기', '진행중', '완료']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => status = v ?? status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('이미지 선택'),
                      onPressed: pickImage,
                    ),
                    if (imagePath != null) const SizedBox(width: 6),
                    if (imagePath != null) const Text('선택됨'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                addInquiry(
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  category: category,
                  status: status,
                  imagePath: imagePath,
                );
                Navigator.pop(ctx);
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog(Map<String, dynamic> inquiry) {
    final titleCtrl = TextEditingController(text: inquiry['title']);
    final contentCtrl = TextEditingController(text: inquiry['content']);
    String category = inquiry['category'];
    String status = inquiry['status'];
    String? imagePath = inquiry['imagePath'];

    Future<void> pickImage() async {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => imagePath = picked.path);
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('문의 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '제목')),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: '내용')),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        items: ['일반 문의', '주문', '배송', '환불', '기타']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => category = v ?? category),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        items: ['대기', '진행중', '완료']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => status = v ?? status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('이미지 변경'),
                      onPressed: pickImage,
                    ),
                    if (imagePath != null) const SizedBox(width: 6),
                    if (imagePath != null) const Text('변경됨'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                updateInquiry(
                  inquiry,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  category: category,
                  status: status,
                  imagePath: imagePath,
                );
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailDialog(Map<String, dynamic> inquiry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(inquiry['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inquiry['imagePath'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.file(File(inquiry['imagePath']), height: 150),
                ),
              Text('내용: ${inquiry['content']}'),
              const SizedBox(height: 6),
              Text('카테고리: ${inquiry['category']}'),
              Text('상태: ${inquiry['status']}'),
              Text('작성일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기'))],
      ),
    );
  }

  /// ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    // Filters applied list
    final filtered = inquiryList.where((inq) {
      final searchDelegateActive = false; // placeholder, handled by SearchDelegate separately
      if (searchDelegateActive) return true;
      final matchesCategory = categoryFilter == '전체' || inq['category'] == categoryFilter;
      final matchesStatus = statusFilter == '전체' || inq['status'] == statusFilter;
      return matchesCategory && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('고객 문의'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            showSearch(context: context, delegate: InquirySearchDelegate(inquiryList));
          }),
          IconButton(icon: const Icon(Icons.download), tooltip: 'CSV 내보내기', onPressed: exportToCSV),
          IconButton(icon: const Icon(Icons.delete_forever), tooltip: '전체 삭제', onPressed: clearAllInquiries),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: sortOption,
                    isExpanded: true,
                    items: ['최신순', '오래된 순']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() { sortOption = v; sortInquiries(); });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: categoryFilter,
                    isExpanded: true,
                    items: ['전체', '일반 문의', '주문', '배송', '환불', '기타']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => categoryFilter = v ?? categoryFilter),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: statusFilter,
                    isExpanded: true,
                    items: ['전체', '대기', '진행중', '완료']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => statusFilter = v ?? statusFilter),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty ? const Center(child: Text('문의 내역이 없습니다.')) : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, idx) {
                final inq = filtered[idx];
                Color statusColor;
                switch (inq['status']) {
                  case '진행중':
                    statusColor = Colors.orange;
                    break;
                  case '완료':
                    statusColor = Colors.green;
                    break;
                  default:
                    statusColor = Colors.grey;
                }
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: inq['imagePath'] != null ? Image.file(File(inq['imagePath']), width: 40, height: 40, fit: BoxFit.cover) : null,
                    title: Text(inq['title']),
                    subtitle: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('${inq['status']} · ${inq['category']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openEditDialog(inq)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteInquiry(inq['id'])),
                      ],
                    ),
                    onTap: () => _openDetailDialog(inq),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openAddDialog, child: const Icon(Icons.add)),
    );
  }
}

/// SearchDelegate searching both title and content.
class InquirySearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> inquiries;
  InquirySearchDelegate(this.inquiries);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = inquiries.where((inq) => inq['title'].contains(query) || inq['content'].contains(query)).toList();
    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}
