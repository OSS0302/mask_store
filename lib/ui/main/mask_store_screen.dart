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
        title: Text(
          '마스크 재고 있는 약국 ${maskStoreViewModel.state.stores.length}곳',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white, // 글자 색상 통일
          ),
        ),
        backgroundColor: Colors.teal, // AppBar 색상
        actions: [
          IconButton(
            icon: Icon(maskStoreViewModel.isDarkMode
                ? Icons.nightlight_round
                : Icons.wb_sunny),
            onPressed: () {
              maskStoreViewModel.toggleDarkMode();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: maskStoreViewModel.state.isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal), // 로딩 색상 변경
              ),
              const SizedBox(height: 16),
              const Text(
                '로딩 중입니다. 잠시만 기다려 주세요.',
                style: TextStyle(fontSize: 18, color: Colors.black54), // 텍스트 스타일 개선
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
                  maskStoreViewModel.filterStores(value);
                },
                decoration: InputDecoration(
                  hintText: '약국 이름을 입력하세요',
                  hintStyle: const TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.teal), // 아이콘 색상
                ),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: maskStoreViewModel.refreshStores,
                color: Colors.teal, // 리프레시 색상 변경
                child: ListView.builder(
                  controller: maskStoreViewModel.scrollController,
                  itemCount: maskStoreViewModel.state.stores.length,
                  itemBuilder: (context, index) {
                    final store = maskStoreViewModel.state.stores[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
