import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class SavedAccount {
  final String email;
  final String password;
  final String? displayName;

  const SavedAccount({
    required this.email,
    required this.password,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'displayName': displayName,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        email: json['email'] as String,
        password: json['password'] as String,
        displayName: json['displayName'] as String?,
      );
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final List<SavedAccount> savedAccounts;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.savedAccounts = const [],
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    List<SavedAccount>? savedAccounts,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      savedAccounts: savedAccounts ?? this.savedAccounts,
    );
  }
}
