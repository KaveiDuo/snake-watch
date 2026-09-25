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
        home: const SignInScreen(),
      ),
    );
  }
}
