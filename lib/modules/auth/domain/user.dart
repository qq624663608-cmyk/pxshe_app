import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.nickname,
    required this.phoneNumber,
    required this.areaCode,
  });

  final String id;
  final String nickname;
  final String phoneNumber;
  final String areaCode;

  static const empty = User(
    id: '',
    nickname: '',
    phoneNumber: '',
    areaCode: '',
  );

  @override
  List<Object> get props => [id, nickname, phoneNumber, areaCode];
}