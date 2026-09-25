import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../theme.dart';
import 'authority_sign_in.dart';
import 'home_shell.dart';

/// Onestop-style gradient background (matches welcome_header.dart in the Onestop app).
class OnestopBackground extends StatelessWidget {
  final Widget child;
  const OnestopBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [C.onestopGreen, C.onestopMint],
              ),
            ),
            // Fills the screen on normal phones and scrolls on very short ones.
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnestopBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 64),
          Hero(tag: 'logo', child: Image.asset('assets/images/app_logo_dark.png', width: 80, height: 80)),
          const SizedBox(height: 24),
          Text('Welcome to the\nall new Onestop', textAlign: TextAlign.center, style: geist(38, height: 1, ls: -1.5)),
          const Spacer(),
          Text(
            'All the features you use every day, now thoughtfully redesigned.',
            textAlign: TextAlign.center,
            style: geist(16, color: C.onestopInk.withValues(alpha: 0.8), ls: -0.76),
          ),
          const SizedBox(height: 25),
          _OnestopButton(
            color: C.onestopGreen,
            onTap: () => Navigator.of(context).pushReplacement(_fade(const AuthenticatingScreen(), 450)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Sign in with Outlook', style: mont(16)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ]),
          ),
          const SizedBox(height: 8),
          Text('For students and faculty with an @iitg.ac.in ID', style: geist(12, color: C.onestopInk.withValues(alpha: 0.6), ls: -0.2)),
          const SizedBox(height: 14),
          _OnestopButton(
            color: Colors.white,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthorityPhoneScreen())),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.badge_outlined, color: C.onestopGreen, size: 18),
              const SizedBox(width: 8),
              Text('Hostel authority sign-in', style: mont(14, color: C.onestopInk)),
            ]),
          ),
          const SizedBox(height: 15),
          Image.asset('assets/images/swc.png', height: 32),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _OnestopButton extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final BorderSide? side;
  const _OnestopButton({required this.color, required this.child, required this.onTap, this.side});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: side ?? BorderSide.none),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: child),
        ),
      );
}

PageRouteBuilder<T> _fade<T>(Widget page, int ms) => PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: ms),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut), child: c),
    );

/// Simulated Outlook sign-in: "Authenticating" types in (~0.6 s), then Home fades in.
class AuthenticatingScreen extends StatefulWidget {
  const AuthenticatingScreen({super.key});
  @override
  State<AuthenticatingScreen> createState() => _AuthenticatingScreenState();
}

class _AuthenticatingScreenState extends State<AuthenticatingScreen> with TickerProviderStateMixin {
  static const word = 'Authenticating';
  late final AnimationController _type = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  late final Timer _dots;
  int _dotCount = 0;
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _dots = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_type.isCompleted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });
    _go();
  }

  void _go() {
    _done?.cancel();
    _done = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      AppScope.read(context).setRole(Role.student);
      Navigator.of(context).pushReplacement(_fade(const HomeShell(), 600));
    });
  }

  @override
  void dispose() {
    _type.dispose();
    _pulse.dispose();
    _dots.cancel();
    _done?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnestopBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 64),
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Hero(tag: 'logo', child: Image.asset('assets/images/app_logo_dark.png', width: 80, height: 80)),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _type,
            builder: (_, _) {
              final n = (word.length * _type.value).round();
              return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 26),
                Text.rich(TextSpan(children: [
                  TextSpan(text: word.substring(0, n)),
                  TextSpan(text: word.substring(n), style: const TextStyle(color: Colors.transparent)),
                ]), style: geist(30, height: 1, ls: -1.5)),
                SizedBox(width: 26, child: Text('.' * _dotCount, style: geist(30, height: 1, ls: -1.5))),
              ]);
            },
          ),
          const Spacer(),
          const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: C.onestopGreen, strokeWidth: 4)),
          const SizedBox(height: 40),
          Text('Complete the login in your browser.', style: geist(16, color: C.onestopInk.withValues(alpha: 0.8), ls: -0.76)),
          const SizedBox(height: 24),
          _OnestopButton(
            color: Colors.white,
            side: const BorderSide(color: C.onestopGreen),
            onTap: _go,
            child: Center(child: Text('Reinitialize', style: mont(16, color: C.onestopGreen))),
          ),
          const SizedBox(height: 15),
          Image.asset('assets/images/swc.png', height: 32),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
