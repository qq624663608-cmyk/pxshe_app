import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../_core/logger.dart';
import '../../../modules/im/im_module.dart';
import '../domain/auth_usecases.dart';
import '../domain/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthUsecases userUsecase})
      : _userUsecase = userUsecase,
        super(const AuthState()) {
    on<AppLoaded>(_appLoaded);
    on<AuthStatusSubscriptionRequested>(_onAuthSubscriptionRequested);
    on<AuthLoginSucceeded>(_onAuthLoginSucceeded);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  final AuthUsecases _userUsecase;

  @override
  Future<void> close() {
    _userUsecase.dispose();
    return super.close();
  }

  Future<void> _appLoaded(AppLoaded event, Emitter<AuthState> emit) async {
    final cached = await _userUsecase.loadCachedSession();
    if (cached == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } else {
      emit(state.copyWith(status: AuthStatus.authenticated, user: cached));
      // Bootstrap IM after a successful session restore. Failures are
      // logged but never block the auth state — the user can still use
      // the app without IM until they retry.
      unawaited(_bootstrapIM().catchError((Object e, StackTrace _) {
        Log.w('AuthBloc: IM bootstrap failed on cold start: $e');
      }));
    }
  }

  Future<void> _bootstrapIM() => bootstrapIMAfterLogin();

  Future<void> _onAuthSubscriptionRequested(
    AuthStatusSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach<User>(
      _userUsecase.userStream,
      onData: (user) {
        if (user == User.empty) {
          return state.copyWith(
            status: AuthStatus.unauthenticated,
            user: user,
          );
        }
        return state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _userUsecase.logout();
    unawaited(bootstrapIMAfterLogout().catchError((Object e, StackTrace _) {
      Log.w('AuthBloc: IM logout failed: $e');
    }));
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: User.empty));
  }

  Future<void> _onAuthLoginSucceeded(
    AuthLoginSucceeded event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticated, user: User.empty));
  }
}