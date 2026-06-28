import 'dart:convert';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get subtotal => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        imageUrl: json['imageUrl'] as String?,
      );

  String toRawJson() => jsonEncode(toJson());

  factory CartItem.fromRawJson(String raw) =>
      CartItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
