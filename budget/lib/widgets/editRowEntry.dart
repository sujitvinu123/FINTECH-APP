import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:flutter/material.dart'
    hide
        SliverReorderableList,
        ReorderableDragStartListener,
        ReorderableDelayedDragStartListener;
import 'package:budget/modified/reorderable_list.dart';

class EditRowEntry extends StatelessWidget {
  const EditRowEntry({
    required this.index,
    required this.content,
    this.accentColor,
    required this.openPage,
    this.onDelete,
    this.onTap,
    this.padding,
    this.currentReorder = false,
    this.canReorder = true,
    this.canDelete = true,
    this.extraIcon,
    this.onExtra,
    this.extraWidget,
    this.extraWidgetsBelow,
    this.showMoreWidget,
    this.hideReorder = false,
    this.disableIntrinsicContentHeight = false,
    this.extraButtonHeight,
    this.iconAlignment,
    this.hasMoreOptionsIcon = false,
    this.disableActions = false,
    this.opacity,
    Key? key,
  }) : super(key: key);
  final int index;
  final Widget content;
  final Color? accentColor;
  final Widget openPage;
  final Future<bool> Function()? onDelete;
  final EdgeInsetsDirectional? padding;
  final bool currentReorder;
  final bool canReorder;
  final bool canDelete;
  final IconData? extraIcon;
  final VoidCallback? onExtra;
  final Widget? extraWidget;
  final List<Widget>? extraWidgetsBelow;
  final Function()? onTap;
  final Widget? showMoreWidget;
  final bool? hideReorder;
  final bool disableIntrinsicContentHeight;
  final double? extraButtonHeight;
  final AlignmentDirectional? iconAlignment;
  final bool hasMoreOptionsIcon;
  final bool disableActions;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    Color containerColor = getColor(context, "standardContainerColor");
    bool useDismissToDelete = canDelete && onDelete != null;
    double borderRadius = getPlatform() == PlatformOS.isIOS ? 0 : 18;
    List<BoxShadow> boxShadow = (getPlatform() == PlatformOS.isIOS
            ? []
            : appStateSettings["materialYou"]
                ? []
                : boxShadowCheck(boxShadowGeneral(context))) ??
        [];
    Widget container = Container(
      decoration: BoxDecoration(
        boxShadow: boxShadow,
      ),
      child: OpenContainerNavigation(
        openPage: openPage,
        closedColor: containerColor,
        borderRadius:
            useDismissToDelete && boxShadow.length == 0 ? 0 : borderRadius,
        button: (openContainer) {
          return Tappable(
            borderRadius:
                useDismissToDelete && boxShadow.length == 0 ? 0 : borderRadius,
            color: containerColor,
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
              if (onTap != null)
                onTap!();
              else
                openContainer();
            },
            child: Stack(
              children: [
                PositionedDirectional(
                  bottom: 0,
                  top: 0,
                  child: AnimatedContainer(
                    curve: Curves.easeInOutCubicEmphasized,
                    duration: Duration(milliseconds: 1000),
                    width: accentColor == null
                        ? 0
                        : getPlatform() == PlatformOS.isIOS
                            ? 4
                            : 5,
                    color: dynamicPastel(
                      context,
                      accentColor ?? Colors.transparent,
                      amount: 0.1,
                      inverse: true,
                    ),
                  ),
                ),
                AnimatedPadding(
                  curve: Curves.easeInOutCubicEmphasized,
                  duration: Duration(milliseconds: 1000),
                  padding: EdgeInsetsDirectional.only(
                    start: accentColor == null
                        ? 0
                        : getPlatform() == PlatformOS.isIOS
                            ? 4
                            : 5,
                  ),
                  child: Column(
                    children: [
                      Builder(builder: (context) {
                        Widget child = Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Container(
                                padding: padding ??
                                    EdgeInsetsDirectional.only(
                                      start: 25 - 3,
                                      end: 10,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                child: content,
                              ),
                            ),
                            extraIcon != null
                                ? Tappable(
                                    color: Colors.transparent,
                                    borderRadius: borderRadius,
                                    child: Container(
                                      alignment: iconAlignment,
                                      height: disableIntrinsicContentHeight
                                          ? extraButtonHeight
                                          : double.infinity,
                                      width: 40,
                                      child: ScaledAnimatedSwitcher(
                                        keyToWatch: extraIcon.toString(),
                                        child: Icon(
                                          extraIcon,
                                        ),
                                      ),
                                    ),
                                    onTap: disableActions ? null : onExtra,
                                  )
                                : SizedBox.shrink(),
                            hasMoreOptionsIcon
                                ? HasMoreOptionsIcon()
                                : SizedBox.shrink(),
                            extraWidget ?? SizedBox.shrink(),
                            canDelete
                                ? Tappable(
                                    color: Colors.transparent,
                                    borderRadius: borderRadius,
                                    child: Container(
                                      alignment: iconAlignment,
                                      margin: EdgeInsetsDirectional.only(
                                        end: hideReorder == true &&
                                                showMoreWidget == null
                                            ? 10
                                            : 0,
                                      ),
                                      height: disableIntrinsicContentHeight
                                          ? extraButtonHeight
                                          : double.infinity,
                                      width: 40,
                                      child: Icon(
                                          appStateSettings["outlinedIcons"]
                                              ? Icons.delete_outlined
                                              : Icons.delete_rounded),
                                    ),
                                    onTap: onDelete == null
                                        ? null
                                        : disableActions
                                            ? () {}
                                            : () async {
                                                await onDelete!();
                                              },
                                  )
                                : SizedBox.shrink(),
                            hideReorder == true
                                ? SizedBox.shrink()
                                : canReorder
                                    ? IgnorePointer(
                                        ignoring: disableActions,
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: Tappable(
                                            color: Colors.transparent,
                                            borderRadius: borderRadius,
                                            child: Container(
                                              alignment: iconAlignment,
                                              margin:
                                                  EdgeInsetsDirectional.only(
                                                end: showMoreWidget == null
                                                    ? 10
                                                    : 0,
                                              ),
                                              width: 40,
                                              height:
                                                  disableIntrinsicContentHeight
                                                      ? extraButtonHeight
                                                      : double.infinity,
                                              child: Icon(appStateSettings[
                                                      "outlinedIcons"]
                                                  ? Icons.drag_handle_outlined
                                                  : Icons.drag_handle_rounded),
                                            ),
                                            onTap: () {},
                                          ),
                                        ),
                                      )
                                    : Opacity(
                                        opacity: 0.2,
                                        child: Container(
                                          alignment: iconAlignment,
                                          margin: EdgeInsetsDirectional.only(
                                              end: 10),
                                          width: 40,
                                          height: disableIntrinsicContentHeight
                                              ? null
                                              : double.infinity,
                                          child: Icon(
                                              appStateSettings["outlinedIcons"]
                                                  ? Icons.drag_handle_outlined
                                                  : Icons.drag_handle_rounded),
                                        ),
                                      ),
                            showMoreWidget ?? SizedBox.shrink(),
                          ],
                        );
                        if (disableIntrinsicContentHeight) return child;
                        return IntrinsicHeight(
                          child: child,
                        );
                      }),
                      ...(extraWidgetsBelow ?? [])
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    // alternative theme:
    // container = OpenContainerNavigation(
    //   openPage: openPage,
    //   closedColor: dynamicPastel(context, accentColor, amount: 0.6),
    //   borderRadius: 15,
    //   button: (openContainer) {
    //     return Tappable(
    //       borderRadius: 15,
    //       color: dynamicPastel(context, accentColor, amount: 0.6),
    //       onTap: () {
    //         FocusScopeNode currentFocus = FocusScope.of(context);
    //         if (!currentFocus.hasPrimaryFocus) {
    //           currentFocus.unfocus();
    //         }
    //         if (onTap != null)
    //           onTap!();
    //         else
    //           openContainer();
    //       },
    //       child: Container(
    //         decoration: BoxDecoration(
    //           border: Border.all(
    //             color: dynamicPastel(
    //                 context,
    //                 dynamicPastel(context, accentColor,
    //                     inverse: true, amount: 0.3),
    //                 amount: 0.3),
    //             width: 2,
    //           ),
    //           borderRadius: BorderRadiusDirectional.circular(15),
    //         ),
    //         child: IntrinsicHeight(
    //           child: Row(
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             mainAxisSize: MainAxisSize.max,
    //             children: [
    //               Expanded(
    //                 child: Container(
    //                   padding: padding ??
    //                       EdgeInsetsDirectional.only(
    //                         start: 25,
    //                         end: 10,
    //                         top: 15,
    //                         bottom: 15,
    //                       ),
    //                   child: content,
    //                 ),
    //               ),
    //               extraIcon != null
    //                   ? Tappable(
    //                       color: Colors.transparent,
    //                       borderRadius: 18,
    //                       child: Container(
    //                           height: double.infinity,
    //                           width: 40,
    //                           child: Icon(extraIcon)),
    //                       onTap: onExtra,
    //                     )
    //                   : SizedBox.shrink(),
    //               canDelete
    //                   ? Tappable(
    //                       color: Colors.transparent,
    //                       borderRadius: 18,
    //                       child: Container(
    //                           height: double.infinity,
    //                           width: 40,
    //                           child: Icon(appStateSettings["outlinedIcons"] ? Icons.delete_outlined : Icons.delete_rounded)),
    //                       onTap: onDelete,
    //                     )
    //                   : SizedBox.shrink(),
    //               canReorder
    //                   ? ReorderableDragStartListener(
    //                       index: index,
    //                       child: Tappable(
    //                         color: Colors.transparent,
    //                         borderRadius: 18,
    //                         child: Container(
    //                             margin: EdgeInsetsDirectional.only(end: 10),
    //                             width: 40,
    //                             height: double.infinity,
    //                             child: Icon(appStateSettings["outlinedIcons"] ? Icons.drag_handle_outlined : Icons.drag_handle_rounded)),
    //                         onTap: () {},
    //                       ),
    //                     )
    //                   : Opacity(
    //                       opacity: 0.2,
    //                       child: Container(
    //                         margin: EdgeInsetsDirectional.only(end: 10),
    //                         width: 40,
    //                         height: double.infinity,
    //                         child: Icon(appStateSettings["outlinedIcons"] ? Icons.drag_handle_outlined : Icons.drag_handle_rounded),
    //                       ),
    //                     ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
    if (useDismissToDelete) {
      container = DismissibleEditRowEntry(
        widget: container,
        onDelete: onDelete!,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      );
    }
    return AnimatedOpacity(
      duration: appStateSettings["appAnimations"] != AppAnimations.all.index
          ? Duration.zero
          : Duration(milliseconds: 200),
      opacity: currentReorder ? 0.6 : (opacity ?? 1),
      child: AddTopAndBottomBorderIfIOS(
        enabled: getPlatform() == PlatformOS.isIOS,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
              horizontal: getPlatform() == PlatformOS.isIOS ? 0 : 10,
              vertical: getPlatform() == PlatformOS.isIOS ? 0 : 5),
          child: ReorderableDelayedDragStartListener(
            index: index,
            child: container,
            enabled: canReorder,
          ),
        ),
      ),
    );
  }
}

class AddTopAndBottomBorderIfIOS extends StatelessWidget {
  const AddTopAndBottomBorderIfIOS(
      {required this.child, required this.enabled, super.key});
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled == false) return child;
    return Stack(
      children: [
        Container(
            decoration: BoxDecoration(
                border: BorderDirectional(
                    bottom: BorderSide(
                        color: getColor(context, "dividerColor"), width: 1.5))),
            child: child),
        PositionedDirectional(
            start: 0,
            end: 0,
            top: 0,
            child: Transform.translate(
              offset: Offset(0, -1.5),
              child: Container(
                  height: 1.5, color: getColor(context, "dividerColor")),
            )),
      ],
    );
  }
}

class DismissibleEditRowEntry extends StatelessWidget {
  const DismissibleEditRowEntry({
    super.key,
    required this.widget,
    required this.onDelete,
    required this.borderRadius,
    required this.boxShadow,
  });
  final Widget widget;
  final Future<bool> Function() onDelete;
  final double borderRadius;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isSwipingToDismissPageDown,
      // Disable the dismiss action if we are swiping down to minimize the page!
      builder: (context, value, _) {
        Widget child = Dismissible(
          key: ValueKey(key),
          background: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            opacity: value ? 0 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadiusDirectional.circular(borderRadius),
                color: Colors.red[700],
              ),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 15),
              alignment: AlignmentDirectional.centerStart,
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.delete_outlined
                    : Icons.delete_rounded,
                color: Colors.white,
              ),
            ),
          ),
          secondaryBackground: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            opacity: value ? 0 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadiusDirectional.circular(borderRadius),
                color: Colors.red[700],
              ),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 15),
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.delete_outlined
                    : Icons.delete_rounded,
                color: Colors.white,
              ),
            ),
          ),
          dismissThresholds: {
            DismissDirection.startToEnd: value == true ? 10 : 0.5,
            DismissDirection.endToStart: value == true ? 10 : 0.5,
          },
          onDismissed: (DismissDirection direction) {},
          confirmDismiss: (direction) async {
            // Do not return the result of onDelete.
            // For example: If going to delete category
            // Press delete, then no to delete all transactions - it still shows minimize size animation!
            // We can't wait on this because we need to pop any routes before things are deleted
            // Ideally to show a change in the list (i.e. an item getting deleted)
            // We use something like:  ImplicitlyAnimatedDeleteSliverReorderableList
            // Still in development... has many bugs - is there a better way to do it? see:  ImplicitlyAnimatedDeleteSliverReorderableList
            await onDelete();
            return false;
          },
          child: widget,
        );
        if (boxShadow.length == 0) {
          return ClipRRect(
            borderRadius: BorderRadiusDirectional.circular(borderRadius),
            child: child,
          );
        } else {
          return child;
        }
      },
    );
  }
}

class HasMoreOptionsIcon extends StatelessWidget {
  const HasMoreOptionsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      appStateSettings["outlinedIcons"]
          ? Icons.more_vert_outlined
          : Icons.more_vert_rounded,
      size: 22,
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
    );
  }
}
