// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppConfigAdapter extends TypeAdapter<AppConfig> {
  @override
  final int typeId = 5;

  @override
  AppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppConfig(
      taxPercent: fields[0] as double,
      restaurantName: fields[1] as String,
      footerMessage: fields[2] as String,
      currencySymbol: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.taxPercent)
      ..writeByte(1)
      ..write(obj.restaurantName)
      ..writeByte(2)
      ..write(obj.footerMessage)
      ..writeByte(3)
      ..write(obj.currencySymbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
