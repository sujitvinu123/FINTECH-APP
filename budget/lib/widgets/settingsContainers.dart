import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsContainerSwitch extends StatefulWidget {
  const SettingsContainerSwitch({
    required this.title,
    this.description,
    this.descriptionWithValue,
    this.initialValue = false,
    this.icon,
    required this.onSwitched,
    this.verticalPadding,
    this.syncWithInitialValue = true,
    this.onLongPress,
    this.onTap,
    this.enableBorderRadius = false,
    this.hasMoreOptionsIcon = false,
    this.runOnSwitchedInitially = false,
    this.descriptionColor,
    this.backgroundColor,
    this.isOutlined,
    this.horizontalPadding,
    Key? key,
  }) : super(key: key);

  final String title;
  final String? description;
  final String Function(bool)? descriptionWithValue;
  final bool initialValue;
  final IconData? icon;
  final Function(bool) onSwitched;
  final double? verticalPadding;
  final bool syncWithInitialValue;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool enableBorderRadius;
  final bool hasMoreOptionsIcon;
  final bool runOnSwitchedInitially;
  final Color? descriptionColor;
  final Color? backgroundColor;
  final bool? isOutlined;
  final double? horizontalPadding;

  @override
  State<SettingsContainerSwitch> createState() =>
      _SettingsContainerSwitchState();
}

class _SettingsContainerSwitchState extends State<SettingsContainerSwitch> {
  bool value = true;
  bool waiting = false;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
    Future.delayed(Duration.zero, () {
      if (widget.runOnSwitchedInitially == true) {
        widget.onSwitched(value);
      }
    });
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    if (widget.initialValue != value && widget.syncWithInitialValue) {
      setState(() {
        value = widget.initialValue;
      });
    }
  }

  void toggleSwitch() async {
    setState(() {
      waiting = true;
    });
    if (await widget.onSwitched(!value) != false) {
      setState(() {
        value = !value;
        waiting = false;
      });
    } else {
      setState(() {
        waiting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? description = widget.description;
    if (widget.descriptionWithValue != null) {
      description = widget.descriptionWithValue!(value);
    }
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: waiting ? 0.5 : 1,
      child: SettingsContainer(
        isOutlined: widget.isOutlined,
        horizontalPadding: widget.horizontalPadding,
        backgroundColor: widget.backgroundColor,
        hasMoreOptionsIcon: widget.hasMoreOptionsIcon,
        enableBorderRadius: widget.enableBorderRadius,
        onLongPress: widget.onLongPress,
        onTap: widget.onTap ?? () => {toggleSwitch()},
        title: widget.title,
        description: description,
        afterWidget: Padding(
          padding: const EdgeInsetsDirectional.only(start: 5),
          child: PlatformSwitch(
            value: value,
            onTap: toggleSwitch,
          ),
        ),
        icon: widget.icon,
        verticalPadding: widget.verticalPadding,
        descriptionColor: widget.descriptionColor,
      ),
    );
  }
}

class PlatformSwitch extends StatelessWidget {
  final bool value;
  final Function onTap;

  PlatformSwitch({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (getPlatform() == PlatformOS.isIOS) {
      return CupertinoSwitch(
        activeColor: Theme.of(context).colorScheme.primary,
        value: value,
        onChanged: (_) {
          onTap();
        },
      );
    } else {
      return Switch(
        activeColor: Theme.of(context).colorScheme.primary,
        value: value,
        onChanged: (_) {
          onTap();
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
  }
}

class SettingsContainerOpenPage extends StatelessWidget {
  const SettingsContainerOpenPage({
    Key? key,
    required this.openPage,
    this.onClosed,
    this.onOpen,
    required this.title,
    this.description,
    this.icon,
    this.iconSize,
    this.iconScale,
    this.isOutlined,
    this.isOutlinedColumn,
    this.isWideOutlined,
    this.descriptionColor,
    this.afterWidget,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  final Widget openPage;
  final VoidCallback? onClosed;
  final VoidCallback? onOpen;
  final String title;
  final String? description;
  final IconData? icon;
  final double? iconSize;
  final double? iconScale;
  final bool? isOutlined;
  final bool? isOutlinedColumn;
  final bool? isWideOutlined;
  final Color? descriptionColor;
  final Widget? afterWidget;
  final Color? backgroundColor;
  final Function(VoidCallback openContainer)? onTap;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: isOutlined == false || isOutlined == null
          ? EdgeInsetsDirectional.zero
          : EdgeInsetsDirectional.only(top: 5, bottom: 5, start: 4, end: 4),
      child: OpenContainerNavigation(
        onClosed: onClosed,
        onOpen: onOpen,
        closedColor:
            backgroundColor ?? Theme.of(context).colorScheme.background,
        borderRadius: isOutlined == true
            ? 10
            : getIsFullScreen(context)
                ? 20
                : 0,
        button: (openContainer) {
          return SettingsContainer(
            title: title,
            description: description,
            icon: icon,
            iconSize: iconSize,
            iconScale: iconScale,
            backgroundColor: backgroundColor,
            onTap: onTap != null
                ? () => onTap!(openContainer)
                : () {
                    openContainer();
                    // Navigator.push(
                    //   context,
                    //   PageRouteBuilder(
                    //     transitionDuration: Duration(milliseconds: 500),
                    //     transitionsBuilder:
                    //         (context, animation, secondaryAnimation, child) {
                    //       return SharedAxisTransition(
                    //         animation: animation,
                    //         secondaryAnimation: secondaryAnimation,
                    //         transitionType: SharedAxisTransitionType.horizontal,
                    //         child: child,
                    //       );
                    //     },
                    //     pageBuilder: (context, animation, secondaryAnimation) {
                    //       return openPage;
                    //     },
                    //   ),
                    // );
                  },
            afterWidget: isOutlined ?? false
                ? SizedBox.shrink()
                : Row(
                    children: [
                      if (afterWidget != null) afterWidget!,
                      MoreChevron(
                          color: colorScheme.secondary,
                          size: isOutlined == true ? 20 : 30),
                    ],
                  ),
            isOutlined: isOutlined,
            isOutlinedColumn: isOutlinedColumn,
            isWideOutlined: isWideOutlined,
            descriptionColor: descriptionColor,
          );
        },
        openPage: openPage,
      ),
    );
  }
}

class MoreChevron extends StatelessWidget {
  const MoreChevron({
    super.key,
    required this.color,
    this.size,
  });
  final Color color;
  final double? size;
  @override
  Widget build(BuildContext context) {
    return Icon(
      appStateSettings["outlinedIcons"]
          ? Icons.chevron_right_outlined
          : Icons.chevron_right_rounded,
      size: size,
      color: color,
    );
  }
}

class SettingsContainerDropdown extends StatefulWidget {
  const SettingsContainerDropdown({
    Key? key,
    required this.title,
    this.description,
    this.icon,
    required this.initial,
    required this.items,
    required this.onChanged,
    this.getLabel,
    this.verticalPadding,
    this.enableBorderRadius = false,
    this.faintValues = const [],
    this.backgroundColor,
  }) : super(key: key);

  final String title;
  final String? description;
  final IconData? icon;
  final String initial;
  final List<String> items;
  final Function(String) onChanged;
  final Function(String)? getLabel;
  final double? verticalPadding;
  final bool enableBorderRadius;
  final List<String> faintValues;
  final Color? backgroundColor;

  @override
  State<SettingsContainerDropdown> createState() =>
      _SettingsContainerDropdownState();
}

class _SettingsContainerDropdownState extends State<SettingsContainerDropdown> {
  late GlobalKey<DropdownSelectState>? _dropdownKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      enableBorderRadius: widget.enableBorderRadius,
      verticalPadding: widget.verticalPadding,
      title: widget.title,
      description: widget.description,
      icon: widget.icon,
      backgroundColor: widget.backgroundColor,
      onTap: () {
        _dropdownKey!.currentState!.openDropdown();
      },
      afterWidget: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10),
        child: DropdownSelect(
          key: _dropdownKey,
          compact: true,
          initial: widget.items.contains(widget.initial) == false
              ? widget.items[0]
              : widget.initial,
          items: widget.items,
          onChanged: widget.onChanged,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          getLabel: widget.getLabel,
          faintValues: widget.faintValues,
        ),
      ),
    );
  }
}

class SettingsContainerOutlined extends StatelessWidget {
  const SettingsContainerOutlined({
    Key? key,
    required this.title,
    this.description,
    this.icon,
    this.afterWidget,
    this.onTap,
    this.onLongPress,
    this.verticalPadding,
    this.horizontalPadding,
    this.iconSize,
    this.iconScale,
    this.isExpanded = true,
    this.isOutlinedColumn,
    this.isWideOutlined,
  }) : super(key: key);

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? afterWidget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? verticalPadding;
  final double? horizontalPadding;
  final double? iconSize;
  final double? iconScale;
  final bool isExpanded;
  final bool? isOutlinedColumn;
  final bool? isWideOutlined;

  @override
  Widget build(BuildContext context) {
    double defaultIconSize = 25;
    Widget content;
    if (isOutlinedColumn == true) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                : getColor(context, "lightDarkAccentHeavy")),
            width: 2,
          ),
          borderRadius: BorderRadiusDirectional.circular(10),
        ),
        padding: EdgeInsetsDirectional.only(
          start: horizontalPadding ?? 3,
          end: horizontalPadding ?? 3,
          top: verticalPadding ?? 14,
          bottom: verticalPadding ?? 14,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon == null
                ? SizedBox.shrink()
                : Transform.scale(
                    scale: iconScale ?? 1,
                    child: Icon(
                      icon,
                      size: iconSize ?? defaultIconSize + 5,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
            SizedBox(height: 10),
            TextFont(
              text: title,
              fontSize: 13,
              textColor: getColor(context, "black").withOpacity(0.8),
              maxLines: 2,
              autoSizeText: true,
              textAlign: TextAlign.center,
            )
          ],
        ),
      );
    } else {
      Widget textContent = description == null
          ? TextFont(
              fixParagraphMargin: true,
              text: title,
              fontSize: isExpanded == false ? 16 : 14.5,
              maxLines: 1,
              overflow: TextOverflow.clip,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFont(
                  fixParagraphMargin: true,
                  text: title,
                  fontSize: 16,
                  maxLines: 1,
                ),
                Container(height: 3),
                TextFont(
                  text: description!,
                  fontSize: 11,
                  maxLines: 5,
                  textColor: appStateSettings["increaseTextContrast"]
                      ? getColor(context, "textLight")
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.5),
                ),
              ],
            );
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                : getColor(context, "lightDarkAccentHeavy")),
            width: 2,
          ),
          borderRadius: BorderRadiusDirectional.circular(10),
        ),
        padding: EdgeInsetsDirectional.only(
          start: horizontalPadding ?? 13,
          end: horizontalPadding ?? 4,
          top: verticalPadding ?? 14,
          bottom: verticalPadding ?? 14,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize:
              isExpanded == false ? MainAxisSize.min : MainAxisSize.max,
          children: [
            icon == null
                ? SizedBox.shrink()
                : Padding(
                    padding: EdgeInsetsDirectional.only(
                        end: 8 +
                            defaultIconSize -
                            (iconSize ?? defaultIconSize)),
                    child: Transform.scale(
                      scale: iconScale ?? 1,
                      child: Icon(
                        icon,
                        size: iconSize ?? defaultIconSize,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
            isWideOutlined == true ? SizedBox(width: 3) : SizedBox.shrink(),
            isExpanded
                ? Expanded(child: textContent)
                : Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: textContent,
                    ),
                  ),
            afterWidget ?? SizedBox()
          ],
        ),
      );
    }
    return Tappable(
      onLongPress: onLongPress,
      color: Colors.transparent,
      onTap: onTap,
      borderRadius: 10,
      child: content,
    );
  }
}

class SettingsContainer extends StatelessWidget {
  const SettingsContainer({
    Key? key,
    required this.title,
    this.description,
    this.icon,
    this.afterWidget,
    this.onTap,
    this.onLongPress,
    this.verticalPadding,
    this.horizontalPadding,
    this.iconSize,
    this.iconScale,
    this.isOutlined,
    this.isOutlinedColumn,
    this.enableBorderRadius = false,
    this.isWideOutlined,
    this.hasMoreOptionsIcon,
    this.descriptionColor,
    this.descriptionWidget,
    this.backgroundColor,
  }) : super(key: key);

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? afterWidget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? verticalPadding;
  final double? horizontalPadding;
  final double? iconSize;
  final double? iconScale;
  final bool? isOutlined;
  final bool? isOutlinedColumn;
  final bool enableBorderRadius;
  final bool? isWideOutlined;
  final bool? hasMoreOptionsIcon;
  final Color? descriptionColor;
  final Widget? descriptionWidget;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusDirectional.circular(
          (enableBorderRadius || getIsFullScreen(context)) && isOutlined != true
              ? getPlatform() == PlatformOS.isIOS
                  ? 10
                  : 15
              : 0),
      child: isOutlined == true
          ? SettingsContainerOutlined(
              title: title,
              afterWidget: afterWidget,
              description: description,
              icon: icon,
              iconSize: iconSize,
              iconScale: iconScale,
              onTap: onTap,
              onLongPress: onLongPress,
              verticalPadding: verticalPadding,
              horizontalPadding: horizontalPadding,
              isOutlinedColumn: isOutlinedColumn,
              isWideOutlined: isWideOutlined,
            )
          : Tappable(
              color: backgroundColor ?? Colors.transparent,
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: horizontalPadding ?? 18,
                  // (enableBorderRadius &&
                  //         getWidthNavigationSidebar(context) <= 0 &&
                  //         icon != null
                  //     ? 10
                  //     : 18),
                  vertical: verticalPadding ?? 11,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          icon == null
                              ? SizedBox.shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 16),
                                  child: ScaledAnimatedSwitcher(
                                    keyToWatch: icon.toString(),
                                    child: Transform.scale(
                                      scale: iconScale ?? 1,
                                      child: Icon(
                                        icon,
                                        size: iconSize ?? 30,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ),
                                ),
                          Expanded(
                            child: description == null &&
                                    descriptionWidget == null
                                ? TextFont(
                                    fixParagraphMargin: true,
                                    text: title,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 5,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFont(
                                        fixParagraphMargin: true,
                                        text: title,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        maxLines: 5,
                                      ),
                                      if (descriptionWidget != null)
                                        descriptionWidget!,
                                      if (description != null)
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  top: 3),
                                          child: AnimatedSizeSwitcher(
                                            child: TextFont(
                                              key: ValueKey(
                                                  description.toString()),
                                              text: description ?? "",
                                              fontSize: 14,
                                              maxLines: 5,
                                              textColor: descriptionColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    hasMoreOptionsIcon == true
                        ? HasMoreOptionsIcon()
                        : SizedBox.shrink(),
                    afterWidget ?? SizedBox()
                  ],
                ),
              ),
            ),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 63,
        end: 63,
        top: 15,
        bottom: 7,
      ),
      child: TextFont(
        text: title.capitalizeFirst,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        textColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
