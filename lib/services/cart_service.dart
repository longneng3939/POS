import '../models/cart_item.dart';

/// In-memory cart service for the current POS session.
///
/// The cart is intentionally transient. Completed sales are persisted as
/// [PosTransaction] rows in Drift and synced to Firestore via [SyncService].
class CartService {
  final List<CartItem> _items = [];

  Future<void> init() async {
    _items.clear();
  }

  Future<List<CartItem>> getItems() async => List.unmodifiable(_items);

  Future<void> addItem(CartItem item) async {
    final index = _items.indexWhere((i) => i.productId == item.productId);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      _items.removeWhere((i) => i.productId == productId);
    } else {
      final index = _items.indexWhere((i) => i.productId == productId);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
    }
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((i) => i.productId == productId);
  }

  Future<void> clear() async {
    _items.clear();
  }

  Future<int> getItemCount() async {
    return _items.fold<int>(0, (sum, i) => sum + i.quantity);
  }

  Future<double> getTotal() async {
    return _items.fold<double>(0, (sum, i) => sum + i.subtotal);
  }

  Future<void> dispose() async {
    _items.clear();
  }
}
