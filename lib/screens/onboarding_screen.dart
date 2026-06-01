import 'package:flutter/material.dart';
import '../settings/settings_store.dart';
import '../widgets/microlock_logo.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'setup_wizard.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              
              // Logo
              const Center(child: MicrolockLogo(height: 72)),
              const SizedBox(height: AppSpacing.xxl),

              // Title
              Text(
                'Your Smart Home,\nOne Tap Away',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Feature Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _FeatureCard(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.primaryLight,
                      title: 'Smart Lock Control',
                      description: 'Secure and monitor your doors anywhere. Auto-lock ensures your house is always safe.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FeatureCard(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: AppColors.amber,
                      title: 'Smart Lamp Control',
                      description: 'Seamlessly toggle smart lights, check status, and configure custom AP options.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Primary CTA Button
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Device'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                ),
                onPressed: () async {
                  final draft = await Navigator.of(context).push<LockSettings>(
                    MaterialPageRoute(
                      builder: (_) => const SetupWizard(),
                    ),
                  );
                  
                  if (draft != null && context.mounted) {
                    final saved = await store.save(draft);
                    
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => HomeShell(store: store, initialSettings: saved),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppIconSize.lg,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
