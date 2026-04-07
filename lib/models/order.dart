import 'package:hive/hive.dart';
import 'order_line.dart';

part 'order.g.dart';

@HiveType(typeId: 3)
class Order extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<OrderLine> items;

  @HiveField(2)
  double subtotal;

  @HiveField(3)
  double taxPercent;

  @HiveField(4)
  double taxAmount;

  @HiveField(5)
  double discount;

  @HiveField(6)
  double total;

  @HiveField(7)
  DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.createdAt,
  });
}
