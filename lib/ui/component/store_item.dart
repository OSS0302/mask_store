import 'package:flutter/material.dart';
import 'package:mask_store/data/model/mask_store.dart';

class StoreItem extends StatelessWidget {
  final MaskStore maskStore;

  const StoreItem({
    super.key,
    required this.maskStore,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(maskStore.storeName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(maskStore.address),
          Text('${maskStore.distance}km'),
        ],
      ),
      trailing: _RemainStateWidget(),
    );
  }

  Widget _RemainStateWidget() {
    // 초기값 설정
    var remainState = '판매중지';
    var description = '판매중지';
    var color = Colors.black;

    switch (maskStore.remainStatus) {
      case 'plenty':
        remainState = '충분';
        description = '100개 이상';
        color = Colors.green;

      case 'some':
        remainState = '보통';
        description = '30개 ~ 100개';
        color = Colors.yellow;

      case 'few':
        remainState = '부족';
        description = '2개 ~ 30개';
        color = Colors.black;

      case 'empty':
        remainState = '매진 임박';
        description = '1개';
        color = Colors.red;
    }
    return Column(
      children: [
        Text(
          remainState,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            color: color,
          ),
        ),
      ],
    );
  }
}
