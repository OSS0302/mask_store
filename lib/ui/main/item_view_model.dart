import 'package:flutter/foundation.dart';
import '../../data/model/item.dart';

class ItemViewModel extends ChangeNotifier {
  final List<Item> _cartItems = [];

  // 장바구니 아이템 읽기 전용 리스트
  List<Item> get cartItems => List.unmodifiable(_cartItems);

  // 총 금액 계산
  double calculateTotal() {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  // 아이템 추가 (중복 처리)
  void addToCart(Item item) {
    var existingItem = _cartItems.firstWhere(
          (i) => i.name == item.name,
      orElse: () => Item(name: '', price: 0),
    );
    if (existingItem.name.isNotEmpty) {
      existingItem.quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  // 아이템 삭제
  void removeFromCart(Item item) {
    _cartItems.removeWhere((i) => i.name == item.name);
    notifyListeners();
  }

  // 수량 증가
  void increaseQuantity(Item item) {
    var targetItem =
    _cartItems.firstWhere((i) => i.name == item.name, orElse: () => item);
    targetItem.quantity++;
    notifyListeners();
  }

  // 수량 감소
  void decreaseQuantity(Item item) {
    var targetItem =
    _cartItems.firstWhere((i) => i.name == item.name, orElse: () => item);
    if (targetItem.quantity > 1) {
      targetItem.quantity--;
    }
    notifyListeners();
  }

  // 장바구니 초기화
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
