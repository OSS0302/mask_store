import 'package:flutter/material.dart';
import 'package:mask_store/data/model/mask_store.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

class StoreItem extends StatelessWidget {
  final MaskStore maskStore;

  const StoreItem({
    super.key,
    required this.maskStore,
  });

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.read<MaskStoreViewModel>();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreInfo(),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RemainStateWidget(),
                IconButton(
                  icon: Icon(
                    maskStore.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: maskStore.isFavorite ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () {
                    maskStoreViewModel.toggleFavorite(maskStore);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maskStore.storeName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          maskStore.address,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${maskStore.distance} km',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _RemainStateWidget() {
    var remainState = '판매중지';
    var description = '판매중지';
    var color = Colors.black;

    switch (maskStore.remainStatus) {
      case 'plenty':
        remainState = '충분';
        description = '100개 이상';
        color = Colors.green;
        break;
      case 'some':
        remainState = '보통';
        description = '30개 ~ 100개';
        color = Colors.yellow;
        break;
      case 'few':
        remainState = '부족';
        description = '2개 ~ 30개';
        color = Colors.orange;
        break;
      case 'empty':
        remainState = '매진 임박';
        description = '1개 남음';
        color = Colors.red;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          remainState,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
