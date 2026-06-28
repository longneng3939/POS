import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';

class CartBottomSheet extends StatefulWidget {
  final CartService cartService;
  final VoidCallback onCheckout;

  const CartBottomSheet({
    super.key,
    required this.cartService,
    required this.onCheckout,
  });

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  late Future<List<CartItem>> _itemsFuture;
  final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.cartService.getItems();
  }

  void _refresh() {
    setState(() {
      _itemsFuture = widget.cartService.getItems();
    });
  }

  Future<void> _updateQty(String productId, int qty) async {
    await widget.cartService.updateQuantity(productId, qty);
    _refresh();
  }

  Future<void> _remove(String productId) async {
    await widget.cartService.removeItem(productId);
    _refresh();
  }

  Future<void> _clear() async {
    await widget.cartService.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Your Cart',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items list
            Expanded(
              child: FutureBuilder<List<CartItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Your cart is empty', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCartItemTile(item);
                    },
                  );
                },
              ),
            ),
            // Footer with total and checkout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SafeArea(
                child: FutureBuilder<List<CartItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    final total = items.fold<double>(0, (s, i) => s + i.subtotal);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total (${items.fold<int>(0, (s, i) => s + i.quantity)} items)',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              _currency.format(total),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: items.isEmpty ? null : widget.onCheckout,
                            child: const Text('Checkout'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl!, fit: BoxFit.cover),
              )
            : const Icon(Icons.image_outlined, color: Colors.grey),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _currency.format(item.price),
        style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
      ),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _qtyButton(Icons.remove, () => _updateQty(item.productId, item.quantity - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            _qtyButton(Icons.add, () => _updateQty(item.productId, item.quantity + 1)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _remove(item.productId),
              child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.lightRed,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primaryRed),
      ),
    );
  }
}
