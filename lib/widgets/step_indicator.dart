import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? 20.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillBorder,
            color: isActive
                ? AppColors.primaryLight
                : (isCompleted
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.outline),
            border: isActive
                ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1)
                : null,
          ),
        );
      }),
    );
  }
}
