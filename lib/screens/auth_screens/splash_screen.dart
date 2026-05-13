import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Local Project Package Imports
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/screens/auth_screens/login_screen.dart';
import 'package:truebpm/utils/global_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _exitController;

  late final Animation<double> _backgroundOpacityAnimation;
  late final Animation<double> _logoOpacityAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _contentOpacityAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  late final Animation<double> _exitOpacityAnimation;
  late final Animation<double> _exitScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
      _initializeApp();
    });
  }

  void _setupAnimations() {
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 680),
      vsync: this,
    );

    _backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.06, 0.62, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.04, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.04, 0.82, curve: Curves.easeOutCubic),
          ),
        );

    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.42, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _exitOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeOut));

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    const minimumDuration = Duration(milliseconds: 1900);
    final stopwatch = Stopwatch()..start();

    try {
      await Future.delayed(const Duration(milliseconds: 650));
      await _waitForMinimumDuration(stopwatch, minimumDuration);
      _exitAndNavigate();
    } catch (e) {
      await _waitForMinimumDuration(stopwatch, minimumDuration);
      _exitAndNavigate();
    }
  }

  Future<void> _waitForMinimumDuration(
    Stopwatch stopwatch,
    Duration minimumDuration,
  ) async {
    final elapsed = stopwatch.elapsed;
    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }
  }

  void _exitAndNavigate() {
    if (!mounted) return;

    _exitController.forward();
    NavigationService.replaceWithSmoothTransition(
      const LoginScreen(fromSplash: true),
      routeName: AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF020A12),
        body: Stack(
          children: [
            _SplashBackground(opacity: _backgroundOpacityAnimation),
            AnimatedBuilder(
              animation: _exitController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1 - _exitOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _exitScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _logoOpacityAnimation,
                        child: SlideTransition(
                          position: _logoSlideAnimation,
                          child: AnimatedBuilder(
                            animation: _logoScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: child,
                              );
                            },
                            child: const _SplashLogoFrame(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _contentOpacityAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Column(
                            children: [
                              Text(
                                appStrings.loginTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appStrings.loginDescription,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.78),
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 42),
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF76D4FF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                appStrings.loading,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.68),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  final Animation<double> opacity;

  const _SplashBackground({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(assets.startBackground, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF03111C).withOpacity(0.82),
                    const Color(0xFF063151).withOpacity(0.68),
                    const Color(0xFF020A12).withOpacity(0.92),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogoFrame extends StatelessWidget {
  const _SplashLogoFrame();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 136,
        height: 136,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.58)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A75BC).withOpacity(0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(assets.appLogo, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
