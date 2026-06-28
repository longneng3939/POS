import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_sheet.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  late List<Product> _allProducts;
  List<Product> _filteredProducts = [];
  bool _isSearching = false;
  int _cartBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _allProducts = _generateMockProducts();
    _filteredProducts = List.from(_allProducts);
    _initCart();
  }

  Future<void> _initCart() async {
    await _cartService.init();
    _updateBadge();
  }

  Future<void> _updateBadge() async {
    final count = await _cartService.getItemCount();
    setState(() => _cartBadgeCount = count);
  }

  List<Product> _generateMockProducts() {
    return [
      Product(id: '1', name: 'Wireless Headphones', category: 'Electronics', price: 59.99, stock: 12, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Headphones'),
      Product(id: '2', name: 'USB-C Cable 2m', category: 'Accessories', price: 9.99, stock: 45, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=USB-C'),
      Product(id: '3', name: 'Phone Case Black', category: 'Accessories', price: 14.99, stock: 0, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Case'),
      Product(id: '4', name: 'Bluetooth Speaker', category: 'Electronics', price: 34.99, stock: 8, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Speaker'),
      Product(id: '5', name: 'Power Bank 20000mAh', category: 'Electronics', price: 29.99, stock: 20, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=PowerBank'),
      Product(id: '6', name: 'Laptop Stand Aluminum', category: 'Office', price: 24.99, stock: 15, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Stand'),
      Product(id: '7', name: 'Mechanical Keyboard', category: 'Office', price: 89.99, stock: 5, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Keyboard'),
      Product(id: '8', name: 'Wireless Mouse', category: 'Office', price: 19.99, stock: 30, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Mouse'),
      Product(id: '9', name: 'Webcam HD 1080p', category: 'Electronics', price: 49.99, stock: 7, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Webcam'),
      Product(id: '10', name: 'Desk Lamp LED', category: 'Office', price: 22.99, stock: 18, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Lamp'),
      Product(id: '11', name: 'Monitor 27" 4K', category: 'Electronics', price: 329.99, stock: 3, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=Monitor'),
      Product(id: '12', name: 'HDMI Cable 3m', category: 'Accessories', price: 7.99, stock: 50, imageUrl: 'https://placehold.jp/30/d32f2f/ffffff/300x300.png?text=HDMI'),
    ];
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts.where((p) {
          return p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _addToCart(Product product) async {
    final item = CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
      imageUrl: product.imageUrl,
    );
    await _cartService.addItem(item);
    _updateBadge();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          backgroundColor: AppTheme.darkRed,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartBottomSheet(
        cartService: _cartService,
        onCheckout: () {
          Navigator.pop(context);
          // TODO: Navigate to checkout screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checkout coming soon...')),
          );
        },
      ),
    ).then((_) => _updateBadge());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearch,
              )
            : const Text('K-POS'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _filteredProducts = List.from(_allProducts);
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _openCart,
              ),
              if (_cartBadgeCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_cartBadgeCount',
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', true),
                _buildCategoryChip('Electronics', false),
                _buildCategoryChip('Accessories', false),
                _buildCategoryChip('Office', false),
              ],
            ),
          ),
          // Product grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _addToCart(product),
                        onAddToCart: () => _addToCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _cartBadgeCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart ($_cartBadgeCount)'),
            )
          : null,
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          // TODO: Filter by category
        },
      ),
    );
  }
}
