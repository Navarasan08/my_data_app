import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/auth/auth_gate.dart';
import 'package:my_data_app/src/splash/splash_screen.dart';
import 'package:my_data_app/src/theme/app_theme.dart';
import 'package:my_data_app/src/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'GLORIA - MY RECORD KEEPER',
            themeMode: themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const _SplashGate(),
          );
        },
      ),
    );
  }
}

/// Shows the animated splash for [_minSplashDuration], then crossfades to
/// [AuthGate]. Firebase is already initialized at this point (see main()),
/// so this is purely a presentational delay to let the splash animation
/// play out.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  static const _minSplashDuration = Duration(milliseconds: 1800);
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : const AuthGate(key: ValueKey('gate')),
    );
  }
}
