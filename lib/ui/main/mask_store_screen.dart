import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/routes.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../component/store_item.dart';
import 'map_view_screen.dart';

class MaskStoreScreen extends StatelessWidget {
  const MaskStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '마스크 재고 있는 약국 ${maskStoreViewModel.state.stores.length}곳',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
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
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: maskStoreViewModel.state.isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Colors.teal),
                SizedBox(height: 16),
                Text(
                  '로딩 중 입니다 잠시만 기다려 주세요',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
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
                          fillColor: Colors.white,
                          hintText: '약국 이름 검색',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(Icons.search, color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_alt, color: Colors.teal),
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
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('정렬 및 필터'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('거리 순'),
                onTap: () {
                  viewModel.sortByDistance();
                  context.pop();
                },
              ),
              ListTile(
                title: const Text('재고 순'),
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
