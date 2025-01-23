import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartItems = context.watch<MaskStoreViewModel>().cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Colors.teal,
      ),
      body: cartItems.isEmpty
          ? const Center(
        child: Text(
          '장바구니가 비어 있습니다.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () {
                context.read<MaskStoreViewModel>().removeFromCart(item);
              },
            ),
          );
        },
      ),
    );
  }
}
