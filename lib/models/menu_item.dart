import 'package:hive/hive.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 1)
class MenuItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String category;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
