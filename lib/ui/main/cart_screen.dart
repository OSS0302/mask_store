import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> cartItems = [
    {'name': 'KF94 마스크', 'price': 1000, 'quantity': 2},
    {'name': 'N95 마스크', 'price': 1500, 'quantity': 1},
  ];
  double discount = 0.0;
  bool isLoading = false;

  double get totalPrice => cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])) * (1 - discount);

  void clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('장바구니 초기화'),
        content: const Text('정말 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() => cartItems.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('장바구니가 초기화되었습니다.')),
              );
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void applyDiscount(String promoCode) {
    if (promoCode == "SAVE10") {
      setState(() => discount = 0.1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('10% 할인이 적용되었습니다!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 프로모션 코드입니다.')),
      );
    }
  }

  void processCheckout() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결제 완료! 감사합니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: clearCart,
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '장바구니가 비어 있습니다.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('스토어로 이동 기능 준비 중')),
                );
              },
              child: const Text('스토어 둘러보기'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: Key(item['name']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => cartItems.removeAt(index));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['name']}이 삭제되었습니다.')),
                    );
                  },
                  child: FadeIn(
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text('₩${item['price']} x ${item['quantity']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              setState(() {
                                if (item['quantity'] > 1) {
                                  item['quantity']--;
                                }
                              });
                            },
                          ),
                          Text('${item['quantity']}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () {
                              setState(() => item['quantity']++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '총 합계',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₩${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: '프로모션 코드를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => applyDiscount(value),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : processCheckout,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('결제하기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
