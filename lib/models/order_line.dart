import 'package:hive/hive.dart';

part 'order_line.g.dart';

@HiveType(typeId: 2)
class OrderLine extends HiveObject {
  @HiveField(0)
  String itemId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double total;

  OrderLine({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
  });

  OrderLine copyWith({
    String? itemId,
    String? name,
    double? price,
    int? quantity,
    double? total,
  }) {
    return OrderLine(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
