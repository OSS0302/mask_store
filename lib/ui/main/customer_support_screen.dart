import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  List<Map<String, dynamic>> inquiryList = [];
  String searchQuery = '';
  String sortOption = '최신순';
  String categoryFilter = '전체';

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

  void clearAllInquiries() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('정말로 모든 문의를 삭제하시겠습니까?'),
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

  void sortInquiries() {
    setState(() {
      if (sortOption == '최신순') {
        inquiryList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      } else {
        inquiryList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      }
    });
  }

  void _showEditDialog(Map<String, dynamic> inquiry) {
    final titleController = TextEditingController(text: inquiry['title']);
    final contentController = TextEditingController(text: inquiry['content']);
    String selectedCategory = inquiry['category'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의 수정'),
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
                  setState(() => selectedCategory = value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() {
                inquiry['title'] = titleController.text;
                inquiry['content'] = contentController.text;
                inquiry['category'] = selectedCategory;
                inquiry['timestamp'] = DateTime.now().toIso8601String();
              });
              saveInquiries();
              Navigator.pop(context);
            },
            child: const Text('수정 완료'),
          ),
        ],
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
                  setState(() => selectedCategory = value);
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(inquiry['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("내용: ${inquiry['content']}"),
            Text("카테고리: ${inquiry['category']}"),
            Text("작성일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = inquiryList
        .where((inquiry) =>
    (inquiry['title'].contains(searchQuery) || inquiry['content'].contains(searchQuery)) &&
        (categoryFilter == '전체' || inquiry['category'] == categoryFilter))
        .toList();

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
            icon: const Icon(Icons.delete_forever),
            onPressed: clearAllInquiries,
            tooltip: '전체 삭제',
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
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
                    onTap: () => _showInquiryDetail(inquiry),
                    title: Text(inquiry['title']),
                    subtitle: Text(
                      '카테고리: ${inquiry['category']} | 날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(inquiry['timestamp']))}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(inquiry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteInquiry(inquiry['id']),
                        ),
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
        onPressed: _showInquiryDialog,
        child: const Icon(Icons.add),
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
    final results = inquiries
        .where((inq) =>
    inq['title'].contains(query) || inq['content'].contains(query))
        .toList();

    return ListView(
      children: results
          .map((inq) => ListTile(title: Text(inq['title'])))
          .toList(),
    );
  }
}
