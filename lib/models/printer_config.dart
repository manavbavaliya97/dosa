import 'package:hive/hive.dart';

part 'printer_config.g.dart';

@HiveType(typeId: 4)
class PrinterConfig extends HiveObject {
  @HiveField(0)
  String type;

  @HiveField(1)
  String deviceName;

  @HiveField(2)
  String deviceAddress;

  PrinterConfig({
    required this.type,
    required this.deviceName,
    required this.deviceAddress,
  });
}
