import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/auth/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  static const _accountsKey = 'saved_accounts';

  AuthCubit({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(const AuthState()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadSavedAccounts();
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        savedAccounts: state.savedAccounts,
      ));
    } else {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        savedAccounts: state.savedAccounts,
      ));
    }
  }

  // ── Account persistence ─────────────────────────────────────────────────

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_accountsKey);
    if (data != null) {
      final list = (jsonDecode(data) as List<dynamic>)
          .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(savedAccounts: list));
    }
  }

  Future<void> _persistAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> _saveCurrentAccount(String email, String password) async {
    final accounts = List<SavedAccount>.from(state.savedAccounts);
    accounts.removeWhere((a) => a.email == email);
    accounts.insert(
        0,
        SavedAccount(
          email: email,
          password: password,
          displayName: _auth.currentUser?.displayName,
        ));
    await _persistAccounts(accounts);
    emit(state.copyWith(savedAccounts: accounts));
  }

  Future<void> removeSavedAccount(String email) async {
    final accounts = List<SavedAccount>.from(state.savedAccounts)
      ..removeWhere((a) => a.email == email);
    await _persistAccounts(accounts);
    emit(state.copyWith(savedAccounts: accounts));
  }

  // ── Auth methods ────────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    try {
      emit(state.copyWith(errorMessage: null));
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveCurrentAccount(email, password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(errorMessage: _mapErrorCode(e.code)));
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      emit(state.copyWith(errorMessage: null));
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _saveCurrentAccount(email, password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(errorMessage: _mapErrorCode(e.code)));
    }
  }

  Future<void> switchAccount(SavedAccount account) async {
    try {
      emit(state.copyWith(errorMessage: null));
      await _auth.signOut();
      await _auth.signInWithEmailAndPassword(
          email: account.email, password: account.password);
      // Move switched account to top
      await _saveCurrentAccount(account.email, account.password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(errorMessage: _mapErrorCode(e.code)));
    }
  }

  Future<void> refreshUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed != null) {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: refreshed,
          savedAccounts: state.savedAccounts,
        ));
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Other accounts (not the currently logged in one)
  List<SavedAccount> get otherAccounts {
    final currentEmail = _auth.currentUser?.email;
    return state.savedAccounts
        .where((a) => a.email != currentEmail)
        .toList();
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
