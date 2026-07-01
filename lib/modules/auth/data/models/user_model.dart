import 'package:hive_ce/hive.dart';

import '../../domain/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nickname,
    required super.phoneNumber,
    required super.areaCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userID'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      areaCode: json['areaCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userID': id,
        'nickname': nickname,
        'phoneNumber': phoneNumber,
        'areaCode': areaCode,
      };
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  int get typeId => 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String? ?? '',
      nickname: fields[1] as String? ?? '',
      phoneNumber: fields[2] as String? ?? '',
      areaCode: fields[3] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.areaCode);
  }
}