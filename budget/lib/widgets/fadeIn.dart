import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/functions.dart';

class FadeIn extends StatefulWidget {
  FadeIn({Key? key, required this.child, this.duration}) : super(key: key);

  final Widget child;
  final Duration? duration;

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? Duration(milliseconds: 500),
      vsync: this,
    );

    if (!appStateSettings["batterySaver"]) {
      _controller.forward();
    }

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appStateSettings["batterySaver"]) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ScaleIn extends StatefulWidget {
  ScaleIn({
    Key? key,
    required this.child,
    this.duration,
    this.curve = const ElasticOutCurve(0.5),
    this.delay = Duration.zero,
    this.loopDelay = Duration.zero,
    this.loop = false,
  }) : super(key: key);

  final Widget child;
  final Duration? duration;
  final Curve curve;
  final Duration delay;
  final Duration loopDelay;
  final loop;

  @override
  _ScaleInState createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (!appStateSettings["batterySaver"]) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          // Check if the widget is still mounted
          _controller.forward();
        }
      });
    }

    if (widget.loop)
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(widget.loopDelay, () {
            if (mounted) {
              _controller.reverse();
            }
          });
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appStateSettings["batterySaver"]) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ScalingWidget extends StatefulWidget {
  final String keyToWatch;
  final Widget child;

  ScalingWidget({required this.keyToWatch, required this.child});

  @override
  _ScalingWidgetState createState() => _ScalingWidgetState();
}

class _ScalingWidgetState extends State<ScalingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;
  String _currentKey = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ScalingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyToWatch != _currentKey && !_isAnimating) {
      _currentKey = widget.keyToWatch;
      _isAnimating = true;
      _controller.forward().then((value) {
        _controller.reverse().then((value) {
          _isAnimating = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _isAnimating ? _scaleAnimation.value : 1.0,
          child: widget.child,
        );
      },
    );
  }
}

class ScaledAnimatedSwitcher extends StatelessWidget {
  const ScaledAnimatedSwitcher({
    required this.keyToWatch,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    Key? key,
  }) : super(key: key);

  final String keyToWatch;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(0.5, 1),
          ),
        );

        final scaleAnimation = Tween<double>(begin: 0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(0, 1.0),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            alignment: Alignment.center,
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: SizedBox(key: ValueKey(keyToWatch), child: child),
    );
  }
}

enum Direction { vertical, horizontal }

class SlideFadeTransition extends StatefulWidget {
  SlideFadeTransition({
    required this.child,
    this.offset = 1,
    this.curve = Curves.decelerate,
    this.direction = Direction.vertical,
    this.delayStart = const Duration(seconds: 0),
    this.animationDuration = const Duration(milliseconds: 500),
    this.reverse = false,
    this.animate = true,
  });

  final Widget child;
  final double offset;
  final Curve curve;
  final Direction direction;
  final Duration delayStart;
  final Duration animationDuration;
  final bool reverse;
  final bool animate;

  @override
  _SlideFadeTransitionState createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition>
    with SingleTickerProviderStateMixin {
  late Animation<Offset> _animationSlide;
  late AnimationController _animationController;
  late Animation<double> _animationFade;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (!appStateSettings["batterySaver"]) {
      if (widget.reverse == true) {}

      if (widget.direction == Direction.vertical) {
        _animationSlide = Tween<Offset>(
                begin:
                    Offset(0, widget.reverse ? -widget.offset : widget.offset),
                end: Offset(0, 0))
            .animate(CurvedAnimation(
          curve: widget.curve,
          parent: _animationController,
        ));
      } else {
        _animationSlide = Tween<Offset>(
                begin:
                    Offset(widget.reverse ? -widget.offset : widget.offset, 0),
                end: Offset(0, 0))
            .animate(CurvedAnimation(
          curve: widget.curve,
          parent: _animationController,
        ));
      }

      _animationFade =
          Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(
        curve: widget.curve,
        parent: _animationController,
      ));

      Timer(widget.delayStart, () {
        _animationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appStateSettings["batterySaver"] || widget.animate == false) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _animationFade,
      child: SlideTransition(
        position: _animationSlide,
        child: widget.child,
      ),
    );
  }
}

class AnimateFABDelayed extends StatefulWidget {
  const AnimateFABDelayed({
    Key? key,
    required this.fab,
    this.delay = const Duration(milliseconds: 250),
    this.enabled,
  }) : super(key: key);

  final Widget fab;
  final Duration delay;
  final bool? enabled;

  @override
  State<AnimateFABDelayed> createState() => _AnimateFABDelayedState();
}

class _AnimateFABDelayedState extends State<AnimateFABDelayed> {
  bool scaleIn = false;

  @override
  void initState() {
    super.initState();
    if (appStateSettings["appAnimations"] == AppAnimations.all.index)
      Future.delayed(widget.delay, () {
        setState(() {
          scaleIn = true;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    if (appStateSettings["appAnimations"] != AppAnimations.all.index)
      return widget.fab;
    return AnimateFAB(
      condition: widget.enabled ?? scaleIn,
      fab: widget.fab,
    );
  }
}

class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 2500),
    this.deltaX = 20,
    this.curve = const ElasticInOutCurve(0.19),
    required this.child,
    this.animate = true,
    required this.delay,
  }) : super(key: key);

  final Duration duration;
  final double deltaX;
  final Widget child;
  final Curve curve;
  final bool animate;
  final Duration delay;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> {
  bool startAnimation = false;
  Future? _future;

  @override
  void initState() {
    _future = Future.delayed(widget.delay, () {
      if (mounted)
        setState(() {
          startAnimation = true;
        });
    });
    // Future.delayed(
    //     widget.delay + widget.duration - Duration(milliseconds: 1600),
    //     () async {
    //   if (mounted) HapticFeedback.mediumImpact();
    //   await Future.delayed(Duration(milliseconds: 70), () {
    //     if (mounted) HapticFeedback.mediumImpact();
    //   });
    //   await Future.delayed(Duration(milliseconds: 70), () {
    //     if (mounted) HapticFeedback.mediumImpact();
    //   });
    //   await Future.delayed(Duration(milliseconds: 70), () {
    //     if (mounted) HapticFeedback.mediumImpact();
    //   });
    // });
    super.initState();
  }

  @override
  void dispose() {
    _future = null;
    super.dispose();
  }

  double shakeAnimation(double animation) =>
      0.3 * (0.5 - (0.5 - widget.curve.transform(animation)).abs());

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: widget.key,
      tween: Tween(
        begin: 0.0,
        end: widget.animate == false || startAnimation == false ? 0 : 1,
      ),
      curve: Curves.easeOut,
      duration: widget.duration,
      builder: (context, animation, child) => Transform.translate(
        offset: Offset(widget.deltaX * shakeAnimation(animation), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class AnimatedClipRRect extends StatelessWidget {
  const AnimatedClipRRect({
    required this.duration,
    this.curve = Curves.linear,
    required this.borderRadius,
    required this.child,
    Key? key,
  }) : super(key: key);

  final Duration duration;
  final Curve curve;
  final BorderRadius borderRadius;
  final Widget child;

  static Widget _builder(
      BuildContext context, BorderRadius radius, Widget? child) {
    return ClipRRect(borderRadius: radius, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<BorderRadius>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: BorderRadius.zero, end: borderRadius),
      builder: _builder,
      child: child,
    );
  }
}

class AnimatedScaleOpacity extends StatelessWidget {
  const AnimatedScaleOpacity(
      {required this.child,
      required this.animateIn,
      this.duration = const Duration(milliseconds: 500),
      this.durationOpacity = const Duration(milliseconds: 100),
      this.alignment = AlignmentDirectional.center,
      this.curve = Curves.easeInOutCubicEmphasized,
      super.key});
  final Widget child;
  final bool animateIn;
  final Duration duration;
  final Duration durationOpacity;
  final AlignmentDirectional alignment;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: durationOpacity,
      opacity: animateIn ? 1 : 0,
      child: AnimatedScale(
        scale: animateIn ? 1 : 0,
        duration: duration,
        curve: curve,
        child: child,
        alignment: alignment.toAlignment(),
      ),
    );
  }
}

class BouncingWidget extends StatefulWidget {
  final Widget child;
  final bool animate;
  final double amountEnd;
  final Duration duration;

  BouncingWidget(
      {required this.child,
      required this.animate,
      this.amountEnd = -8,
      this.duration = const Duration(milliseconds: 800)});

  @override
  _BouncingWidgetState createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.amountEnd).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ElasticOutCurve(0.6),
        reverseCurve: Curves.bounceIn,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed && widget.animate) {
          if (widget.animate) {
            _controller.forward();
          }
        }
      });

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BouncingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_isAnimating) {
      _controller.forward();
    }
    _isAnimating = widget.animate;
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
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
    );
  }
}
