import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'status_badge.dart';

class HeroStatusCard extends StatelessWidget {
  const HeroStatusCard({
    super.key,
    required this.isLamp,
    required this.stateText,
    required this.isActive,
    required this.deviceName,
    required this.connectionStatus,
    required this.busy,
    required this.lastUpdated,
    required this.countdownRemaining,
  });

  final bool isLamp;
  final String stateText;
  final bool isActive;
  final String deviceName;
  final String connectionStatus;
  final bool busy;
  final String? lastUpdated;
  final int countdownRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Determine state colors and icons
    final Color stateColor;
    final IconData iconData;

    if (isLamp) {
      stateColor = isActive ? AppColors.lampOn : AppColors.textMuted;
      iconData = isActive ? Icons.lightbulb : Icons.lightbulb_outline;
    } else {
      stateColor = isActive ? AppColors.unlocked : AppColors.locked;
      iconData = isActive ? Icons.lock_open_rounded : Icons.lock_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.heroCardBorder,
        side: BorderSide(
          color: stateColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.heroCardBorder,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              stateColor.withValues(alpha: 0.08),
              AppColors.surfaceContainerDark.withValues(alpha: 0.8),
            ],
          ),
        ),
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            // Hero Icon
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Animation Background when Active
                if (isActive)
                  _PulseRing(color: stateColor),
                AnimatedContainer(
                  duration: AppDurations.normal,
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: stateColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppDurations.normal,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        iconData,
                        key: ValueKey('${isLamp}_$isActive'),
                        size: AppIconSize.hero,
                        color: stateColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // State Title
            Text(
              stateText.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Outfit',
                color: stateColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Device Name
            Text(
              deviceName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Connection status and updated timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(status: connectionStatus),
                if (lastUpdated != null && lastUpdated!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Updated $lastUpdated',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            // Linear Progress Indicator for busy state
            if (busy) ...[
              const SizedBox(height: AppSpacing.xl),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                child: SizedBox(
                  width: 120,
                  height: 3,
                  child: LinearProgressIndicator(),
                ),
              ),
            ],

            // Auto-lock Countdown
            if (!isLamp && countdownRemaining > 0) ...[
              const SizedBox(height: AppSpacing.xl),
                Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: AppIconSize.sm,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Auto-lock in ${countdownRemaining}s',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.pillBorder,
                      child: LinearProgressIndicator(
                        value: countdownRemaining / 5.0,
                        backgroundColor: AppColors.outlineVariant,
                        color: AppColors.amber,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color});
  final Color color;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 140 * _animation.value,
          height: 140 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(
                alpha: (1.0 - (_animation.value - 1.0) / 0.35).clamp(0.0, 0.4),
              ),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
