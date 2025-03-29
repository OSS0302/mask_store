import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'rating': 4.2,
      'note': '',
    },
    {
      'name': 'N95 마스크',
      'price': 1500,
      'quantity': 1,
      'wishlist': false,
      'image': 'assets/n95.png',
      'soldOut': false,
      'selected': false,
      'rating': 4.5,
      'note': '',
    },
  ];

  // 저장된 상품 목록 (나중에 구매용) 및 최근 본 상품 목록
  List<Map<String, dynamic>> savedItems = [];
  List<Map<String, dynamic>> recentlyViewed = [];

  // 삭제한 항목 보관 (Undo 기능)
  List<Map<String, dynamic>> removedItems = [];

  // 주문 내역 저장 (추가 기능)
  List<Map<String, dynamic>> orderHistory = [];

  double discount = 0.0;
  bool isLoading = false;
  double shippingFee = 3000.0;
  String selectedShipping = "일반 배송 (₩3000)";
  List<String> availableCoupons = ["SAVE10", "FREESHIP", "DISCOUNT5"];
  String sortOption = "none";

  // 추천 상품 예시 (카테고리 포함)
  final List<Map<String, dynamic>> recommendedProducts = [
    {
      'name': '손 소독제',
      'price': 2000,
      'image': 'assets/sanitizer.png',
      'category': '위생'
    },
    {
      'name': '일회용 장갑',
      'price': 500,
      'image': 'assets/gloves.png',
      'category': '보호'
    },
    {
      'name': '소독 티슈',
      'price': 800,
      'image': 'assets/disinfectant.png',
      'category': '위생'
    },
  ];
  String selectedCategory = "전체";

  final ScrollController _scrollController = ScrollController();

  double get totalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])) *
          (1 - discount);
  double get finalPrice =>
      totalPrice >= 50000 ? totalPrice : totalPrice + shippingFee;
  double get discountAmount =>
      cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])) * discount;

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
    removedItems = cartItems.where((item) => item['selected']).toList();
    setState(() {
      cartItems.removeWhere((item) => item['selected']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('선택한 상품이 삭제되었습니다.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              cartItems.addAll(removedItems);
              removedItems.clear();
            });
          },
        ),
      ),
    );
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

  Future<void> processCheckout() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    // 주문 내역 저장 (주문 아이템, 총액, 날짜)
    orderHistory.add({
      'items': List<Map<String, dynamic>>.from(cartItems),
      'total': finalPrice,
      'date': DateTime.now().toString(),
    });
    setState(() {
      isLoading = false;
      cartItems.clear();
    });
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

  // 주문 내역 보기
  void viewOrderHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 내역'),
        content: SizedBox(
          width: double.maxFinite,
          child: orderHistory.isEmpty
              ? const Text('주문 내역이 없습니다.')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: orderHistory.length,
            itemBuilder: (context, index) {
              final order = orderHistory[index];
              return ListTile(
                title: Text('총액: ₩${order['total'].toStringAsFixed(2)}'),
                subtitle: Text('주문일: ${order['date']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
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
        .map((item) => "${item['name']} - ₩${item['price']} x ${item['quantity']}")
        .join("\n");
    // Share.share(cartContent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('장바구니 내용이 공유되었습니다.\n$cartContent')),
    );
  }

  // 장바구니 저장 및 불러오기
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
        'rating': 4.0,
        'note': '',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']}이(가) 추가되었습니다.')),
    );
  }

  // 상품 상세보기 (메모 및 평점 수정 가능)
  void showItemDetails(Map<String, dynamic> item, int index) {
    TextEditingController noteController =
    TextEditingController(text: item['note']);
    double currentRating = item['rating'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('가격: ₩${item['price']}'),
              const SizedBox(height: 8),
              Text('수량: ${item['quantity']}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('평점: '),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: i <= currentRating ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          currentRating = i.toDouble();
                        });
                      },
                    ),
                  Text('$currentRating'),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: '메모를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                cartItems[index]['note'] = noteController.text;
                cartItems[index]['rating'] = currentRating;
              });
              if (!recentlyViewed.contains(item)) {
                setState(() {
                  recentlyViewed.add(item);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // Save for Later: 장바구니에서 삭제 후 savedItems에 추가
  void moveToSaved(int index) {
    setState(() {
      savedItems.add(cartItems[index]);
      cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('나중에 구매할 상품으로 이동되었습니다.')),
    );
  }

  // 저장된 상품 보기 및 복원
  void viewSavedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장된 상품'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: savedItems.length,
            itemBuilder: (context, index) {
              final item = savedItems[index];
              return ListTile(
                leading: Image.asset(item['image'], width: 40, height: 40),
                title: Text(item['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    setState(() {
                      cartItems.add(item);
                      savedItems.removeAt(index);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('상품이 장바구니로 복원되었습니다.')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 전체 장바구니 비우기
  void clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                cartItems.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('전체 상품이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 추천 상품 필터링 (카테고리 선택)
  List<Map<String, dynamic>> get filteredRecommendedProducts {
    if (selectedCategory == "전체") return recommendedProducts;
    return recommendedProducts
        .where((product) => product['category'] == selectedCategory)
        .toList();
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
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: viewSavedItems,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: viewOrderHistory,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "전체 삭제") {
                clearCart();
              } else {
                sortCart(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "가격 낮은 순", child: Text("가격 낮은 순")),
              const PopupMenuItem(value: "가격 높은 순", child: Text("가격 높은 순")),
              const PopupMenuItem(value: "전체 삭제", child: Text("전체 삭제")),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          cartItems.isEmpty
              ? const Center(
            child: Text(
              '장바구니가 비어 있습니다.',
              style: TextStyle(fontSize: 18),
            ),
          )
              : SingleChildScrollView(
            controller: _scrollController,
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
                            title: GestureDetector(
                              onTap: () => showItemDetails(item, index),
                              child: Text(item['name']),
                            ),
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
                                IconButton(
                                  icon: const Icon(Icons.bookmark_border),
                                  onPressed: () => moveToSaved(index),
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
                          const SnackBar(content: Text('삭제할 상품을 선택해주세요.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('선택 삭제'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '총 합계',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₩${finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('결제하기'),
                      ),
                    ],
                  ),
                ),
                // 최근 본 상품 영역
                if (recentlyViewed.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '최근 본 상품',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentlyViewed.length,
                          itemBuilder: (context, index) {
                            final item = recentlyViewed[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(item['image'], width: 60, height: 60),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['name'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                // 추천 상품 카테고리 필터
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: ["전체", "위생", "보호"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredRecommendedProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredRecommendedProducts[index];
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
                                Image.asset(product['image'], width: 60, height: 60),
                                const SizedBox(height: 8),
                                Text(
                                  product['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₩${product['price']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
          // 결제 진행 중 전체 오버레이
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      // Floating Action Button: 최상단으로 스크롤
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}
