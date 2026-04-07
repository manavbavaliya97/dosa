// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_line.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderLineAdapter extends TypeAdapter<OrderLine> {
  @override
  final int typeId = 2;

  @override
  OrderLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderLine(
      itemId: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      quantity: fields[3] as int,
      total: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, OrderLine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
