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
    setState(() {
      inquiryList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'category': category,
        'status': '대기',
        'timestamp': DateTime.now().toIso8601String(),
        'images': images,
      });
      sortInquiries();
    });
    saveInquiries();
  }

  void deleteInquiry(String id) {
    setState(() {
      inquiryList.removeWhere((inquiry) => inquiry['id'] == id);
    });
    saveInquiries();
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

  void sortInquiries() {
    setState(() {
      if (sortOption == '최신순') {
        inquiryList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      } else {
        inquiryList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      }
    });
  }

  Future<void> exportCSV() async {
    List<List<String>> csvData = [
      ['ID', '제목', '내용', '카테고리', '상태', '날짜']
    ];
    for (var inquiry in inquiryList) {
      csvData.add([
        inquiry['id'],
        inquiry['title'],
        inquiry['content'],
        inquiry['category'],
        inquiry['status'],
        inquiry['timestamp'],
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = inquiryList.where((inquiry) {
      final query = searchQuery.toLowerCase();
      return (statusFilter == '전체' || inquiry['status'] == statusFilter) &&
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
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: () {
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('전체 삭제'),
              content: const Text('정말 전체 삭제하시겠습니까?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                TextButton(onPressed: () {
                  setState(() => inquiryList.clear());
                  saveInquiries();
                  Navigator.pop(ctx);
                }, child: const Text('삭제')),
              ],
            ));
          })
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: sortOption,
                items: ['최신순', '오래된 순']
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
              const SizedBox(width: 20),
              DropdownButton<String>(
                value: statusFilter,
                items: ['전체', '대기', '진행중', '완료']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => statusFilter = value!),
              ),
            ],
          ),
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text('문의 내역이 없습니다.'))
                : ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final inquiry = filteredList[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 3,
                  child: ListTile(
                    title: Text(inquiry['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inquiry['content']),
                        Text('카테고리: ${inquiry['category']} | 상태: ${inquiry['status']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}', style: TextStyle(fontSize: 12)),
                        if (inquiry['images'] != null && inquiry['images'].isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: (inquiry['images'] as List<String>).map((path) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.file(File(path)))),
                                  child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
                                ),
                              )).toList(),
                            ),
                          )
                      ],
                    ),
                    trailing: Column(
                      children: [
                        DropdownButton<String>(
                          value: inquiry['status'],
                          onChanged: (val) => updateStatus(inquiry['id'], val!),
                          items: ['대기', '진행중', '완료']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                        ),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteInquiry(inquiry['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInquiryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInquiryDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = '일반 문의';
    List<String> selectedImages = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('문의하기'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: '제목')),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: '내용')),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: ['일반 문의', '주문', '배송', '환불', '기타']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => selectedCategory = value!),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('이미지 선택'),
                  onPressed: () async {
                    final imgs = await pickImages();
                    setStateDialog(() => selectedImages = imgs);
                  },
                ),
                Wrap(
                  spacing: 5,
                  children: selectedImages.map((e) => Image.file(File(e), width: 50, height: 50)).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                addInquiry(titleController.text, contentController.text, selectedCategory, selectedImages);
                Navigator.pop(context);
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final results = inquiries.where((inq) =>
    inq['title'].toLowerCase().contains(query.toLowerCase()) ||
        inq['content'].toLowerCase().contains(query.toLowerCase()) ||
        inq['category'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}