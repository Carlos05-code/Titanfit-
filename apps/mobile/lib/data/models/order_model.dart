import 'product_model.dart';
import 'service_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<ProductModel> products;
  final List<ServiceModel> services;
  final double total;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.products,
    required this.services,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      products: (json['products'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'products': products.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'total': total,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
