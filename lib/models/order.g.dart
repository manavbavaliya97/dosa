// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 3;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      items: (fields[1] as List).cast<OrderLine>(),
      subtotal: fields[2] as double,
      taxPercent: fields[3] as double,
      taxAmount: fields[4] as double,
      discount: fields[5] as double,
      total: fields[6] as double,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.subtotal)
      ..writeByte(3)
      ..write(obj.taxPercent)
      ..writeByte(4)
      ..write(obj.taxAmount)
      ..writeByte(5)
      ..write(obj.discount)
      ..writeByte(6)
      ..write(obj.total)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
