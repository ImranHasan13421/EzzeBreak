import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../monitoring/providers/monitoring_providers.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../settings/providers/theme_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _dotsController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineOpacity;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
    _startPreloadAndNavigate();
  }

  void _startPreloadAndNavigate() async {
    final startTime = DateTime.now();

    // Preload database & status
    try {
      final db = ref.read(databaseProvider);
      await db.database; // Ensure DB connection is warm
      await ref.read(monitoredAppsListProvider.notifier).loadApps();
      await ref.read(todayUsageProvider.notifier).refresh();
      await ref.read(permissionsProvider.notifier).checkAll();
    } catch (_) {}

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    const minSplashDurationMs = 1500;
    final remainingDelay = minSplashDurationMs - elapsed;

    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }

    if (!mounted) return;

    setState(() => _isExiting = true);
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final onboardingDone = ref.read(onboardingCompletedProvider);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => onboardingDone
            ? const MainNavigationLayout()
            : OnboardingScreen(
                onFinish: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const MainNavigationLayout(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
              ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg0 : AppColors.lightBg0;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedOpacity(
        opacity: _isExiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                AppColors.brandRed.withValues(alpha: isDark ? 0.04 : 0.03),
                bgColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // App Logo with enter scale + fade
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandRed.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          child: Image.asset(
                            'assets/logo/applogo.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.xl),

                    // Brand title: EZZE BREAK
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleOpacity.value,
                          child: child,
                        );
                      },
                      child: Text(
                        'EZZE BREAK',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.sm),

                    // Tagline
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineOpacity.value,
                          child: child,
                        );
                      },
                      child: Text(
                        'Use mindfully. Move regularly. Feel better.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: secondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // 3 Pulsing loading dots
                    AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final delay = index * 0.25;
                            final val = (_dotsController.value + delay) % 1.0;
                            final pulse = (0.3 + 0.7 * (1.0 - (val - 0.5).abs() * 2)).clamp(0.3, 1.0);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandRed.withValues(alpha: pulse),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
