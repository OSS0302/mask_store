import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  bool showFavoritesOnly = false;

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

  void addInquiry(String title, String content, String category) {
    setState(() {
      inquiryList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
        'status': '대기중',
        'favorite': false,
        'memo': '',
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

  void toggleFavorite(String id) {
    setState(() {
      final index = inquiryList.indexWhere((inq) => inq['id'] == id);
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
      } else {
        inquiryList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      }
    });
  }

  Future<void> exportToCSV() async {
    List<List<dynamic>> rows = [
      ['ID', '제목', '내용', '카테고리', '상태', '등록일'],
      ...inquiryList.map((e) => [
        e['id'],
        e['title'],
        e['content'],
        e['category'],
        e['status'],
        e['timestamp'],
      ])
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV 파일이 저장되었습니다.')));
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('고객 문의 내역')),
          pw.Table.fromTextArray(
            headers: ['제목', '내용', '카테고리', '상태', '등록일'],
            data: inquiryList.map((e) => [
              e['title'],
              e['content'],
              e['category'],
              e['status'],
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(e['timestamp'])),
            ]).toList(),
          )
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF 파일이 저장되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = inquiryList.where((inquiry) {
      return inquiry['title'].contains(searchQuery) &&
          (statusFilter == '전체' || inquiry['status'] == statusFilter) &&
          (!showFavoritesOnly || inquiry['favorite'] == true);
    }).toList();

    Map<String, int> statusCounts = {
      '대기중': inquiryList.where((e) => e['status'] == '대기중').length,
      '처리중': inquiryList.where((e) => e['status'] == '처리중').length,
      '완료': inquiryList.where((e) => e['status'] == '완료').length,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('고객 문의'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: InquirySearchDelegate(inquiryList),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportToPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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
                DropdownButton<String>(
                  value: statusFilter,
                  items: ['전체', '대기중', '처리중', '완료']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        statusFilter = value;
                      });
                    }
                  },
                ),
                Row(
                  children: [
                    const Text('즐겨찾기'),
                    Switch(
                      value: showFavoritesOnly,
                      onChanged: (val) => setState(() => showFavoritesOnly = val),
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '대기중: ${statusCounts['대기중']}  |  처리중: ${statusCounts['처리중']}  |  완료: ${statusCounts['완료']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
                      const SizedBox(height: 5),
                      Text(
                          '카테고리: ${inquiry['category']} | 상태: ${inquiry['status']}
                          등록일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    if ((inquiry['memo'] ?? '').isNotEmpty)
                Text('메모: ${inquiry['memo']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
                ),
                trailing: Wrap(
                spacing: 8,
                children: [
                IconButton(
                icon: Icon(
                inquiry['favorite'] == true ? Icons.star : Icons.star_border,
                color: Colors.orange,
                ),
                onPressed: () => toggleFavorite(inquiry['id']),
                ),
                IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteInquiry(inquiry['id']),
                ),
                ],
                ),
                onTap: () => _showInquiryDetail(inquiry),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '제목')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: '내용')),
            DropdownButton<String>(
              value: selectedCategory,
              items: ['일반 문의', '주문', '배송', '환불', '기타']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              addInquiry(titleController.text, contentController.text, selectedCategory);
              Navigator.pop(context);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  void _showInquiryDetail(Map<String, dynamic> inquiry) {
    final memoController = TextEditingController(text: inquiry['memo'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(inquiry['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(inquiry['content']),
            TextField(
              controller: memoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '메모'),
              onChanged: (val) {
                setState(() => inquiry['memo'] = val);
                saveInquiries();
              },
            ),
            DropdownButton<String>(
              value: inquiry['status'],
              items: ['대기중', '처리중', '완료']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => inquiry['status'] = value);
                  saveInquiries();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
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
    final results = inquiries.where((inq) => inq['title'].contains(query)).toList();
    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}