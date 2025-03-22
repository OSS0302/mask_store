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
    {
      'name': 'KF94 마스크',
      'price': 1000,
      'quantity': 2,
      'wishlist': false,
      'image': 'assets/kf94.png',
      'soldOut': false,
      'selected': false
    },
    {
      'name': 'N95 마스크',
      'price': 1500,
      'quantity': 1,
      'wishlist': false,
      'image': 'assets/n95.png',
      'soldOut': false,
      'selected': false
    },
  ];
  double discount = 0.0;
  bool isLoading = false;
  double shippingFee = 3000.0;
  String selectedShipping = "일반 배송 (₩3000)";
  List<String> availableCoupons = ["SAVE10", "FREESHIP", "DISCOUNT5"];

  double get totalPrice => cartItems.fold(
      0.0, (sum, item) => sum + (item['price'] * item['quantity'])) *
      (1 - discount);
  double get finalPrice => totalPrice >= 50000 ? totalPrice : totalPrice + shippingFee;
  double get discountAmount => cartItems.fold(
      0.0, (sum, item) => sum + (item['price'] * item['quantity'])) *
      discount;

  void toggleWishlist(int index) {
    setState(() {
      cartItems[index]['wishlist'] = !cartItems[index]['wishlist'];
    });
  }

  void changeQuantity(int index, int delta) {
    setState(() {
      cartItems[index]['quantity'] = (cartItems[index]['quantity'] + delta).clamp(1, 99);
    });
  }

  void removeSelectedItems() {
    setState(() {
      cartItems.removeWhere((item) => item['selected']);
    });
  }

  void confirmRemoveSelectedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택한 상품 삭제'),
        content: const Text('선택한 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              removeSelectedItems();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('선택한 상품이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void applyDiscount(String promoCode) {
    setState(() {
      if (promoCode == "SAVE10") {
        discount = 0.1;
      } else if (promoCode == "FREESHIP" && totalPrice >= 30000) {
        shippingFee = 0;
      } else if (promoCode == "DISCOUNT5") {
        discount = 0.05;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 프로모션 코드입니다.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할인이 적용되었습니다!')),
      );
    });
  }

  void processCheckout() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제 완료!'),
        content: const Text('결제가 성공적으로 완료되었습니다. 감사합니다!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
      ),
      body: cartItems.isEmpty
          ? Center(
          child: const Text('장바구니가 비어 있습니다.', style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return FadeInUp(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Checkbox(
                        value: item['selected'],
                        onChanged: (value) {
                          setState(() {
                            item['selected'] = value!;
                          });
                        },
                      ),
                      title: Text(item['name']),
                      subtitle: Text(item['soldOut']
                          ? '품절됨'
                          : '₩${item['price']} x ${item['quantity']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => changeQuantity(index, -1),
                          ),
                          Text('${item['quantity']}',
                              style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => changeQuantity(index, 1),
                          ),
                          IconButton(
                            icon: Icon(
                              item['wishlist']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: item['wishlist'] ? Colors.red : null,
                            ),
                            onPressed: () => toggleWishlist(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 선택 삭제 버튼 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // 하나 이상 선택된 항목이 있을 때만 동작
                if (cartItems.any((item) => item['selected'])) {
                  confirmRemoveSelectedItems();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제할 상품을 선택해주세요.')),
                  );
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('선택 삭제'),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedShipping,
                  onChanged: (value) {
                    setState(() {
                      selectedShipping = value!;
                      shippingFee = value == "빠른 배송 (₩5000)" ? 5000 : 3000;
                    });
                  },
                  items: ["일반 배송 (₩3000)", "빠른 배송 (₩5000)"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('총 합계',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₩${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                  ],
                ),
                TextField(
                  decoration: const InputDecoration(
                      hintText: '프로모션 코드를 입력하세요',
                      border: OutlineInputBorder()),
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
이제 사용자가 각 상품의 체크박스를 선택한 후, 화면 하단의 "선택 삭제" 버튼을 눌러 선택한 항목들을 한꺼번에 삭제할 수 있습니다.






나의 말:
품절된 상품이 자동으로 비활성화되도록 변경
ChatGPT의 말:
4초 동안 이성 처리 완료
다음은 품절된 상품이 자동으로 비활성화되도록 개선한 코드입니다.

품절 상품은 체크박스, 수량 변경 버튼, 찜 버튼 등이 비활성화되며, UI에 '품절됨' 문구와 함께 흐릿하게 표시됩니다.
dart
복사
편집
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
    {
      'name': 'KF94 마스크',
      'price': 1000,
      'quantity': 2,
      'wishlist': false,
      'image': 'assets/kf94.png',
      'soldOut': true, // 품절 처리됨
      'selected': false
    },
    {
      'name': 'N95 마스크',
      'price': 1500,
      'quantity': 1,
      'wishlist': false,
      'image': 'assets/n95.png',
      'soldOut': false,
      'selected': false
    },
  ];
  double discount = 0.0;
  bool isLoading = false;
  double shippingFee = 3000.0;
  String selectedShipping = "일반 배송 (₩3000)";
  List<String> availableCoupons = ["SAVE10", "FREESHIP", "DISCOUNT5"];

  double get totalPrice => cartItems.fold(
      0.0, (sum, item) => sum + (item['price'] * item['quantity'])) *
      (1 - discount);
  double get finalPrice =>
      totalPrice >= 50000 ? totalPrice : totalPrice + shippingFee;
  double get discountAmount => cartItems.fold(
      0.0, (sum, item) => sum + (item['price'] * item['quantity'])) *
      discount;

  void toggleWishlist(int index) {
    if (cartItems[index]['soldOut']) return; // 비활성화 처리
    setState(() {
      cartItems[index]['wishlist'] = !cartItems[index]['wishlist'];
    });
  }

  void changeQuantity(int index, int delta) {
    if (cartItems[index]['soldOut']) return; // 비활성화 처리
    setState(() {
      cartItems[index]['quantity'] =
          (cartItems[index]['quantity'] + delta).clamp(1, 99);
    });
  }

  void removeSelectedItems() {
    setState(() {
      cartItems.removeWhere((item) => item['selected']);
    });
  }

  void confirmRemoveSelectedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택한 상품 삭제'),
        content: const Text('선택한 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              removeSelectedItems();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('선택한 상품이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void applyDiscount(String promoCode) {
    setState(() {
      if (promoCode == "SAVE10") {
        discount = 0.1;
      } else if (promoCode == "FREESHIP" && totalPrice >= 30000) {
        shippingFee = 0;
      } else if (promoCode == "DISCOUNT5") {
        discount = 0.05;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 프로모션 코드입니다.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할인이 적용되었습니다!')),
      );
    });
  }

  void processCheckout() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제 완료!'),
        content: const Text('결제가 성공적으로 완료되었습니다. 감사합니다!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
      ),
      body: cartItems.isEmpty
          ? Center(
          child: const Text('장바구니가 비어 있습니다.', style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return FadeInUp(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Opacity(
                      opacity: item['soldOut'] ? 0.5 : 1.0,
                      child: ListTile(
                        leading: Checkbox(
                          value: item['selected'],
                          onChanged: item['soldOut']
                              ? null
                              : (value) {
                            setState(() {
                              item['selected'] = value!;
                            });
                          },
                        ),
                        title: Text(item['name']),
                        subtitle: Text(item['soldOut']
                            ? '품절됨'
                            : '₩${item['price']} x ${item['quantity']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: item['soldOut']
                                  ? null
                                  : () => changeQuantity(index, -1),
                            ),
                            Text('${item['quantity']}',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: item['soldOut']
                                  ? null
                                  : () => changeQuantity(index, 1),
                            ),
                            IconButton(
                              icon: Icon(
                                item['wishlist']
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: item['wishlist'] ? Colors.red : null,
                              ),
                              onPressed: () => toggleWishlist(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 선택 삭제 버튼 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (cartItems.any((item) => item['selected'])) {
                  confirmRemoveSelectedItems();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제할 상품을 선택해주세요.')),
                  );
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('선택 삭제'),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedShipping,
                  onChanged: (value) {
                    setState(() {
                      selectedShipping = value!;
                      shippingFee = value == "빠른 배송 (₩5000)" ? 5000 : 3000;
                    });
                  },
                  items: ["일반 배송 (₩3000)", "빠른 배송 (₩5000)"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('총 합계',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₩${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                TextField(
                  decoration: const InputDecoration(hintText: '프로모션 코드를 입력하세요', border: OutlineInputBorder()),
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