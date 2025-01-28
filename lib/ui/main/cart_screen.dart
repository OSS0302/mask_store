import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/item_view_model.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartItems = context.watch<ItemViewModel>().cartItems;
    final cartTotal = context.watch<ItemViewModel>().calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Colors.teal,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                context.read<ItemViewModel>().clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('장바구니가 초기화되었습니다.')),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(
        child: Text(
          '장바구니가 비어 있습니다.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle:
                    Text('₩${item.price} / 수량: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () {
                            context
                                .read<ItemViewModel>()
                                .decreaseQuantity(item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            context
                                .read<ItemViewModel>()
                                .increaseQuantity(item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context
                                .read<ItemViewModel>()
                                .removeFromCart(item);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 합계',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₩${cartTotal.toStringAsFixed(2)}',
                  style:
                  const TextStyle(fontSize: 18, color: Colors.teal),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('결제 기능은 아직 지원되지 않습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 12),
            ),
            child: const Text(
              '결제하기',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
