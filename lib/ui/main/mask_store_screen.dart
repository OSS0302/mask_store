import 'package:flutter/material.dart';
import 'package:mask_store/ui/component/store_item.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';

class MaskStoreScreen extends StatelessWidget {
  final MaskStoreViewModel maskStoreViewModel;

  const MaskStoreScreen({
    super.key,
    required this.maskStoreViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('마스크 재고 있는 약국 ${maskStoreViewModel.stores.length}곳 '),
      ),
      body: ListenableBuilder(
        listenable: maskStoreViewModel, builder: (BuildContext context, Widget? child) {
          return ListView(
            children: maskStoreViewModel.stores
                .map((store) => StoreItem(maskStore: store)).toList(),
          );
      },),
    );
  }
}
