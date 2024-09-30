import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

import '../component/store_item.dart';

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
            fontSize: 20, // 폰트 크기 조정
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal, // AppBar 색상 변경

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
                style: TextStyle(fontSize: 16), // 텍스트 크기 조정
              ),
            ],
          ),
        )
            : Column(
          children: [
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
                  suffixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey, // 구분선 색상
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: maskStoreViewModel.refreshStores,
                child: ListView.builder(
                  controller: maskStoreViewModel.scrollController,
                  itemCount: maskStoreViewModel.state.stores.length,
                  itemBuilder: (context, index) {
                    final store = maskStoreViewModel.state.stores[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // 약국 아이템 위젯
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 카드의 둥근 모서리
                        ),
                        elevation: 5,
                        shadowColor: Colors.grey.withOpacity(0.2),
                        child: StoreItem(maskStore: store), // 약국 아이템 위젯
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
}
