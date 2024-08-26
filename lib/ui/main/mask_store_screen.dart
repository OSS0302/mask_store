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
        title: Text('마스크 재고 있는 약국 ${maskStoreViewModel.stores.length}곳 '),
      ),
      body: ListView(
        children: maskStoreViewModel.stores
            .map((store) => StoreItem(maskStore: store))
            .toList(),
      ),
     );
  }
}
