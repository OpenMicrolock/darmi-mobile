import 'package:flutter/material.dart';
import '../settings/settings_store.dart';
import '../widgets/microlock_logo.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'onboarding_screen.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.store});

  final SettingsStore store;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _checkDeviceAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkDeviceAndNavigate() async {
    // Force a minimum of 1.5s splash screen time
    final stopwatch = Stopwatch()..start();
    
    final activeDevice = await widget.store.load();
    
    final elapsedMs = stopwatch.elapsedMilliseconds;
    const minSplashDuration = 1500;
    if (elapsedMs < minSplashDuration) {
      await Future.delayed(Duration(milliseconds: minSplashDuration - elapsedMs));
    }

    if (!mounted) return;

    if (activeDevice == null || !activeDevice.isComplete) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: AppDurations.normal,
          pageBuilder: (_, __, ___) => OnboardingScreen(store: widget.store),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: AppDurations.normal,
          pageBuilder: (_, __, ___) => HomeShell(
            store: widget.store,
            initialSettings: activeDevice,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MicrolockLogo(height: 100),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Smart IoT Hub',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Outfit',
                        color: AppColors.textSecondary,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.huge),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
