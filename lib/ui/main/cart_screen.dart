import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:share_plus/share_plus.dart'; // 실제 공유 기능 사용 시

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [
    {
      'name': 'KF94 마스크',
      'price': 1000,
      'quantity': 2,
      'wishlist': false,
      'image': 'assets/kf94.png',
      'soldOut': true,
      'selected': false,
    },
    {
      'name': 'N95 마스크',
      'price': 1500,
      'quantity': 1,
      'wishlist': false,
      'image': 'assets/n95.png',
      'soldOut': false,
      'selected': false,
    },
  ];

  double discount = 0.0;
  bool isLoading = false;
  double shippingFee = 3000.0;
  String selectedShipping = "일반 배송 (₩3000)";
  List<String> availableCoupons = ["SAVE10", "FREESHIP", "DISCOUNT5"];
  String sortOption = "none";

  // 추천 상품 예시
  final List<Map<String, dynamic>> recommendedProducts = [
    {
      'name': '손 소독제',
      'price': 2000,
      'image': 'assets/sanitizer.png',
    },
    {
      'name': '일회용 장갑',
      'price': 500,
      'image': 'assets/gloves.png',
    },
    {
      'name': '소독 티슈',
      'price': 800,
      'image': 'assets/disinfectant.png',
    },
  ];

  double get totalPrice => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
  ) *
      (1 - discount);

  double get finalPrice =>
      totalPrice >= 50000 ? totalPrice : totalPrice + shippingFee;

  double get discountAmount => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
  ) *
      discount;

  void toggleWishlist(int index) {
    if (cartItems[index]['soldOut']) return;
    setState(() {
      cartItems[index]['wishlist'] = !cartItems[index]['wishlist'];
    });
  }

  void changeQuantity(int index, int delta) {
    if (cartItems[index]['soldOut']) return;
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
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
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

  // 재입고 알림 신청 (품절 상품용)
  void requestRestockNotification(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$productName 재입고 알림 신청이 완료되었습니다.')),
    );
  }

  // 장바구니 공유 (실제 공유 기능은 share_plus 패키지 사용 가능)
  void shareCart() {
    String cartContent = cartItems
        .map((item) =>
    "${item['name']} - ₩${item['price']} x ${item['quantity']}")
        .join("\n");
    // Share.share(cartContent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('장바구니 내용이 공유되었습니다.\n$cartContent')),
    );
  }

  // 장바구니 저장 기능 (SharedPreferences 사용)
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonCart = jsonEncode(cartItems);
    await prefs.setString('cartItems', jsonCart);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('장바구니가 저장되었습니다.')),
    );
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonCart = prefs.getString('cartItems');
    if (jsonCart != null) {
      List<dynamic> loaded = jsonDecode(jsonCart);
      setState(() {
        cartItems = loaded.cast<Map<String, dynamic>>();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장바구니가 불러와졌습니다.')),
      );
    }
  }

  // 정렬 기능
  void sortCart(String option) {
    setState(() {
      sortOption = option;
      if (option == "가격 낮은 순") {
        cartItems.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (option == "가격 높은 순") {
        cartItems.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  // 추천 상품 장바구니에 추가
  void addRecommendedProduct(Map<String, dynamic> product) {
    setState(() {
      cartItems.add({
        'name': product['name'],
        'price': product['price'],
        'quantity': 1,
        'wishlist': false,
        'image': product['image'],
        'soldOut': false,
        'selected': false,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']}이(가) 추가되었습니다.')),
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: shareCart,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveCart,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: loadCart,
          ),
          PopupMenuButton<String>(
            onSelected: sortCart,
            itemBuilder: (context) => [
              const PopupMenuItem(value: "가격 낮은 순", child: Text("가격 낮은 순")),
              const PopupMenuItem(value: "가격 높은 순", child: Text("가격 높은 순")),
            ],
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
          : SingleChildScrollView(
        child: Column(
          children: [
            // 장바구니 리스트
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
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
                        trailing: item['soldOut']
                            ? ElevatedButton(
                          onPressed: () =>
                              requestRestockNotification(item['name']),
                          child: const Text('재입고 알림'),
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              onPressed: () =>
                                  changeQuantity(index, -1),
                            ),
                            Text(
                              '${item['quantity']}',
                              style:
                              const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline),
                              onPressed: () =>
                                  changeQuantity(index, 1),
                            ),
                            IconButton(
                              icon: Icon(
                                item['wishlist']
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: item['wishlist']
                                    ? Colors.red
                                    : null,
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
            // 선택 삭제 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (cartItems.any((item) => item['selected'])) {
                    confirmRemoveSelectedItems();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('삭제할 상품을 선택해주세요.')),
                    );
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('선택 삭제'),
                style: ElevatedButton.styleFrom(primary: Colors.red),
              ),
            ),
            const SizedBox(height: 10),
            // 배송 옵션, 총 합계, 프로모션 및 결제 영역
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
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 합계',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₩${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                    ],
                  ),
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
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text('결제하기'),
                  ),
                ],
              ),
            ),
            // 추천 상품 영역
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '추천 상품',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  return GestureDetector(
                    onTap: () => addRecommendedProduct(product),
                    child: Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              product['image'],
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₩${product['price']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
