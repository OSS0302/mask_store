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
        title: Text('마스크 재고 있는 약국 ${maskStoreViewModel.stores.length}곳 '),
      ),
      body: SafeArea(
        child: maskStoreViewModel.isLoading
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
            : RefreshIndicator(
                onRefresh: maskStoreViewModel.refreshStores, // 아래로 당길 때 호출되는 메서드
                child: ListView(
                  children: maskStoreViewModel.stores
                      .map((store) => StoreItem(maskStore: store))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
