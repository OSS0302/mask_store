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
  List<Map<String, dynamic>> savedItems = [];
  List<Map<String, dynamic>> recentlyViewed = [];
  List<Map<String, dynamic>> removedItems = [];
  List<Map<String, dynamic>> orderHistory = [];

  double discount = 0.0;
  bool isLoading = false;
  double shippingFee = 3000.0;
  bool giftWrap = false;
  final double giftWrapFee = 500.0;
  String selectedShipping = "일반 배송 (₩3000)";
  List<String> availableCoupons = ["SAVE10", "FREESHIP", "DISCOUNT5"];
  String sortOption = "none";

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

  // 검색 기능 관련
  bool isSearching = false;
  String searchQuery = "";

  double get totalPrice => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
  ) * (1 - discount);

  double get finalPrice => totalPrice >= 50000
      ? totalPrice
      : totalPrice + shippingFee + (giftWrap ? giftWrapFee : 0);

  double get discountAmount => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
  ) * discount;

  int get earnedPoints => (finalPrice * 0.01).round();

  List<Map<String, dynamic>> get filteredCartItems {
    if (searchQuery.isEmpty) return cartItems;
    return cartItems
        .where((item) =>
        item['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  // 기본 기능들
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

  void applyBestCoupon() {
    double couponDiscount = 0.0;
    double freeShipBenefit = shippingFee - 3000 > 0 ? shippingFee - 3000 : 3000;
    if (totalPrice * 0.1 > totalPrice * 0.05 &&
        totalPrice * 0.1 > freeShipBenefit) {
      couponDiscount = 0.1;
    } else if (totalPrice * 0.05 > freeShipBenefit) {
      couponDiscount = 0.05;
    }
    setState(() {
      discount = couponDiscount;
      if (couponDiscount == 0.0 && totalPrice >= 30000) {
        shippingFee = 0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('최적 쿠폰이 자동 적용되었습니다!')),
    );
  }

  Future<void> processCheckout() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    orderHistory.add({
      'items': List<Map<String, dynamic>>.from(cartItems),
      'total': finalPrice,
      'earnedPoints': earnedPoints,
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
        content: Text('결제가 완료되었습니다.\n적립 포인트: $earnedPoints point'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

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
            onPressed: () {
              setState(() {
                orderHistory.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('주문 내역이 삭제되었습니다.')),
              );
            },
            child: const Text('전체 주문 삭제', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void requestRestockNotification(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$productName 재입고 알림 신청이 완료되었습니다.')),
    );
  }

  void shareCart() {
    String cartContent = cartItems
        .map((item) =>
    "${item['name']} - ₩${item['price']} x ${item['quantity']}")
        .join("\n");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('장바구니 내용이 공유되었습니다.\n$cartContent')),
    );
  }

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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('상품 리뷰'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('사용자A'),
                            subtitle: Text('훌륭한 제품입니다!'),
                          ),
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('사용자B'),
                            subtitle: Text('가격 대비 만족스럽습니다.'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('닫기'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('리뷰 보기'),
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

  void moveToSaved(int index) {
    setState(() {
      savedItems.add(cartItems[index]);
      cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('나중에 구매할 상품으로 이동되었습니다.')),
    );
  }

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
        title: isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '상품 검색...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        )
            : const Text('장바구니'),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchQuery = "";
              });
            },
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: shareCart),
          IconButton(icon: const Icon(Icons.save), onPressed: saveCart),
          IconButton(icon: const Icon(Icons.folder_open), onPressed: loadCart),
          IconButton(icon: const Icon(Icons.bookmark), onPressed: viewSavedItems),
          IconButton(icon: const Icon(Icons.history), onPressed: viewOrderHistory),
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
                // 장바구니 리스트 (검색 결과 반영)
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredCartItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredCartItems[index];
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
                              onTap: () => showItemDetails(item, cartItems.indexOf(item)),
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
                                  onPressed: () => changeQuantity(cartItems.indexOf(item), -1),
                                ),
                                Text('${item['quantity']}',
                                    style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => changeQuantity(cartItems.indexOf(item), 1),
                                ),
                                IconButton(
                                  icon: Icon(
                                    item['wishlist']
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: item['wishlist'] ? Colors.red : null,
                                  ),
                                  onPressed: () => toggleWishlist(cartItems.indexOf(item)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bookmark_border),
                                  onPressed: () => moveToSaved(cartItems.indexOf(item)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                            '선물 포장 (추가 ₩500)',
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: giftWrap,
                            onChanged: (value) {
                              setState(() {
                                giftWrap = value;
                              });
                            },
                          ),
                        ],
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
                      Text('예상 적립 포인트: $earnedPoints point'),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: '프로모션 코드를 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => applyDiscount(value),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: applyBestCoupon,
                        child: const Text('최적 쿠폰 자동 적용'),
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
                if (recentlyViewed.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
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
