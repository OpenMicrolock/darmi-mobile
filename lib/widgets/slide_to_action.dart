import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SlideToAction extends StatefulWidget {
  const SlideToAction({
    super.key,
    required this.onCompleted,
    this.text = 'Slide to unlock',
    this.completedText = 'Unlocking...',
    this.icon = Icons.arrow_forward_rounded,
    this.color = AppColors.primary,
  });

  final VoidCallback onCompleted;
  final String text;
  final String completedText;
  final IconData icon;
  final Color color;

  @override
  State<SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDragWidth) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx)
          .clamp(0.0, maxDragWidth);
    });
  }

  void _onDragEnd(double maxDragWidth) {
    if (_isCompleted) return;
    
    // Threshold to unlock: 85% of total width
    if (_dragPosition >= maxDragWidth * 0.85) {
      setState(() {
        _dragPosition = maxDragWidth;
        _isCompleted = true;
      });
      widget.onCompleted();
      
      // Reset after a short delay to allow another action in the future
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _dragPosition = 0.0;
            _isCompleted = false;
          });
        }
      });
    } else {
      // Snap back to start
      _animController.forward(from: 0.0);
      final double startPosition = _dragPosition;
      _animController.addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = startPosition * (1.0 - _animController.value);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double widgetHeight = 56.0;
    const double padding = 4.0;
    const double thumbSize = widgetHeight - (padding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragWidth = constraints.maxWidth - thumbSize - (padding * 2);

        return Container(
          height: widgetHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerDark,
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: AppColors.outlineVariant,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Sliding background track (active color reveal)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: _dragPosition + thumbSize + (padding * 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),

              // Track Text Overlay
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragPosition / maxDragWidth * 1.5)).clamp(0.0, 1.0),
                  child: Text(
                    _isCompleted ? widget.completedText : widget.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Draggable Thumb
              Positioned(
                left: padding + _dragPosition,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxDragWidth),
                  onHorizontalDragEnd: (_) => _onDragEnd(maxDragWidth),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCompleted ? Icons.check_rounded : widget.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
