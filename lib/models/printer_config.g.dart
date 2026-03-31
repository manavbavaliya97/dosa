// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrinterConfigAdapter extends TypeAdapter<PrinterConfig> {
  @override
  final int typeId = 4;

  @override
  PrinterConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterConfig(
      type: fields[0] as String,
      deviceName: fields[1] as String,
      deviceAddress: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.deviceName)
      ..writeByte(2)
      ..write(obj.deviceAddress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
