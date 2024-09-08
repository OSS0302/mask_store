import 'package:flutter/material.dart';
import 'package:mask_store/ui/component/store_item.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

class MaskStoreScreen extends StatelessWidget {
  const MaskStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('마스크 재고 있는 약국 ${maskStoreViewModel.state.stores.length}곳 '),
        actions: [
          Switch(
            value: maskStoreViewModel.isDarkMode, // 현재 다크 모드 상태
            onChanged: (value) {
              maskStoreViewModel.toggleDarkMode(); // 다크 모드 토글
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
            children: [
              CircularProgressIndicator(),
              Text('로딩 중 입니다 잠시만 기다려 주세요'),
            ],
          ),
        )
            : Column(
          children: [
            // 검색 입력 필드를 바디에 추가
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) {
                  maskStoreViewModel.filterStores(value); // 검색어에 따라 필터링
                },
                decoration: InputDecoration(
                  hintText: '약국 이름 검색',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: maskStoreViewModel.refreshStores, // 아래로 당길 때 호출되는 메서드
                child: ListView.builder(
                  controller: maskStoreViewModel.scrollController,
                  itemCount: maskStoreViewModel.state.stores.length,
                  itemBuilder: (context, index) {
                    final store = maskStoreViewModel.state.stores[index];
                    return StoreItem(maskStore: store);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
