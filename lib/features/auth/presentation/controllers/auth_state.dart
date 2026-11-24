import 'package:equatable/equatable.dart';
import '../../data/models/auth_model.dart';

enum AuthStatus { initial, checking, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final bool isLoading;
  final Personal? personal;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.personal,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    Personal? personal,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      personal: personal ?? this.personal,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, personal, errorMessage];
}
