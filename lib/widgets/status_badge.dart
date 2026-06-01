import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  String get _labelText {
    return switch (status.toLowerCase()) {
      'active' => 'Active',
      'inactive' => 'Inactive',
      'error' => 'Error',
      _ => 'Unknown',
    };
  }

  Color get _color {
    return switch (status.toLowerCase()) {
      'active' => AppColors.connectionActive,
      'inactive' => AppColors.connectionInactive,
      'error' => AppColors.connectionError,
      _ => AppColors.connectionUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _labelText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
