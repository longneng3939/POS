class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.category = '',
    required this.price,
    required this.stock,
    this.barcode,
    this.imageUrl,
    this.isActive = true,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? barcode,
    String? imageUrl,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        barcode: json['barcode'] as String?,
        imageUrl: json['imageUrl'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );
}
