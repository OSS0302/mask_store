import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../component/store_item.dart';

class MaskStoreScreen extends StatelessWidget {
  const MaskStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    final isDarkMode = maskStoreViewModel.isDarkMode; // 다크모드 여부 확인

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '마스크 재고 있는 약국 ${maskStoreViewModel.state.stores.length}곳',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black, // 다크모드에 따라 글자 색상 변경
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal, // 다크모드 배경색
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              // 지도 화면으로 이동
              context.push("/mapViewScreen");
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900] // 다크모드 배경색
                : [Colors.teal.shade100, Colors.teal.shade50], // 라이트모드 배경색
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: maskStoreViewModel.state.isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: isDarkMode ? Colors.white : Colors.teal),
                const SizedBox(height: 16),
                Text(
                  '로딩 중 입니다 잠시만 기다려 주세요',
                  style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.teal),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          maskStoreViewModel.filterStores(value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          hintText: '약국 이름 검색',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.filter_alt, color: isDarkMode ? Colors.white : Colors.teal),
                      onPressed: () {
                        // 정렬/필터 다이얼로그 열기
                        showSortFilterDialog(context, maskStoreViewModel);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.teal),
              Expanded(
                child: maskStoreViewModel.state.stores.isEmpty
                    ? Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.grey.shade600),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: maskStoreViewModel.refreshStores,
                  child: ListView.builder(
                    controller: maskStoreViewModel.scrollController,
                    itemCount: maskStoreViewModel.state.stores.length,
                    itemBuilder: (context, index) {
                      final store = maskStoreViewModel.state.stores[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.2),
                          child: StoreItem(maskStore: store),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSortFilterDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = viewModel.isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            '정렬 및 필터',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('거리 순', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByDistance();
                  context.pop();
                },
              ),
              ListTile(
                title: Text('재고 순', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByStock();
                  context.pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
