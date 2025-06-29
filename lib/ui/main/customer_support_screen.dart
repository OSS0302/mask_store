import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

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
    if (lower.contains('배송') || lower.contains('배송')) return '배송';
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

  void addInquiry(String title, String content, [String? manualCategory]) {
    final category = manualCategory ?? recommendCategoryByAI(content);
    final newInquiry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
      'status': '대기중',
      'favorite': false,
      'memo': '', // 메모는 빈 상태
      'replyTemplate': suggestReplyTemplate(content), // AI 답변 템플릿 추가
    };
    setState(() {
      inquiryList.add(newInquiry);
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
      ['ID', '제목', '내용', '카테고리', '상태', '등록일', '메모'],
      ...inquiryList.map((e) => [
            e['id'],
            e['title'],
            e['content'],
            e['category'],
            e['status'],
            e['timestamp'],
            e['memo'] ?? '',
          ])
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('CSV 파일이 저장되었습니다.')));
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('고객 문의 내역')),
          pw.Table.fromTextArray(
            headers: ['제목', '내용', '카테고리', '상태', '등록일', '메모'],
            data: inquiryList
                .map((e) => [
                      e['title'],
                      e['content'],
                      e['category'],
                      e['status'],
                      DateFormat('yyyy-MM-dd HH:mm')
                          .format(DateTime.parse(e['timestamp'])),
                      e['memo'] ?? '',
                    ])
                .toList(),
          )
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inquiries.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PDF 파일이 저장되었습니다.')));
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
      '처리중': inquiryList.where((e) => e['처리중']).length,
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
          // 필터 및 정렬 옵션
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
                      onChanged: (val) =>
                          setState(() => showFavoritesOnly = val),
                    ),
                  ],
                )
              ],
            ),
          ),

          // 상태별 문의 개수 표시

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
                              // AI 요약 보여주기
                              Text(summarizeContentAI(inquiry['content'])),
                              const SizedBox(height: 5),
                              Text(
                                '카테고리: ${inquiry['category']} | 상태: ${inquiry['status']} 등록일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                              if ((inquiry['memo'] ?? '').isNotEmpty)
                                Text('메모: ${inquiry['memo']}',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic)),
                              const SizedBox(height: 5),
                              // AI 답변 템플릿 보여주기
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
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('문의하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목')),
              TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '내용')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final aiCategory =
                      recommendCategoryByAI(contentController.text);
                  setDialogState(() {
                    selectedCategory = aiCategory;
                  });
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
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
                  return;
                }
                addInquiry(titleController.text, contentController.text,
                    selectedCategory);
                Navigator.pop(context);
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInquiryDetail(Map<String, dynamic> inquiry) {
    final memoController = TextEditingController(text: inquiry['memo'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(inquiry['title']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // 메모에 AI 답변 템플릿 자동 삽입
                  memoController.text = inquiry['replyTemplate'];
                  setState(() => inquiry['memo'] = inquiry['replyTemplate']);
                  saveInquiries();
                },
                child: const Text('AI 답변 템플릿 메모에 넣기'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기')),
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
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    final results =
        inquiries.where((inq) => inq['title'].contains(query)).toList();
    return ListView(
      children: results
          .map((inq) => ListTile(
                title: Text(inq['title']),
                onTap: () {
                  close(context, null);
                  // 추가 동작 가능
                },
              ))
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results =
        inquiries.where((inq) => inq['title'].contains(query)).toList();
    return ListView(
      children:
          results.map((inq) => ListTile(title: Text(inq['title']))).toList(),
    );
  }
}
