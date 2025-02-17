import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Prevent scrolling of the parent scroll when scrolling through the infinite list
ValueNotifier<bool> cancelParentScroll = ValueNotifier<bool>(false);

class MultiDirectionalInfiniteScroll extends StatefulWidget {
  const MultiDirectionalInfiniteScroll({
    Key? key,
    required this.itemBuilder,
    this.initialItems,
    this.overBoundsDetection = 50,
    this.startingScrollPosition = 0,
    this.duration = const Duration(milliseconds: 100),
    this.height,
    this.axis = Axis.horizontal,
    this.onTopLoaded,
    this.onBottomLoaded,
    this.onScroll,
    required this.shouldAddTop,
    required this.shouldAddBottom,
    this.physics,
    this.scrollController,
  }) : super(key: key);
  final int? initialItems;
  final int overBoundsDetection;
  final Function(int index, bool isFirst, bool isLast) itemBuilder;
  final double startingScrollPosition;
  final Duration duration;
  final double? height;
  final Axis axis;
  final Function? onTopLoaded;
  final Function? onBottomLoaded;
  final Function? onScroll;
  final bool Function(int top) shouldAddTop;
  final bool Function(int bottom) shouldAddBottom;
  final ScrollPhysics? physics;
  final ScrollController? scrollController;

  @override
  State<MultiDirectionalInfiniteScroll> createState() =>
      MultiDirectionalInfiniteScrollState();
}

class MultiDirectionalInfiniteScrollState
    extends State<MultiDirectionalInfiniteScroll> {
  late ScrollController _scrollController;
  List<int> top = [1];
  List<int> bottom = [-1, 0];

  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      top = [];
      bottom = [0];
      for (int i = 1; i < widget.initialItems!; i++) {
        top.insert(0, -(widget.initialItems! - i));
        bottom.add(i);
      }
    }
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        widget.startingScrollPosition,
        duration: widget.duration,
        curve: ElasticOutCurve(0.7),
      );
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.removeListener(_scrollListener);
      _scrollController.dispose();
    }
    super.dispose();
  }

  scrollTo(duration, {double? position}) {
    double positionToScroll =
        position == null ? widget.startingScrollPosition : position;
    double clampedPosition = positionToScroll.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent);

    if (_scrollController.position.minScrollExtent == clampedPosition ||
        _scrollController.position.maxScrollExtent == clampedPosition) {
      // Update the scroll position for the possibility of a new item being added
      _scrollController.notifyListeners();
      Future.delayed(Duration(milliseconds: 1), () {
        clampedPosition = positionToScroll.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            clampedPosition,
            duration: duration,
            curve: Curves.fastOutSlowIn,
          );
        });
      });
    }

    _scrollController.animateTo(
      clampedPosition,
      duration: duration,
      curve: Curves.fastOutSlowIn,
    );
  }

  _scrollListener() {
    _onScrollCheck();
    if (widget.onScroll != null) {
      widget.onScroll!(_scrollController.offset);
    }
  }

  _onScrollCheck() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent -
            widget.overBoundsDetection) {
      _onEndReached();
      if (widget.onTopLoaded != null) {
        widget.onTopLoaded!();
      }
    }
    if (_scrollController.offset <=
        _scrollController.position.minScrollExtent +
            widget.overBoundsDetection) {
      _onStartReached();
      if (widget.onBottomLoaded != null) {
        widget.onBottomLoaded!();
      }
    }
  }

  _onEndReached() {
    int indexToAdd = bottom.length;
    if (widget.shouldAddBottom(indexToAdd))
      setState(() {
        bottom.add(indexToAdd);
      });
  }

  _onStartReached() {
    int indexToAdd = -top.length - 1;
    if (widget.shouldAddTop(indexToAdd))
      setState(() {
        top.add(indexToAdd);
      });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        cancelParentScroll.value = true;
        cancelParentScroll.notifyListeners();
      },
      onExit: (_) {
        cancelParentScroll.value = false;
        cancelParentScroll.notifyListeners();
      },
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _scrollController.animateTo(
              _scrollController.offset + event.scrollDelta.dy,
              curve: Curves.linear,
              duration: Duration(milliseconds: 100),
            );
          }
        },
        onPointerDown: (event) {
          if (_scrollController.offset >=
                  _scrollController.position.maxScrollExtent ||
              _scrollController.offset <=
                  _scrollController.position.minScrollExtent) _onScrollCheck();
        },
        child: Container(
          height: widget.height,
          child: CustomScrollView(
            physics: widget.physics,
            scrollDirection: widget.axis,
            controller: _scrollController,
            center: ValueKey('second-sliver-list'),
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return SizedBox(
                      key: ValueKey(index * -1),
                      child: widget.itemBuilder(
                          top[index], index == top.length - 1, false),
                    );
                  },
                  childCount: top.length,
                ),
              ),
              SliverList(
                key: ValueKey('second-sliver-list'),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return SizedBox(
                      key: ValueKey(index),
                      child: widget.itemBuilder(
                          bottom[index], false, index == bottom.length - 1),
                    );
                  },
                  childCount: bottom.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
