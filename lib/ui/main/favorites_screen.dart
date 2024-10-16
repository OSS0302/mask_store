import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../component/store_item.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    final favoriteStores = maskStoreViewModel.state.stores.where((store) => store.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기'),
        backgroundColor: Colors.teal,
      ),
      body: favoriteStores.isEmpty
          ? const Center(child: Text('즐겨찾기 한 약국이 없습니다.'))
          : ListView.builder(
        itemCount: favoriteStores.length,
        itemBuilder: (context, index) {
          final store = favoriteStores[index];
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
    );
  }
}
