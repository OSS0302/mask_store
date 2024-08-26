import 'package:flutter/material.dart';
import 'package:mask_store/data/model/mask_store.dart';
import 'package:mask_store/ui/component/store_item.dart';

class MaskStoreScreen extends StatelessWidget {
  const MaskStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마스크 재고 있는 약국 5곳 '),
      ),
      body: ListView(
        children: [
          StoreItem(
            maskStore: MaskStore(
              storeName: '승약국',
              address: '서울특별시 강북구 솔매로 38 (미아동)',
              distance: 10,
              remainStatus: 'empty',
              latitude: 10,
              longitude: 0,
            ),
          ),
        ],
      ),
    );
  }
}
