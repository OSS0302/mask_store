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
          ),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // 지도 화면으로 이동
              context.push("/first");
            },
          ),
        ],
      ),
      body: SafeArea(
        child: maskStoreViewModel.state.isLoading
            ? Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '로딩 중 입니다 잠시만 기다려 주세요',
                style: TextStyle(fontSize: 16),
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
                        hintText: '약국 이름 검색',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: () {
                      // 정렬/필터 다이얼로그 열기
                      showSortFilterDialog(context, maskStoreViewModel);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Expanded(
              child: maskStoreViewModel.state.stores.isEmpty
                  ? Center(
                child: Text(
                  '검색 결과가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('재고 순'),
                onTap: () {
                  viewModel.sortByStock();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


