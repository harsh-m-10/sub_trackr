// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 0;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      appName: fields[0] as String,
      planName: fields[1] as String,
      amount: fields[2] as double,
      frequency: fields[3] as String,
      startDate: fields[4] as DateTime,
      category: fields[5] as String,
      reminderDays: (fields[6] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.planName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.reminderDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
