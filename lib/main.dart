import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_state.dart';
import 'screens/sign_in.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(SnakeWatchApp(state: AppState()));
}

class SnakeWatchApp extends StatelessWidget {
  final AppState state;
  const SnakeWatchApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Onestop · Snake Watch',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // On a wide browser window, show the app at phone width in the middle.
        builder: (context, child) {
          final w = MediaQuery.sizeOf(context).width;
          if (w <= 560) return child!;
          return ColoredBox(
            color: const Color(0xFF070707),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 430,
                  height: MediaQuery.sizeOf(context).height,
                  child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(430, MediaQuery.sizeOf(context).height)), child: child!),
                ),
              ),
            ),
          );
        },
        home: const SignInScreen(),
      ),
    );
  }
}
