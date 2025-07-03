import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MaterialApp(home: CustomerSupportScreen()));
}

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
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    fetchInquiries().then((_) => checkUnansweredInquiries());
  }

  Future<void> fetchInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? inquiriesJson = prefs.getString('inquiries');
    if (inquiriesJson != null) {
      setState(() {
        inquiryList =
        List<Map<String, dynamic>>.from(json.decode(inquiriesJson));
        sortInquiries();
      });
    }
  }

  Future<void> saveInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('inquiries', json.encode(inquiryList));
  }

  String recommendCategoryByAI(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('주문') || lower.contains('order')) return '주문';
    if (lower.contains('배송') || lower.contains('delivery')) return '배송';
    if (lower.contains('환불') || lower.contains('refund')) return '환불';
    if (lower.contains('기타')) return '기타';
    return '일반 문의';
  }

  String summarizeContentAI(String content) {
    if (content.length <= 50) return content;
    return content.substring(0, 50) + '...';
  }

  String suggestReplyTemplate(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('배송')) {
      return '안녕하세요, 배송 문의에 대해 확인 중입니다. 빠른 시일 내에 답변 드리겠습니다.';
    } else if (lower.contains('환불')) {
      return '환불 요청을 접수하였습니다. 처리 절차를 안내해 드리겠습니다.';
    } else if (lower.contains('주문')) {
      return '주문 관련 문의 감사합니다. 자세한 내용을 확인 후 연락드리겠습니다.';
    } else {
      return '문의해 주셔서 감사합니다. 검토 후 빠른 답변 드리겠습니다.';
    }
  }

  void addInquiry(String title, String content, String category) {
    final newInquiry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
      'status': '대기중',
      'favorite': false,
      'memo': '',
      'replyTemplate': suggestReplyTemplate(content),
      'answer': '', // **추가**
    };
    setState(() {
      inquiryList.add(newInquiry);
      sortInquiries();
    });
    saveInquiries();
  }

  void updateInquiry(String id, String title, String content, String category) {
    final index = inquiryList.indexWhere((inq) => inq['id'] == id);
    if (index != -1) {
      setState(() {
        inquiryList[index]['title'] = title;
        inquiryList[index]['content'] = content;
        inquiryList[index]['category'] = category;
        inquiryList[index]['replyTemplate'] = suggestReplyTemplate(content);
      });
      saveInquiries();
    }
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
        inquiryList[index]['favorite'] =
        !(inquiryList[index]['favorite'] ?? false);
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
      ['ID', '제목', '내용', '카테고리', '상태', '등록일', '메모', '답변'],
      ...inquiryList.map((e) => [
        e['id'],
        e['title'],
        e['content'],
        e['category'],
        e['status'],
        e['timestamp'],
        e['memo'] ?? '',
        e['answer'] ?? '',
      ])
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.csv');
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(file.path)], text: '고객 문의 CSV 파일');
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('고객 문의 내역')),
          pw.Table.fromTextArray(
            headers: [
              '제목',
              '내용',
              '카테고리',
              '상태',
              '등록일',
              '메모',
              '답변' // **추가**
            ],
            data: inquiryList
                .map((e) => [
              e['title'],
              e['content'],
              e['category'],
              e['status'],
              DateFormat('yyyy-MM-dd HH:mm')
                  .format(DateTime.parse(e['timestamp'])),
              e['memo'] ?? '',
              e['answer'] ?? '',
            ])
                .toList(),
          )
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF 파일이 저장되었습니다.')));
  }

  void checkUnansweredInquiries() {
    final now = DateTime.now();
    for (final inquiry in inquiryList) {
      final created = DateTime.parse(inquiry['timestamp']);
      final duration = now.difference(created);
      if (inquiry['status'] == '대기중' && duration.inHours >= 24) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '🚨 24시간 이상 미응답: "${inquiry['title']}" 문의를 확인해주세요.',
          ),
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = inquiryList.where((inquiry) {
      final matchesSearch = inquiry['title'].contains(searchQuery) ||
          inquiry['content'].contains(searchQuery);
      final matchesStatus =
          statusFilter == '전체' || inquiry['status'] == statusFilter;
      final matchesCategory =
          categoryFilter == '전체' || inquiry['category'] == categoryFilter;
      final matchesFavorite =
          !showFavoritesOnly || inquiry['favorite'] == true;

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesFavorite;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('고객 문의'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: InquirySearchDelegate(inquiryList),
            ),
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: exportToCSV),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: exportToPDF),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                      setState(() => statusFilter = value);
                    }
                  },
                ),
                DropdownButton<String>(
                  value: categoryFilter,
                  items: ['전체', '일반 문의', '주문', '배송', '환불', '기타']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => categoryFilter = value);
                    }
                  },
                ),
                Row(
                  children: [
                    const Text('즐겨찾기'),
                    Switch(
                      value: showFavoritesOnly,
                      onChanged: (val) =>
                          setState(() => showFavoritesOnly = val),
                    ),
                  ],
                ),
              ],
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
                        Text(summarizeContentAI(inquiry['content'])),
                        const SizedBox(height: 5),
                        Text(
                          '카테고리: ${inquiry['category']} | 상태: ${inquiry['status']} | 등록일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if ((inquiry['memo'] ?? '').isNotEmpty)
                          Text('메모: ${inquiry['memo']}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        if ((inquiry['answer'] ?? '').isNotEmpty)
                          Text('답변: ${inquiry['answer']}',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                        const SizedBox(height: 5),
                        Text(
                          '추천 답변: ${inquiry['replyTemplate']}',
                          style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: Icon(
                            inquiry['favorite'] == true
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                          ),
                          onPressed: () => toggleFavorite(inquiry['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showInquiryDialog(
                              isEdit: true, inquiry: inquiry),
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

  void _showInquiryDialog({bool isEdit = false, Map<String?, dynamic>? inquiry}) {
    final titleController = TextEditingController(text: inquiry?['title'] ?? '');
    final contentController = TextEditingController(text: inquiry?['content'] ?? '');
    String selectedCategory = inquiry?['category'] ?? '일반 문의';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '문의 수정' : '문의 등록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: '제목')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: '내용')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final aiCategory = recommendCategoryByAI(contentController.text);
                  setDialogState(() => selectedCategory = aiCategory);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AI 추천 카테고리: $aiCategory')),
                  );
                },
                child: const Text('AI 카테고리 추천'),
              ),
              DropdownButton<String>(
                value: selectedCategory,
                items: ['일반 문의', '주문', '배송', '환불', '기타']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedCategory = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
                  return;
                }
                if (isEdit && inquiry != null) {
                  updateInquiry(inquiry['id'], titleController.text, contentController.text, selectedCategory);
                } else {
                  addInquiry(titleController.text, contentController.text, selectedCategory);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? '수정' : '등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInquiryDetail(Map<String, dynamic> inquiry) {
    final memoController = TextEditingController(text: inquiry['memo'] ?? '');
    final answerController = TextEditingController(text: inquiry['answer'] ?? ''); // **추가**

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(inquiry['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inquiry['content']),
              const SizedBox(height: 10),
              TextField(
                controller: memoController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '메모'),
                onChanged: (val) {
                  setState(() => inquiry['memo'] = val);
                  saveInquiries();
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: answerController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '답변'),
                onChanged: (val) {
                  setState(() => inquiry['answer'] = val);
                  saveInquiries();
                },
              ), // **추가**
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              Text(
                'AI 추천 답변:\n${inquiry['replyTemplate']}',
                style: TextStyle(color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  memoController.text = inquiry['replyTemplate'];
                  setState(() {
                    inquiry['memo'] = inquiry['replyTemplate'];
                    inquiry['answer'] = inquiry['replyTemplate']; // **추가**
                  });
                  saveInquiries();
                },
                child: const Text('AI 답변 템플릿 메모/답변에 넣기'),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기'))],
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
  Widget buildResults(BuildContext context) {
    final results = inquiries
        .where((inq) =>
    inq['title'].contains(query) || inq['content'].contains(query))
        .toList();
    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = inquiries
        .where((inq) =>
    inq['title'].contains(query) || inq['content'].contains(query))
        .toList();
    return ListView(
      children: results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}
