import 'package:flutter/material.dart';
import 'package:virtual_shop/utils/expressive_motion.dart';
import 'package:virtual_shop/utils/expressive_shapes.dart';
import 'package:virtual_shop/utils/expressive_typography.dart';

/// Expressive Button Widgets
/// Enhanced buttons with Material 3 Expressive features

class ExpressiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ExpressiveContext context;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final Size? size;

  const ExpressiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.context = ExpressiveContext.smooth,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.size,
  });

  @override
  State<ExpressiveButton> createState() => _ExpressiveButtonState();
}

class _ExpressiveButtonState extends State<ExpressiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ExpressiveMotion.getDurationForContext(widget.context),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ExpressiveMotion.getCurveForContext(widget.context),
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor =
        widget.backgroundColor ??
        (widget.context == ExpressiveContext.hero
            ? colorScheme.primary
            : colorScheme.primaryContainer);

    final effectiveForegroundColor =
        widget.foregroundColor ??
        (widget.context == ExpressiveContext.hero
            ? colorScheme.onPrimary
            : colorScheme.onPrimaryContainer);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size?.width,
            height: widget.size?.height ?? 48,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: ExpressiveShapes.getShapeForContext(
                ShapeContext.button,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveBackgroundColor.withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 12 + (8 * _glowAnimation.value),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: ExpressiveShapes.getShapeForContext(
                  ShapeContext.button,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: effectiveForegroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      else if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: effectiveForegroundColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!widget.isLoading)
                        Text(
                          widget.text,
                          style: ExpressiveTypography.emphasizedLabel(
                            brightness: theme.brightness,
                          ).copyWith(color: effectiveForegroundColor),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Expressive Floating Action Button
class ExpressiveFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ExpressiveContext context;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ExpressiveFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.context = ExpressiveContext.playful,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ExpressiveFAB> createState() => _ExpressiveFABState();
}

class _ExpressiveFABState extends State<ExpressiveFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ExpressiveMotion.getDurationForContext(widget.context),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ExpressiveMotion.getCurveForContext(widget.context),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: _handleTap,
              tooltip: widget.tooltip,
              backgroundColor:
                  widget.backgroundColor ?? colorScheme.primaryContainer,
              foregroundColor:
                  widget.foregroundColor ?? colorScheme.onPrimaryContainer,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: ExpressiveShapes.getShapeForContext(
                  ShapeContext.fab,
                ),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Expressive Card with enhanced interactions
class ExpressiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final ExpressiveContext context;
  final bool useGradient;

  const ExpressiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.context = ExpressiveContext.smooth,
    this.useGradient = false,
  });

  @override
  State<ExpressiveCard> createState() => _ExpressiveCardState();
}

class _ExpressiveCardState extends State<ExpressiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ExpressiveMotion.getDurationForContext(widget.context),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ExpressiveMotion.getCurveForContext(widget.context),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            color: widget.color ?? colorScheme.surfaceContainerHigh,
            elevation: _elevationAnimation.value,
            shape: RoundedRectangleBorder(
              borderRadius: ExpressiveShapes.getShapeForContext(
                ShapeContext.card,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: widget.onTap != null ? _handleTapDown : null,
              onTapUp: widget.onTap != null ? _handleTapUp : null,
              onTapCancel: widget.onTap != null ? _handleTapCancel : null,
              borderRadius: ExpressiveShapes.getShapeForContext(
                ShapeContext.card,
              ),
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Expressive Loading Indicator
class ExpressiveLoadingIndicator extends StatefulWidget {
  final ExpressiveContext context;
  final Color? color;
  final double size;

  const ExpressiveLoadingIndicator({
    super.key,
    this.context = ExpressiveContext.energetic,
    this.color,
    this.size = 32.0,
  });

  @override
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: ExpressiveMotion.getDurationForContext(widget.context),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: ExpressiveMotion.getCurveForContext(widget.context),
      ),
    );

    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _scaleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                color: widget.color ?? colorScheme.primary,
                strokeWidth: 3.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
