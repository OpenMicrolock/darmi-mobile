import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DeviceAvatar extends StatelessWidget {
  const DeviceAvatar({
    super.key,
    required this.deviceType,
    this.size = 40,
    this.isActive = false,
  });

  final String deviceType;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isLamp = deviceType == 'lamp';
    final IconData iconData;
    final Color iconColor;
    final Color backgroundColor;

    if (isLamp) {
      iconData = isActive ? Icons.lightbulb : Icons.lightbulb_outline;
      iconColor = isActive ? AppColors.lampOn : AppColors.textSecondary;
      backgroundColor = isActive 
          ? AppColors.amber.withValues(alpha: 0.15)
          : AppColors.surfaceContainerHighDark;
    } else {
      iconData = isActive ? Icons.lock_open : Icons.lock;
      iconColor = isActive ? AppColors.unlockedLight : AppColors.primaryLight;
      backgroundColor = isActive 
          ? AppColors.unlocked.withValues(alpha: 0.15)
          : AppColors.primary.withValues(alpha: 0.15);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive 
              ? iconColor.withValues(alpha: 0.5) 
              : AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Icon(
        iconData,
        size: size * 0.55,
        color: iconColor,
      ),
    );
  }
}
