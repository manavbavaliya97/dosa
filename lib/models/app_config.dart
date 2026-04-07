import 'package:hive/hive.dart';

part 'app_config.g.dart';

@HiveType(typeId: 5)
class AppConfig extends HiveObject {
  @HiveField(0)
  double taxPercent;

  @HiveField(1)
  String restaurantName;

  @HiveField(2)
  String footerMessage;

  @HiveField(3)
  String currencySymbol;

  AppConfig({
    this.taxPercent = 5.0,
    this.restaurantName = 'Malhar Dosa',
    this.footerMessage = 'Thank you for visiting!',
    this.currencySymbol = '₹',
  });
}
