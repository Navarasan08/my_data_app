import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/auth/cubit/auth_state.dart';
import 'package:my_data_app/src/auth/login_screen.dart';
import 'package:my_data_app/src/auth/authenticated_shell.dart';
import 'package:my_data_app/src/splash/branded_loader.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const BrandedLoader(message: 'Just a moment…');
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return AuthenticatedShell(uid: state.user!.uid);
        }
      },
    );
  }
}
