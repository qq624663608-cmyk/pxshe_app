part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppLoaded extends AuthEvent {}

class AuthStatusSubscriptionRequested extends AuthEvent {
  const AuthStatusSubscriptionRequested();
}

class AuthLoginSucceeded extends AuthEvent {
  const AuthLoginSucceeded();
}

class AuthLogoutRequested extends AuthEvent {}
