import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // The app is offline-first: every screen renders from the local Firestore
  // cache and listeners stream server changes in. Make persistence explicit
  // (it is off by default on web) and stop the LRU garbage collector from
  // evicting a user's older data, which would otherwise force a network
  // round-trip — or an empty screen when offline — to get it back.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  _warmUpFirestore();
  runApp(const MyApp());
}

/// Kicks off the Firestore client's one-time startup (opening the local
/// database, loading its indexes) right now, so it overlaps the splash and
/// auth instead of starting only when the first real listener attaches.
/// The read itself is a throwaway cache lookup and is expected to be empty.
void _warmUpFirestore() {
  unawaited(
    FirebaseFirestore.instance
        .collection('_warmup')
        .limit(1)
        .get(const GetOptions(source: Source.cache))
        .then<void>((_) {}, onError: (Object _) {}),
  );
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

/// Shows the animated splash for [_minSplashDuration] and then fades it out.
///
/// [AuthGate] is built underneath the splash from the very first frame, so
/// auth resolves and every module's Firestore listener starts while the
/// animation plays. By the time the splash lifts, the cached data is
/// already on screen instead of the loading only beginning then.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  static const _minSplashDuration = Duration(milliseconds: 1800);
  static const _fadeDuration = Duration(milliseconds: 500);
  bool _splashVisible = true;
  bool _splashMounted = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (!mounted) return;
      setState(() => _splashVisible = false);
      Future.delayed(_fadeDuration, () {
        if (mounted) setState(() => _splashMounted = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AuthGate(),
        if (_splashMounted)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _splashVisible ? 1 : 0,
              duration: _fadeDuration,
              curve: Curves.easeOut,
              child: const SplashScreen(),
            ),
          ),
      ],
    );
  }
}
