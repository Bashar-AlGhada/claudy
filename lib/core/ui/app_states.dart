import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Empty state with large background icon, title, optional body, and actions.
///
/// Use for screens with no data or content to display.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.lowPower = false,
  });

  /// Primary icon displayed in the background.
  final IconData? icon;

  /// Main title text (medium weight).
  final String title;

  /// Optional subtitle/body text (lighter weight).
  final String? body;

  /// Primary action button label.
  final String? actionLabel;

  /// Primary action callback.
  final VoidCallback? onAction;

  /// Secondary action button label (text style).
  final String? secondaryActionLabel;

  /// Secondary action callback.
  final VoidCallback? onSecondaryAction;

  /// Disables subtle animations when true.
  final bool lowPower;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (icon != null) _BackgroundIcon(icon: icon!, color: iconColor, lowPower: lowPower),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) const SizedBox(height: Tokens.space32),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  if (body != null) ...[
                    const SizedBox(height: Tokens.space8),
                    Text(
                      body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: Tokens.space16),
                    FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                  if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                    const SizedBox(height: Tokens.space8),
                    TextButton(onPressed: onSecondaryAction, child: Text(secondaryActionLabel!)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state with background icon, message, retry button, and optional report action.
class AppErrorState extends StatefulWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.icon,
    this.retryLabel,
    this.onRetry,
    this.reportLabel,
    this.onReport,
    this.lowPower = false,
  });

  /// Error icon displayed in the background.
  final IconData? icon;

  /// Error message to display.
  final String message;

  /// Retry button label.
  final String? retryLabel;

  /// Retry callback; shows loading state while executing.
  final VoidCallback? onRetry;

  /// Optional "Report issue" button label.
  final String? reportLabel;

  /// Report issue callback.
  final VoidCallback? onReport;

  /// Disables subtle animations when true.
  final bool lowPower;

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying || widget.onRetry == null) return;
    setState(() => _isRetrying = true);
    widget.onRetry!();
    // Reset after a brief delay to allow the UI to respond
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isRetrying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.error;
    final effectiveIcon = widget.icon ?? Icons.error_outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _BackgroundIcon(icon: effectiveIcon, color: iconColor, lowPower: widget.lowPower),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: Tokens.space32),
                  Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.retryLabel != null && widget.onRetry != null) ...[
                    const SizedBox(height: Tokens.space16),
                    FilledButton(
                      onPressed: _isRetrying ? null : _handleRetry,
                      child: _isRetrying
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(widget.retryLabel!),
                    ),
                  ],
                  if (widget.reportLabel != null && widget.onReport != null) ...[
                    const SizedBox(height: Tokens.space8),
                    TextButton(onPressed: widget.onReport, child: Text(widget.reportLabel!)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent loading indicator for use across the app.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  /// Optional loading message displayed below the indicator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: Tokens.space16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Large semi-transparent background icon with optional pulse animation.
class _BackgroundIcon extends StatefulWidget {
  const _BackgroundIcon({
    required this.icon,
    required this.color,
    required this.lowPower,
  });

  final IconData icon;
  final Color color;
  final bool lowPower;

  @override
  State<_BackgroundIcon> createState() => _BackgroundIconState();
}

class _BackgroundIconState extends State<_BackgroundIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: Tokens.emptyStateIconOpacity, end: Tokens.emptyStateIconOpacity * 1.5)
            .chain(CurveTween(curve: Tokens.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Tokens.emptyStateIconOpacity * 1.5, end: Tokens.emptyStateIconOpacity)
            .chain(CurveTween(curve: Tokens.easeInOut)),
        weight: 1,
      ),
    ]).animate(_controller);

    if (!widget.lowPower) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_BackgroundIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lowPower && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.lowPower && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowPower) {
      return Icon(
        widget.icon,
        size: Tokens.emptyStateIconSize,
        color: widget.color.withValues(alpha: Tokens.emptyStateIconOpacity),
      );
    }

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) => Icon(
        widget.icon,
        size: Tokens.emptyStateIconSize,
        color: widget.color.withValues(alpha: _opacityAnimation.value),
      ),
    );
  }
}

