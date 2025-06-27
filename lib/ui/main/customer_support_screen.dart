import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  List<Map<String, dynamic>> inquiryList = [];
  String searchQuery = '';
  String sortOption = '최신순';
  String statusFilter = '전체';
  String categoryFilter = '전체';
  bool filterWithImages = false;
  final ImagePicker _picker = ImagePicker();

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
        sortInquiries();
      });
    }
  }

  Future<void> saveInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('inquiries', json.encode(inquiryList));
  }

  void addInquiry(String title, String content, String category, List<String> images) {
    final newInquiry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'category': category,
      'status': '대기',
      'timestamp': DateTime.now().toIso8601String(),
      'images': images,
      'favorite': false,
      'memo': '',
    };

    setState(() {
      if (sortOption == '최신순') {
        inquiryList.insert(0, newInquiry);
      } else {
        inquiryList.add(newInquiry);
        sortInquiries();
      }
    });

    saveInquiries();
  }

  void deleteInquiry(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 문의를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        inquiryList.removeWhere((inquiry) => inquiry['id'] == id);
      });
      saveInquiries();
    }
  }

  void updateStatus(String id, String newStatus) {
    setState(() {
      final index = inquiryList.indexWhere((inquiry) => inquiry['id'] == id);
      if (index != -1) {
        inquiryList[index]['status'] = newStatus;
      }
    });
    saveInquiries();
  }

  void toggleFavorite(String id) {
    setState(() {
      final index = inquiryList.indexWhere((inquiry) => inquiry['id'] == id);
      if (index != -1) {
        inquiryList[index]['favorite'] = !(inquiryList[index]['favorite'] ?? false);
      }
    });
    saveInquiries();
  }

  void sortInquiries() {
    setState(() {
      if (sortOption == '최신순') {
        inquiryList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      } else if (sortOption == '오래된 순') {
        inquiryList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      } else if (sortOption == '제목순') {
        inquiryList.sort((a, b) => a['title'].compareTo(b['title']));
      } else if (sortOption == '카테고리순') {
        inquiryList.sort((a, b) => a['category'].compareTo(b['category']));
      }
    });
  }

  Future<void> exportCSV() async {
    List<List<String>> csvData = [
      ['ID', '제목', '내용', '카테고리', '상태', '날짜', '이미지수', '즐겨찾기']
    ];
    for (var inquiry in inquiryList) {
      csvData.add([
        inquiry['id'],
        inquiry['title'],
        inquiry['content'],
        inquiry['category'],
        inquiry['status'],
        inquiry['timestamp'],
        (inquiry['images'] as List<String>).length.toString(),
        inquiry['favorite'].toString()
      ]);
    }
    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inquiries.csv';
    final file = File(path);
    await file.writeAsString(csv);
    final xfile = XFile(path);
    await Share.shareXFiles([xfile], text: '문의 내역 CSV 파일입니다.');
  }

  Future<void> backupToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');
    await file.writeAsString(jsonEncode(inquiryList));
    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], text: '문의 내역 백업 파일입니다.');
  }

  Future<List<String>> pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    return picked?.map((x) => x.path).toList() ?? [];
  }

  int countStatus(String status) {
    return inquiryList.where((inq) => inq['status'] == status).length;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = inquiryList.where((inquiry) {
      final query = searchQuery.toLowerCase();
      final matchesImage = !filterWithImages || (inquiry['images'] != null && (inquiry['images'] as List).isNotEmpty);
      return (statusFilter == '전체' || inquiry['status'] == statusFilter) &&
          (categoryFilter == '전체' || inquiry['category'] == categoryFilter) &&
          matchesImage &&
          (inquiry['title'].toLowerCase().contains(query) ||
              inquiry['content'].toLowerCase().contains(query) ||
              inquiry['category'].toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('고객 문의'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            showSearch(context: context, delegate: InquirySearchDelegate(inquiryList));
          }),
          IconButton(icon: const Icon(Icons.download), onPressed: exportCSV),
          IconButton(icon: const Icon(Icons.backup), onPressed: backupToFile),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
            child: Row(
              children: [
                Text('대기: ${countStatus("대기")}'),
                const SizedBox(width: 10),
                Text('진행중: ${countStatus("진행중")}'),
                const SizedBox(width: 10),
                Text('완료: ${countStatus("완료")}'),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: sortOption,
                items: ['최신순', '오래된 순', '제목순', '카테고리순']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      sortOption = value;
                      sortInquiries();
                    });
                  }
                },
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: statusFilter,
                items: ['전체', '대기', '진행중', '완료']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => statusFilter = value!),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: categoryFilter,
                items: ['전체', '일반 문의', '주문', '배송', '환불', '기타']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => categoryFilter = value!),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  const Text('이미지 포함'),
                  Switch(value: filterWithImages, onChanged: (val) => setState(() => filterWithImages = val)),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final inquiry = filteredList[index];
                final hasImages = (inquiry['images'] as List).isNotEmpty;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(
                        inquiry['favorite'] ? Icons.star : Icons.star_border,
                        color: inquiry['favorite'] ? Colors.amber : null,
                      ),
                      onPressed: () => toggleFavorite(inquiry['id']),
                    ),
                    title: Text(inquiry['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('카테고리: ${inquiry['category']}'),
                        Text('상태: ${inquiry['status']}'),
                        Text('날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}'),
                        if (hasImages) const Icon(Icons.image, size: 16),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteInquiry(inquiry['id']),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(inquiry['title']),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('내용:\n${inquiry['content']}\n'),
                                Text('카테고리: ${inquiry['category']}'),
                                Text('상태: ${inquiry['status']}'),
                                Text('날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}'),
                                if (hasImages)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text('첨부 이미지:'),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (inquiry['images'] as List<String>)
                                            .map((imgPath) => Image.file(File(imgPath), width: 80, height: 80, fit: BoxFit.cover))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
                            TextButton(
                              onPressed: () {
                                final newStatus = inquiry['status'] == '대기'
                                    ? '진행중'
                                    : (inquiry['status'] == '진행중' ? '완료' : '대기');
                                updateStatus(inquiry['id'], newStatus);
                                Navigator.pop(context);
                              },
                              child: const Text('상태 변경'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InquirySearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> inquiries;
  InquirySearchDelegate(this.inquiries);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = inquiries.where((inq) => inq['title'].toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}