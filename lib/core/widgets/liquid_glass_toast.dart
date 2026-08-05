import 'dart:ui';

import 'package:flutter/material.dart';

/// Semantic type of a [LiquidGlassToast], driving its accent color and icon.
enum ToastType { success, error, info, warning }

/// Where a [LiquidGlassToast] is anchored on screen.
enum ToastPosition { top, bottom }

extension _ToastTypeStyle on ToastType {
  Color get color {
    switch (this) {
      case ToastType.success:
        return const Color(0xFF34D399);
      case ToastType.error:
        return const Color(0xFFF87171);
      case ToastType.warning:
        return const Color(0xFFFBBF24);
      case ToastType.info:
        return const Color(0xFF60A5FA);
    }
  }

  IconData get icon {
    switch (this) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }
}

/// A reusable "liquid glass" style toast, presented as a floating top
/// overlay (in the style of iOS system toasts / Dynamic Island banners).
///
/// Callable from anywhere with a [BuildContext] — no BLoC dependency, so it
/// works fine from inside a `BlocListener` callback.
class LiquidGlassToast {
  LiquidGlassToast._();

  static OverlayEntry? _currentEntry;
  static _LiquidGlassToastCardState? _currentState;

  static const _minDuration = Duration(seconds: 2);
  static const _maxDuration = Duration(seconds: 7);
  static const _baseDuration = Duration(seconds: 2);

  /// ~200 words per minute reading speed → ~65ms per character.
  static const _perCharacter = Duration(milliseconds: 65);

  /// Estimates a readable display duration from [message]'s length,
  /// clamped between [_minDuration] and [_maxDuration].
  static Duration _durationFor(String message) {
    final estimated = _baseDuration + _perCharacter * message.length;
    if (estimated < _minDuration) return _minDuration;
    if (estimated > _maxDuration) return _maxDuration;
    return estimated;
  }

  /// Shows a toast over everything currently on screen.
  ///
  /// If a toast is already visible, it is dismissed immediately and replaced
  /// by the new one.
  ///
  /// [duration] defaults to an estimate based on [message]'s length (longer
  /// messages stay on screen longer), clamped between [_minDuration] and
  /// [_maxDuration]. Pass an explicit [duration] to override this.
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    double bottomOffset = 0,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    // Replace any toast that's already showing.
    _currentState?.dismiss();
    _currentEntry?.remove();
    _currentEntry = null;

    final safePadding = MediaQuery.of(context).padding;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _LiquidGlassToastCard(
          message: message,
          type: type,
          position: position,
          duration: duration ?? _durationFor(message),
          topInset: safePadding.top,
          bottomInset: safePadding.bottom + bottomOffset,
          onStateCreated: (state) => _currentState = state,
          onDismissed: () {
            entry.remove();
            if (_currentEntry == entry) {
              _currentEntry = null;
              _currentState = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _LiquidGlassToastCard extends StatefulWidget {
  const _LiquidGlassToastCard({
    required this.message,
    required this.type,
    required this.position,
    required this.duration,
    required this.topInset,
    required this.bottomInset,
    required this.onStateCreated,
    required this.onDismissed,
  });

  final String message;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final double topInset;
  final double bottomInset;
  final ValueChanged<_LiquidGlassToastCardState> onStateCreated;
  final VoidCallback onDismissed;

  @override
  State<_LiquidGlassToastCard> createState() => _LiquidGlassToastCardState();
}

class _LiquidGlassToastCardState extends State<_LiquidGlassToastCard>
    with SingleTickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 550);
  static const _exitDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;

  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _iconScale;
  late final Animation<double> _glow;

  double _dragExtent = 0;
  bool _dragging = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _entranceDuration,
      reverseDuration: _exitDuration,
    );

    final fromBottom = widget.position == ToastPosition.bottom;
    _slide =
        Tween<Offset>(
          begin: Offset(0, fromBottom ? 1 : -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    // Deliberately NOT easeOutBack: that curve overshoots past 1.0, and
    // since this scales the whole card (glass tint, border, shadow
    // together) the overshoot reads as the card flashing brighter/bigger
    // before settling down. easeOutCubic reaches 1.0 and stops there.
    //
    // The range is kept narrow (0.96–1.0, not 0.85–1.0): BackdropFilter's
    // blur sigma is fixed in pixels, so scaling the card also scales how
    // strong that blur reads visually — a wide range made the glass look
    // like it blurred harder at the start of the entrance. A narrow range
    // keeps that shift small enough to be imperceptible while still giving
    // a soft "settle" feel.
    _scale = Tween<double>(begin:0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    // The glow tracks the FULL animation span (no Interval cutoff) so it
    // reaches full strength exactly when the card finishes settling —
    // never before, which is what read as a premature flash/fade.
    _glow = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Icon "pop": starts a beat after the card begins settling, then
    // overshoots slightly past 1.0 before resting.
    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutBack),
        reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    widget.onStateCreated(this);

    _controller.forward();
    _scheduleAutoDismiss();
  }

  void _scheduleAutoDismiss() {
    Future.delayed(widget.duration, () {
      if (mounted && !_dismissed && !_dragging) {
        dismiss();
      }
    });
  }

  Future<void> dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await _controller.reverse();
    widget.onDismissed();
  }

  /// +1 for a top toast (dismiss swipe is upward, i.e. negative dy), -1 for
  /// a bottom toast (dismiss swipe is downward, i.e. positive dy).
  double get _dismissDirection => widget.position == ToastPosition.top ? 1 : -1;

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.delta.dy * _dismissDirection;
    if (delta >= 0) return;
    setState(() {
      _dragExtent += delta;
      _dragging = true;
      final progress = (1 + _dragExtent / 100).clamp(0.0, 1.0);
      _controller.value = progress;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    const dismissThreshold = -40.0;
    final velocity = (details.primaryVelocity ?? 0) * _dismissDirection;
    final flung = velocity < -300;

    if (_dragExtent < dismissThreshold || flung) {
      dismiss();
    } else {
      _controller.forward();
      _dragExtent = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.type.color;
    final isTop = widget.position == ToastPosition.top;

    return Positioned(
      top: isTop ? widget.topInset + 16 : null,
      bottom: isTop ? null : widget.bottomInset + 28,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fade.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, _slide.value.dy * 60),
                  child: Transform.scale(
                    scale: _scale.value,
                    alignment: isTop
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              );
            },
            child: _GlassCard(
              message: widget.message,
              accentColor: accentColor,
              icon: widget.type.icon,
              iconScale: _iconScale,
              glowStrength: _glow,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.message,
    required this.accentColor,
    required this.icon,
    required this.iconScale,
    required this.glowStrength,
  });

  final String message;
  final Color accentColor;
  final IconData icon;
  final Animation<double> iconScale;

  /// Drives the shadow opacities in lockstep with the card's own fade, so
  /// the colored glow eases in with everything else instead of snapping to
  /// full strength on the very first frame.
  final Animation<double> glowStrength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowStrength,
      builder: (context, child) {
        final strength = glowStrength.value.clamp(0.0, 1.0);
        return Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3 * strength),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25 * strength),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Stack(
            children: [
              // Base glass tint — kept light so the blurred background
              // actually shows through (a heavier tint just looks like a
              // frosted-white card, not glass over real content).
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.01),
                  ),
                ),
              ),
              // Diagonal sheen: a soft light pass across the glass to
              // suggest refraction rather than a flat tint. Kept subtle —
              // a brighter sheen reads as a flash while the card is still
              // fading in, since it's a much larger fraction of the still-low
              // overall opacity than it is once the card is fully visible.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Full specular border wrapping the glass edge.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: iconScale,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(icon, color: accentColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
