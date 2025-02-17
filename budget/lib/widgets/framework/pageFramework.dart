import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/scrollbarWrap.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/swipeToSelectTransactions.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:budget/widgets/pullDownToRefreshSync.dart';
import 'package:flutter/services.dart';

ValueNotifier<bool> isSwipingToDismissPageDown = ValueNotifier<bool>(false);
ValueNotifier<bool> callRefreshToPages = ValueNotifier<bool>(false);

refreshPageFrameworks() async {
  callRefreshToPages.value = !callRefreshToPages.value;
}

class PageFramework extends StatefulWidget {
  const PageFramework({
    Key? key,
    this.title = "",
    this.capitalizeTitle = true,
    this.titleWidget,
    this.slivers = const [],
    this.sliversBefore = true,
    this.listWidgets,
    this.appBarBackgroundColor,
    this.appBarBackgroundColorStart,
    this.backButton = true,
    this.subtitle = null,
    this.subtitleSize = null,
    this.addExtraPaddingAfterCenteredSubtitle,
    this.subtitleAnimationSpeed,
    this.onBottomReached,
    this.pinned = true,
    this.subtitleAlignment = AlignmentDirectional.bottomCenter,
    // this.customTitleBuilder,
    this.onScroll,
    this.floatingActionButton,
    this.textColor,
    this.dragDownToDismiss = false,
    this.dragDownToDismissEnabled = true,
    this.backSwipeToDismissEnabled = true,
    this.onBackButton,
    this.onDragDownToDismiss,
    this.actions,
    this.expandedHeight,
    this.listID,
    this.horizontalPaddingConstrained = false,
    this.getExtraHorizontalPadding,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
    this.overlay,
    this.staticOverlay,
    this.scrollToTopButton = false,
    this.scrollToBottomButton = false,
    this.bottomPadding = true,
    this.enableHeader = true,
    this.scrollPhysics,
    this.belowAppBarPaddingWhenCenteredTitleSmall,
    this.transparentAppBar = false,
    this.customScrollViewBuilder,
    this.bodyBuilder,
    this.scrollController,
    this.selectedTransactionsAppBar,
    this.backButtonOpacity,
    this.forceBackgroundColors = false,
    this.scrollbar = true,
  }) : super(key: key);

  final String title;
  final bool capitalizeTitle;
  final Widget? titleWidget;
  final List<Widget> slivers;
  final bool sliversBefore;
  final List<Widget>? listWidgets;
  final Color? appBarBackgroundColor;
  final bool backButton;
  final Color? appBarBackgroundColorStart;
  final Widget? subtitle;
  final double? subtitleSize;
  final double? addExtraPaddingAfterCenteredSubtitle;
  final double? subtitleAnimationSpeed;
  final VoidCallback? onBottomReached;
  final bool pinned;
  final AlignmentGeometry subtitleAlignment;
  // final Function(AnimationController _animationController)? customTitleBuilder;
  final Function(double position)? onScroll;
  final Widget? floatingActionButton;
  final Color? textColor;
  final bool dragDownToDismiss;
  final bool dragDownToDismissEnabled;
  final bool backSwipeToDismissEnabled;
  final VoidCallback? onBackButton;
  final VoidCallback? onDragDownToDismiss;
  final List<Widget>? actions;
  final double? expandedHeight;
  final String? listID;
  final bool horizontalPaddingConstrained;
  final double Function(BuildContext context)? getExtraHorizontalPadding;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? overlay;
  final Widget? staticOverlay;
  final bool scrollToTopButton;
  final bool scrollToBottomButton;
  final bool bottomPadding;
  final bool enableHeader;
  final ScrollPhysics? scrollPhysics;
  final double? belowAppBarPaddingWhenCenteredTitleSmall;
  final bool transparentAppBar;
  final Widget Function(
      ScrollController scrollController,
      ScrollPhysics? scrollPhysics,
      Widget sliverAppBar)? customScrollViewBuilder;
  final Widget Function(ScrollController scrollController,
      ScrollPhysics? scrollPhysics, Widget sliverAppBar)? bodyBuilder;
  final ScrollController? scrollController;
  final Widget? selectedTransactionsAppBar;
  final double? backButtonOpacity;
  final bool forceBackgroundColors;
  final bool scrollbar;

  @override
  State<PageFramework> createState() => PageFrameworkState();
}

class PageFrameworkState extends State<PageFramework>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final double leftBackSwipeDetectionWidth = 30;

  late ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  late AnimationController _animationControllerShift =
      AnimationController(vsync: this);
  late AnimationController _animationControllerOpacity;
  late AnimationController _animationControllerDragY;
  late AnimationController _scrollToTopAnimationController =
      AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500),
  );

  final double scrollingLimit = 50000;

  double? getDistanceToBottom() {
    try {
      if (_scrollController.hasClients == false) return 0;
      final double currentScrollPosition = _scrollController.position.pixels;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      final double distanceToEnd = maxScrollExtent - currentScrollPosition;
      return distanceToEnd;
    } catch (e) {
      return null;
    }
  }

  double? getDistanceToTop() {
    try {
      final double currentScrollPosition = _scrollController.position.pixels;
      return currentScrollPosition;
    } catch (e) {
      return null;
    }
  }

  void scrollToTop({int duration = 1200}) {
    if (getDistanceToTop() == null ||
        (getDistanceToTop() ?? 0) > scrollingLimit ||
        duration == 0) {
      _scrollController.jumpTo(0);
      print("Scrolling via jump, list too long!");
    } else {
      _scrollController.animateTo(0,
          duration: Duration(
              milliseconds: (getPlatform() == PlatformOS.isIOS
                      ? duration * 0.2
                      : duration)
                  .round()),
          curve: getPlatform() == PlatformOS.isIOS
              ? Curves.easeInOut
              : Curves.elasticOut);
    }
  }

  void scrollToBottom({int duration = 1200}) {
    if (getDistanceToBottom() == null ||
        (getDistanceToBottom() ?? 0) > scrollingLimit ||
        duration == 0) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      print("Scrolling via jump, list too long!");
    } else {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: Duration(
              milliseconds: (getPlatform() == PlatformOS.isIOS
                      ? duration * 0.2
                      : duration)
                  .round()),
          curve: getPlatform() == PlatformOS.isIOS
              ? Curves.easeInOut
              : Curves.elasticOut);
    }
  }

  void scrollTo(double position, {int duration = 1200}) {
    _scrollController.animateTo(position,
        duration: Duration(milliseconds: duration), curve: Curves.easeInOut);
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double expandedHeaderHeight =
          getExpandedHeaderHeight(context, widget.expandedHeight);
      _animationControllerShift = AnimationController(
        vsync: this,
        value: expandedHeaderHeight - 56 == 0 ? 1 : 0,
      );
    });

    _animationControllerOpacity = AnimationController(vsync: this, value: 0.5);
    _animationControllerDragY = AnimationController(vsync: this, value: 0);
    _animationControllerDragY.duration = Duration(milliseconds: 1000);
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addObserver(this);
  }

  // double measurement = 0;
  // @override
  // void didChangeMetrics() {
  //   // should be changed to the new method:
  //   // print(EdgeInsetsDirectional.fromWindowPadding(WidgetsBinding.instance.window.viewInsets,WidgetsBinding.instance.window.devicePixelRatio));
  //   if (MediaQuery.of(context).viewInsets.bottom < measurement) {
  //     // keyboard closed
  //     _scrollListener();
  //   }
  //   measurement = MediaQuery.of(context).viewInsets.bottom;
  // }

  void _scrollListener() {
    if (widget.onScroll != null) {
      widget.onScroll!(_scrollController.offset);
    }
    if (widget.onBottomReached != null &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
      widget.onBottomReached!();
    }
    double percent;
    if (getExpandedHeaderHeight(context, widget.expandedHeight) - 56 == 0) {
      percent = 100;
    } else {
      percent = _scrollController.offset /
          (getExpandedHeaderHeight(context, widget.expandedHeight) - 56);
    }
    if (widget.backButton == true || widget.subtitle != null && percent <= 1) {
      double offset = _scrollController.offset;
      if (percent < 0) offset = 0;

      if (getExpandedHeaderHeight(context, widget.expandedHeight) - 56 == 0) {
        _animationControllerOpacity.value = widget.backButtonOpacity ??
            (0.5 +
                (offset /
                    (getExpandedHeaderHeight(context, widget.expandedHeight)) /
                    2));
        _animationControllerShift.value = (offset /
            (getExpandedHeaderHeight(context, widget.expandedHeight)));
      } else {
        _animationControllerOpacity.value = widget.backButtonOpacity ??
            (0.5 +
                (offset /
                    (getExpandedHeaderHeight(context, widget.expandedHeight) -
                        56) /
                    2));
        _animationControllerShift.value = (offset /
            (getExpandedHeaderHeight(context, widget.expandedHeight) - 56));
      }
    }
    if (_scrollController.offset > 400 &&
        _scrollToTopAnimationController.value == 0) {
      _scrollToTopAnimationController.forward();
    } else if (_scrollController.offset < 400 &&
        _scrollToTopAnimationController.value == 1) {
      _scrollToTopAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationControllerShift.dispose();
    _animationControllerOpacity.dispose();
    _animationControllerDragY.dispose();
    _scrollToTopAnimationController.dispose();

    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double keyboardOpenedPrevious = 0;

  double totalDragY = 0;
  double totalDragX = 0;
  bool swipeDownToDismiss = false;
  bool isBackSideSwiping = false;
  double calculatedYOffsetForX = 0;
  double calculatedYOffsetForY = 0;
  Timer? hapticFeedbackTimer;

  _onPointerMove(PointerMoveEvent ptr) {
    if ((widget.onDragDownToDismiss != null ||
            Navigator.of(context).canPop()) &&
        (widget.dragDownToDismissEnabled || widget.backSwipeToDismissEnabled) &&
        selectingTransactionsActive == 0) {
      if (isBackSideSwiping && widget.backSwipeToDismissEnabled) {
        if (appStateSettings["closeNavigationHapticFeedback"] == true &&
            totalDragX < 90 &&
            totalDragX + ptr.delta.dx >= 90) {
          HapticFeedback.selectionClick();
          hapticFeedbackTimer = Timer(Duration(milliseconds: 200), () {});
        }

        totalDragX = totalDragX + ptr.delta.dx;
        calculatedYOffsetForX = totalDragX / 500;

        if (totalDragX > 20) {
          isSwipingToDismissPageDown.value = true;
          isSwipingToDismissPageDown.notifyListeners();
        }
      }
      if (swipeDownToDismiss && widget.dragDownToDismissEnabled) {
        if (appStateSettings["closeNavigationHapticFeedback"] == true &&
            totalDragY < 125 &&
            totalDragY + ptr.delta.dy >= 125) {
          HapticFeedback.selectionClick();
          hapticFeedbackTimer = Timer(Duration(milliseconds: 200), () {});
        }

        totalDragY = totalDragY + ptr.delta.dy;
        calculatedYOffsetForY = totalDragY / 500;

        if (totalDragY > 20) {
          isSwipingToDismissPageDown.value = true;
          isSwipingToDismissPageDown.notifyListeners();
        }
      }
      _animationControllerDragY.value =
          max(calculatedYOffsetForX, calculatedYOffsetForY);
    }
  }

  _onPointerUp(PointerUpEvent event) async {
    //How far you need to drag to dismiss
    if (widget.dragDownToDismissEnabled || widget.backSwipeToDismissEnabled) {
      if ((totalDragX >= 90 || totalDragY >= 125) &&
          !(ModalRoute.of(context)?.isFirst ?? true)) {
        if (appStateSettings["closeNavigationHapticFeedback"] == true &&
            hapticFeedbackTimer?.isActive == false) {
          HapticFeedback.mediumImpact();
        }

        if (widget.onDragDownToDismiss != null) {
          widget.onDragDownToDismiss!();
        } else {
          await maybePopRoute(context);
        }
      }
      // This cannot be in an else statement
      // If a popup comes e.g. discard changes and user hits cancel
      // we need to already have had this reset!
      totalDragX = 0;
      totalDragY = 0;
      calculatedYOffsetForY = 0;
      calculatedYOffsetForX = 0;
      isBackSideSwiping = false;
      _animationControllerDragY.reverse();
      isSwipingToDismissPageDown.value = false;
      isSwipingToDismissPageDown.notifyListeners();
    }
  }

  _onPointerDown(PointerDownEvent event) {
    if (event.position.dx < leftBackSwipeDetectionWidth &&
        isBackSideSwiping == false) {
      isBackSideSwiping = true;
    }

    if (_scrollController.offset > 0) {
      swipeDownToDismiss = false;
    } else {
      swipeDownToDismiss = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool backButtonEnabled =
        ModalRoute.of(context)?.isFirst == false && widget.backButton;
    bool centeredTitle = getCenteredTitle(
        context: context, backButtonEnabled: backButtonEnabled);
    bool centeredTitleSmall = getCenteredTitleSmall(
        context: context, backButtonEnabled: backButtonEnabled);

    Widget sliverAppBar = PageFrameworkSliverAppBar(
      title: widget.title,
      capitalizeTitle: widget.capitalizeTitle,
      titleWidget: widget.titleWidget,
      appBarBackgroundColor: widget.appBarBackgroundColor,
      appBarBackgroundColorStart: widget.appBarBackgroundColorStart,
      backButton: widget.backButton,
      subtitle: widget.subtitle,
      subtitleSize: widget.subtitleSize,
      subtitleAnimationSpeed: widget.subtitleAnimationSpeed,
      onBottomReached: widget.onBottomReached,
      pinned: widget.pinned,
      subtitleAlignment: widget.subtitleAlignment,
      // customTitleBuilder: widget.customTitleBuilder,
      animationControllerOpacity: _animationControllerOpacity,
      animationControllerShift: _animationControllerShift,
      textColor: widget.textColor,
      onBackButton: widget.onBackButton,
      actions: widget.actions,
      expandedHeight: getExpandedHeaderHeight(context, widget.expandedHeight),
      centeredTitle: centeredTitle,
      centeredTitleSmall: centeredTitleSmall,
      belowAppBarPaddingWhenCenteredTitleSmall:
          widget.belowAppBarPaddingWhenCenteredTitleSmall,
      forceBackgroundColors: widget.forceBackgroundColors,
    );

    double horizontalPadding = (widget.getExtraHorizontalPadding != null
            ? widget.getExtraHorizontalPadding!(context)
            : 0) +
        (widget.horizontalPaddingConstrained
            ? getHorizontalPaddingConstrained(context)
            : 0);

    List<Widget> slivers = [
      for (Widget sliver in widget.slivers)
        SliverPadding(
          padding:
              EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
          sliver: sliver,
        )
    ];

    List<Widget> listWidgets = [
      widget.listWidgets != null
          ? SliverPadding(
              padding: EdgeInsetsDirectional.symmetric(
                  horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...widget.listWidgets!,
                  widget.bottomPadding
                      ? SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 15)
                      : SizedBox.shrink(),
                ]),
              ),
            )
          : SliverToBoxAdapter(
              child: widget.bottomPadding
                  ? SizedBox(height: MediaQuery.paddingOf(context).bottom + 15)
                  : SizedBox.shrink(),
            ),
    ];

    List<Widget> allSliversContent = widget.sliversBefore
        ? [...slivers, ...listWidgets]
        : [...listWidgets, ...slivers];

    Widget scaffold = Scaffold(
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      backgroundColor: widget.backgroundColor,
      body: widget.bodyBuilder != null
          ? widget.bodyBuilder!(
              _scrollController,
              widget.scrollPhysics,
              sliverAppBar,
            )
          : Stack(
              children: [
                ScrollbarWrap(
                  enabled: widget.scrollbar,
                  child: widget.customScrollViewBuilder != null
                      ? widget.customScrollViewBuilder!(
                          _scrollController,
                          widget.scrollPhysics,
                          sliverAppBar,
                        )
                      : CustomScrollView(
                          physics: widget.scrollPhysics,
                          controller: _scrollController,
                          slivers: [
                            if (widget.enableHeader) sliverAppBar,
                            if (widget.enableHeader &&
                                (centeredTitleSmall || centeredTitle))
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(
                                      bottom: widget
                                              .addExtraPaddingAfterCenteredSubtitle ??
                                          0),
                                  child: Center(child: widget.subtitle),
                                ),
                              ),
                            ...allSliversContent
                          ],
                        ),
                ),
                if (widget.overlay != null) widget.overlay ?? SizedBox.shrink(),
              ],
            ),
    );
    Widget? dragDownToDismissScaffold = null;
    if (widget.dragDownToDismiss) {
      dragDownToDismissScaffold = Listener(
        onPointerMove: (ptr) => {_onPointerMove(ptr)},
        onPointerUp: (ptr) => {_onPointerUp(ptr)},
        onPointerDown: (ptr) => {_onPointerDown(ptr)},
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (widget.transparentAppBar != true)
              ...getAppBarBackgroundColorLayers(
                animationControllerOpacity: _animationControllerOpacity,
                percent: null,
                appBarBackgroundColor: widget.appBarBackgroundColor,
                appBarBackgroundColorStart: widget.appBarBackgroundColorStart,
                centeredTitle: centeredTitle,
                centeredTitleSmall: centeredTitleSmall,
                context: context,
                forceBackgroundColors: widget.forceBackgroundColors,
              ),
            AnimatedBuilder(
              animation: _animationControllerDragY,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(
                      0,
                      _animationControllerDragY.value *
                          ((1 + 1 - _animationControllerDragY.value) * 50)),
                  child: scaffold,
                );
              },
            ),
            if (widget.staticOverlay != null)
              widget.staticOverlay ?? SizedBox.shrink(),
          ],
        ),
      );
    }

    Widget scrollToTopButton = AnimatedBuilder(
      animation: _scrollToTopAnimationController,
      builder: (_, child) {
        return IgnorePointer(
          ignoring: _scrollToTopAnimationController.value <= 0.1,
          child: Transform.translate(
            offset: Offset(
              0,
              10 *
                  (1 -
                      CurvedAnimation(
                              parent: _scrollToTopAnimationController,
                              curve: Curves.easeInOut)
                          .value),
            ),
            child: child,
          ),
        );
      },
      child: FadeTransition(
        opacity: CurvedAnimation(
            parent: _scrollToTopAnimationController, curve: Curves.easeInOut),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 7, bottom: 1),
          child: Transform.rotate(
            angle: pi / 2,
            child: Material(
              elevation: 10,
              shadowColor:
                  Theme.of(context).colorScheme.shadow.withOpacity(0.8),
              borderRadius: BorderRadiusDirectional.circular(
                  getPlatform() == PlatformOS.isIOS ? 10 : 15),
              child: ButtonIcon(
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.chevron_left_outlined
                    : Icons.chevron_left_rounded,
                onTap: () {
                  scrollToTop();
                },
              ),
            ),
          ),
        ),
      ),
    );

    Widget scrollToTopBottomButton = AnimatedBuilder(
      animation: _scrollToTopAnimationController,
      builder: (_, child) {
        // Don't show scroll to bottom button if list is way too long!
        if (getDistanceToBottom() == null ||
            (getDistanceToBottom() ?? 0) > scrollingLimit) {
          return scrollToTopButton;
        }
        return IgnorePointer(
          ignoring: _scrollToTopAnimationController.value <= 0.1,
          child: Transform.translate(
            offset: Offset(
              0,
              10 *
                  (1 -
                      CurvedAnimation(
                              parent: _scrollToTopAnimationController,
                              curve: Curves.easeInOut)
                          .value),
            ),
            child: child,
          ),
        );
      },
      child: FadeTransition(
        opacity: CurvedAnimation(
            parent: _scrollToTopAnimationController, curve: Curves.easeInOut),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 7),
          child: Builder(builder: (context) {
            double size = 44;
            double iconPadding = 24;
            double iconInset = 7;
            // same as the FAB height
            double height = getIsFullScreen(context) == false ? 60 : 70;
            double borderRadius = getPlatform() == PlatformOS.isIOS ? 10 : 15;
            return Material(
              elevation: 10,
              shadowColor:
                  Theme.of(context).colorScheme.shadow.withOpacity(0.8),
              borderRadius: BorderRadiusDirectional.circular(borderRadius),
              child: Container(
                height: height,
                width: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(
                      getPlatform() == PlatformOS.isIOS ? 10 : 15),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: size,
                      height: height / 2,
                      child: Tappable(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: borderRadius,
                        onTap: scrollToTop,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(top: iconInset),
                          child: Transform.rotate(
                            angle: directionalityReverse(context) * pi / 2,
                            child: Icon(
                              appStateSettings["outlinedIcons"]
                                  ? Icons.chevron_left_outlined
                                  : Icons.chevron_left_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              size: size - iconPadding,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: size,
                      height: height / 2,
                      child: Tappable(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: borderRadius,
                        onTap: scrollToBottom,
                        child: Padding(
                          padding:
                              EdgeInsetsDirectional.only(bottom: iconInset),
                          child: Transform.rotate(
                            angle: directionalityReverse(context) * -pi / 2,
                            child: Icon(
                              appStateSettings["outlinedIcons"]
                                  ? Icons.chevron_left_outlined
                                  : Icons.chevron_left_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              size: size - iconPadding,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );

    Widget child;
    if (widget.floatingActionButton != null) {
      child = Stack(
        children: [
          dragDownToDismissScaffold ?? scaffold,
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                  bottom: getBottomInsetOfFAB(context), end: 15, start: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  widget.scrollToBottomButton && widget.scrollToTopButton
                      ? scrollToTopBottomButton
                      : SizedBox.shrink(),
                  !widget.scrollToBottomButton && widget.scrollToTopButton
                      ? scrollToTopButton
                      : SizedBox.shrink(),
                  widget.floatingActionButton ?? Container(),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      child = dragDownToDismissScaffold ?? scaffold;
    }

    child = SwipeToSelectTransactions(
      listID: widget.listID ?? "0",
      child: child,
    );

    child = MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: child,
    );

    if (widget.selectedTransactionsAppBar != null)
      child = Stack(
        children: [
          child,
          widget.selectedTransactionsAppBar ?? SizedBox.shrink(),
        ],
      );

    Widget childListener = ValueListenableBuilder(
      valueListenable: callRefreshToPages,
      builder: (context, callRefreshToPagesValue, _) {
        if (callRefreshToPagesValue == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                callRefreshToPages.value = false;
              }));
        }
        return child;
      },
    );

    if (backButtonEnabled == false) {
      return PullDownToRefreshSync(
        child: childListener,
        scrollController: _scrollController,
        checkEnabled: () => widget.dragDownToDismissEnabled != false,
      );
    } else {
      return childListener;
    }
  }
}

class PageFrameworkSliverAppBar extends StatelessWidget {
  const PageFrameworkSliverAppBar({
    Key? key,
    this.title = "",
    this.capitalizeTitle = true,
    this.titleWidget,
    this.appBarBackgroundColor,
    this.appBarBackgroundColorStart,
    this.backButton = true,
    this.subtitle = null,
    this.subtitleSize = null,
    this.subtitleAnimationSpeed,
    this.onBottomReached,
    this.pinned = true,
    this.subtitleAlignment = AlignmentDirectional.bottomCenter,
    // this.customTitleBuilder,
    this.animationControllerOpacity,
    this.animationControllerShift,
    this.actions,
    this.textColor,
    this.onBackButton,
    this.expandedHeight,
    this.bottom,
    this.centeredTitle,
    this.centeredTitleSmall,
    this.belowAppBarPaddingWhenCenteredTitleSmall,
    this.forceBackgroundColors = false,
  }) : super(key: key);

  final String title;
  final bool capitalizeTitle;
  final Widget? titleWidget;
  final Color? appBarBackgroundColor;
  final bool backButton;
  final Color? appBarBackgroundColorStart;
  final Widget? subtitle;
  final double? subtitleSize;
  final double? subtitleAnimationSpeed;
  final VoidCallback? onBottomReached;
  final bool pinned;
  final AlignmentGeometry subtitleAlignment;
  // final Function(AnimationController _animationController)? customTitleBuilder;
  final AnimationController? animationControllerOpacity;
  final AnimationController? animationControllerShift;
  final List<Widget>? actions;
  final Color? textColor;
  final VoidCallback? onBackButton;
  final double? expandedHeight;
  final double collapsedHeight = 56;
  final PreferredSizeWidget? bottom;
  final bool? centeredTitle;
  final bool? centeredTitleSmall;
  final double? belowAppBarPaddingWhenCenteredTitleSmall;
  final bool forceBackgroundColors;
  @override
  Widget build(BuildContext context) {
    bool backButtonEnabled =
        ModalRoute.of(context)?.isFirst == false && backButton;
    bool centeredTitleWithDefault = centeredTitle ??
        getCenteredTitle(
            context: context, backButtonEnabled: backButtonEnabled);
    bool centeredTitleSmallWithDefault = centeredTitleSmall ??
        getCenteredTitleSmall(
            context: context, backButtonEnabled: backButtonEnabled);

    Widget appBar = SliverAppBar(
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
      shadowColor: getPlatform() == PlatformOS.isIOS
          ? Colors.transparent
          : Theme.of(context).shadowColor.withAlpha(130),
      leading: backButtonEnabled == true && animationControllerOpacity != null
          ? FadeTransition(
              opacity: animationControllerOpacity!,
              child: IconButton(
                onPressed: () {
                  if (appStateSettings["closeNavigationHapticFeedback"] ==
                      true) {
                    HapticFeedback.mediumImpact();
                  }

                  if (onBackButton != null)
                    onBackButton!();
                  else
                    maybePopRoute(context);
                },
                icon: Icon(
                  getPlatform() == PlatformOS.isIOS
                      ? appStateSettings["outlinedIcons"]
                          ? Icons.chevron_left_outlined
                          : Icons.chevron_left_rounded
                      : appStateSettings["outlinedIcons"]
                          ? Icons.arrow_back_outlined
                          : Icons.arrow_back_rounded,
                  color: getColor(context, "black"),
                ),
              ),
            )
          : Container(),
      backgroundColor: calculateAppBarBGColor(
        context: context,
        appBarBackgroundColor: appBarBackgroundColor,
        centeredTitleSmall: centeredTitleSmallWithDefault,
      ),
      floating: false,
      pinned: enableDoubleColumn(context) ? true : pinned,
      expandedHeight: centeredTitleSmallWithDefault
          ? 0
          : getExpandedHeaderHeight(context, expandedHeight),
      collapsedHeight: collapsedHeight,
      actions: pushActionsTogether(context, actions),
      flexibleSpace: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        // print('constraints=' + constraints.toString());
        double expandedHeightCalculated =
            getExpandedHeaderHeight(context, expandedHeight);
        double percent = 1 -
            (constraints.biggest.height -
                    collapsedHeight -
                    MediaQuery.paddingOf(context).top) /
                (expandedHeightCalculated - collapsedHeight);
        if (collapsedHeight == expandedHeightCalculated) percent = 1;
        String titleString = capitalizeTitle ? title.capitalizeFirst : title;
        return FlexibleSpaceBar(
          centerTitle: centeredTitleWithDefault,
          titlePadding:
              EdgeInsetsDirectional.symmetric(vertical: 15, horizontal: 18),
          title: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.0)),
            child: Transform.translate(
              offset: centeredTitleWithDefault
                  ? Offset(
                      0,
                      centeredTitleSmallWithDefault
                          ? (enableDoubleColumn(context) ? -1.3 : -3.3)
                          : 0)
                  //  Offset(0, -(1 - percent) * 40)
                  : Offset(
                      (directionalityReverse(context)) *
                          (backButtonEnabled ? 46 * percent : 10 * percent),
                      -(subtitleSize ?? 0) * (1 - percent) + -0.5 * percent,
                    ),
              child: Transform.scale(
                scale: percent * 0.15 + 1,
                child: titleWidget ??
                    AnimatedSizeSwitcher(
                      child: TextFont(
                        key: ValueKey(titleString),
                        text: getIsFullScreen(context) == false &&
                                titleString.length > 20
                            ? titleString.split(" ")[0]
                            : titleString,
                        fontSize: centeredTitleSmallWithDefault
                            ? (enableDoubleColumn(context) ? 19 : 16)
                            : 22,
                        fontWeight: FontWeight.bold,
                        textColor: textColor == null
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : textColor,
                        textAlign: centeredTitleWithDefault
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                    ),
              ),
            ),
          ),
          background: Stack(
            children: [
              ...getAppBarBackgroundColorLayers(
                // If it is collapsed - there is no percent!
                // we need to rely on the animation controller values
                animationControllerOpacity:
                    centeredTitleSmallWithDefault == false &&
                            centeredTitleWithDefault == false
                        ? null
                        : animationControllerOpacity,
                percent: percent,
                appBarBackgroundColor: appBarBackgroundColor,
                appBarBackgroundColorStart: appBarBackgroundColorStart,
                centeredTitle: centeredTitleWithDefault,
                centeredTitleSmall: centeredTitleSmallWithDefault,
                context: context,
                forceBackgroundColors: forceBackgroundColors,
              ),
              subtitle != null &&
                      centeredTitleSmallWithDefault == false &&
                      centeredTitleWithDefault == false
                  ? Builder(builder: (context) {
                      double expandedHeightHeaderPercent =
                          getExpandedHeaderHeight(context, expandedHeight);
                      expandedHeightHeaderPercent =
                          (expandedHeightHeaderPercent - 100) / 100;
                      // print(expandedHeightHeaderPercent * 150 + 50);
                      return Transform.translate(
                          offset: Offset(
                            0,
                            -(percent) *
                                (subtitleAnimationSpeed ?? 100) *
                                (expandedHeightHeaderPercent * 150 + 50) /
                                200,
                          ),
                          child: Align(
                            alignment: centeredTitleWithDefault
                                ? AlignmentDirectional.bottomCenter
                                : subtitleAlignment,
                            child: Opacity(
                              opacity: 1 - clampDouble(percent, 0, 0.5) * 2,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: 20, vertical: 0),
                                child: Transform.translate(
                                  offset: Offset(0, -4),
                                  child: subtitle,
                                ),
                              ),
                            ),
                          ));
                    })
                  : SizedBox(),
            ],
          ),
        );
      }),
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadiusDirectional.vertical(
      //     bottom: getWidthNavigationSidebar(context) > 0
      //         ? Radius.circular(0)
      //         : Radius.circular(15),
      //   ),
      // ),
    );

    if (belowAppBarPaddingWhenCenteredTitleSmall == 0 ||
        belowAppBarPaddingWhenCenteredTitleSmall == null) {
      return appBar;
    }
    return SliverPadding(
      padding: EdgeInsetsDirectional.only(
          bottom: centeredTitleSmallWithDefault
              ? belowAppBarPaddingWhenCenteredTitleSmall ?? 10
              : 0),
      sliver: appBar,
    );
  }
}

Color calculateAppBarBGColor({
  required BuildContext context,
  required Color? appBarBackgroundColor,
  required bool centeredTitleSmall,
}) {
  Color appBarBGColorCalculated = appBarBackgroundColor == null
      ? Theme.of(context).colorScheme.secondaryContainer
      : appBarBackgroundColor;
  if (centeredTitleSmall && getPlatform() == PlatformOS.isIOS) {
    appBarBGColorCalculated =
        appBarBackgroundColor ?? Theme.of(context).colorScheme.background;
  }
  return appBarBGColorCalculated;
}

List<Widget> getAppBarBackgroundColorLayers({
  required BuildContext context,
  required Color? appBarBackgroundColor,
  required Color? appBarBackgroundColorStart,
  required bool centeredTitle,
  required bool centeredTitleSmall,
  // Supply one of (animationControllerOpacity or percent)
  required AnimationController? animationControllerOpacity,
  required double? percent,
  bool forceBackgroundColors = false,
}) {
  // animationControllerOpacity does from top:1 to bottom: 0
  // and to make it into a percent: we use (animationControllerOpacity.value - 0.5) / 0.5
  Color appBarBGColorCalculated = calculateAppBarBGColor(
    context: context,
    appBarBackgroundColor: appBarBackgroundColor,
    centeredTitleSmall: centeredTitleSmall,
  );
  return [
    Container(
      color: appBarBackgroundColor ?? Theme.of(context).colorScheme.background,
      // Fixes backdrop not fading correctly when using Impeller (iOS - Flutter v3.13)
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height - 1,
    ),
    centeredTitleSmall && appBarBackgroundColorStart == null
        ? SizedBox.shrink()
        : Container(
            // Fixes backdrop not fading correctly when using Impeller (iOS - Flutter v3.13)
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height - 1,

            color: appBarBackgroundColorStart == null
                ? Theme.of(context).colorScheme.background
                : appBarBackgroundColorStart,
          ),
    (animationControllerOpacity != null ||
                percent != null ||
                forceBackgroundColors) &&
            centeredTitleSmall
        ? Builder(
            builder: (context) {
              Widget container = Container(
                // Fixes backdrop not fading correctly when using Impeller (iOS - Flutter v3.13)
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height - 1,

                color: forceBackgroundColors || appBarBackgroundColor == null
                    ? dynamicPastel(
                        context,
                        Theme.of(context).colorScheme.secondaryContainer,
                        amount: appStateSettings["materialYou"] ? 0.4 : 0.55,
                      )
                    : appBarBackgroundColor,
              );
              return forceBackgroundColors
                  ? container
                  : animationControllerOpacity != null
                      ? AnimatedBuilder(
                          animation: animationControllerOpacity,
                          builder: (_, child) {
                            return Opacity(
                              opacity: clampDouble(
                                  (animationControllerOpacity.value - 0.5) /
                                      0.5,
                                  0,
                                  1),
                              child: child,
                            );
                          },
                          child: container,
                        )
                      : percent != null
                          ? Opacity(
                              opacity: clampDouble(percent, 0, 1),
                              child: container,
                            )
                          : SizedBox.shrink();
            },
          )
        : SizedBox.shrink(),
    (animationControllerOpacity != null ||
                percent != null ||
                forceBackgroundColors) &&
            centeredTitleSmall == false
        ? Builder(
            builder: (context) {
              Widget container = Container(
                // Fixes backdrop not fading correctly when using Impeller (iOS - Flutter v3.13)
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height - 1,

                color: appBarBGColorCalculated,
              );
              return forceBackgroundColors
                  ? container
                  : animationControllerOpacity != null
                      ? AnimatedBuilder(
                          animation: animationControllerOpacity,
                          builder: (_, child) {
                            return Opacity(
                              opacity: clampDouble(
                                (animationControllerOpacity.value - 0.5) / 0.5,
                                0,
                                1,
                              ),
                              child: child,
                            );
                          },
                          child: container,
                        )
                      : percent != null
                          ? Opacity(
                              opacity: clampDouble(percent, 0, 1),
                              child: container,
                            )
                          : SizedBox.shrink();
            },
          )
        : SizedBox.shrink(),
    (animationControllerOpacity != null ||
                percent != null ||
                forceBackgroundColors) &&
            centeredTitleSmall &&
            getPlatform() == PlatformOS.isIOS
        ? Builder(
            builder: (context) {
              Widget container = Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Container(
                  height: 1.2,
                  color: dynamicPastel(
                    context,
                    forceBackgroundColors || appBarBackgroundColor == null
                        ? dynamicPastel(context,
                            Theme.of(context).colorScheme.secondaryContainer,
                            amount:
                                appStateSettings["materialYou"] ? 0.4 : 0.55)
                        : appBarBackgroundColor,
                    inverse: true,
                    amount: 0.05,
                  ),
                ),
              );
              return forceBackgroundColors
                  ? container
                  : animationControllerOpacity != null
                      ? AnimatedBuilder(
                          animation: animationControllerOpacity,
                          builder: (_, child) {
                            return Opacity(
                              opacity: clampDouble(
                                  (animationControllerOpacity.value - 0.5) /
                                      0.5,
                                  0,
                                  1),
                              child: child,
                            );
                          },
                          child: container,
                        )
                      : percent != null
                          ? Opacity(
                              opacity: clampDouble(percent, 0, 1),
                              child: container,
                            )
                          : SizedBox.shrink();
            },
          )
        : SizedBox.shrink(),
  ];
}

List<Widget> pushActionsTogether(BuildContext context, List<Widget>? actions) {
  return (actions ?? []).asMap().entries.map((action) {
    int idx = action.key;
    int length = (actions ?? []).length;
    Widget widget = action.value;
    double offsetX = (length - 1 - idx) * 7;
    return Transform.translate(
      offset: Offset(offsetX, 0).withDirectionality(context),
      child: widget,
    );
  }).toList();
}

// Only blur if iOS
class BlurBehindAppBar extends StatelessWidget {
  const BlurBehindAppBar({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (getPlatform() != PlatformOS.isIOS) return child;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: child,
      ),
    );
  }
}

// Small blur, used behind popups on iOS
class BlurBehind extends StatelessWidget {
  const BlurBehind({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (getPlatform() != PlatformOS.isIOS) return child;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: child,
      ),
    );
  }
}

double MIN_HEIGHT_FOR_HEADER = 700;
double MAX_HEIGHT_FOR_HEADER = 855;

bool getCenteredTitle(
    {required BuildContext context, required bool backButtonEnabled}) {
  if (getCenteredTitleSmall(
          context: context, backButtonEnabled: backButtonEnabled) ==
      true) {
    return true;
  } else if (enableDoubleColumn(context)) {
    return true;
  }
  return false;
}

bool getCenteredTitleSmall(
    {required BuildContext context, required bool backButtonEnabled}) {
  if (backButtonEnabled &&
      (MediaQuery.sizeOf(context).height <= MIN_HEIGHT_FOR_HEADER ||
          appStateSettings["forceSmallHeader"] == true)) {
    return true;
  } else if (backButtonEnabled && getPlatform() == PlatformOS.isIOS) {
    return true;
  }
  return false;
}

double getExpandedHeaderHeight(
    BuildContext context, double? expandedHeightPassed,
    {bool? isHomePageSpace}) {
  if (expandedHeightPassed != null) return expandedHeightPassed;
  double height = MediaQuery.sizeOf(context).height;

  double minHeaderHeight = getPlatform() == PlatformOS.isIOS
      ? isHomePageSpace == true
          ? 0
          : 100
      : 110;
  double maxHeaderHeight = getPlatform() == PlatformOS.isIOS
      ? isHomePageSpace == true
          ? 0
          : 100
      : 200;

  if (height >= MAX_HEIGHT_FOR_HEADER &&
      appStateSettings["forceSmallHeader"] != true) {
    return maxHeaderHeight;
  } else if (height <= MIN_HEIGHT_FOR_HEADER ||
      appStateSettings["forceSmallHeader"] == true) {
    return minHeaderHeight;
  } else {
    double heightPercentage = (height - MIN_HEIGHT_FOR_HEADER) /
        (MAX_HEIGHT_FOR_HEADER - MIN_HEIGHT_FOR_HEADER);
    double expandedHeaderHeight = minHeaderHeight +
        heightPercentage * (maxHeaderHeight - minHeaderHeight);
    return expandedHeaderHeight;
  }
}
