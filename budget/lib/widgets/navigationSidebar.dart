import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/pages/exchangeRatesPage.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/timeDigits.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:timer_builder/timer_builder.dart';

// returns 0 if no navigation sidebar should be shown
double getWidthNavigationSidebar(BuildContext context) {
  double screenPercent = 0.3;
  double maxWidthNavigation = 270;
  double minScreenWidth = 700;

  if (MediaQuery.sizeOf(context).width < minScreenWidth) return 0;
  if (appStateSettings["expandedNavigationSidebar"] == false) {
    return 70 + MediaQuery.viewPaddingOf(context).left;
  }
  return (MediaQuery.sizeOf(context).width * screenPercent > maxWidthNavigation
          ? maxWidthNavigation
          : MediaQuery.sizeOf(context).width * screenPercent) +
      MediaQuery.viewPaddingOf(context).left;
}

double getHeightNavigationSidebar(context) {
  if (getIsFullScreen(context)) {
    // No navbar in full screen
    return 0;
  } else {
    if (getPlatform() == PlatformOS.isIOS) {
      return 70 + MediaQuery.viewPaddingOf(context).bottom;
    } else {
      return 80 + MediaQuery.viewPaddingOf(context).bottom;
    }
  }
}

double getBottomInsetOfFAB(context) {
  if (MediaQuery.viewPaddingOf(context).bottom <= 15) {
    return 15;
  } else {
    return MediaQuery.viewPaddingOf(context).bottom;
  }
}

bool enableDoubleColumn(context) {
  // double minScreenWidth = 1000;
  double minScreenWidth = 750 + getWidthNavigationSidebar(context);
  return MediaQuery.sizeOf(context).width > minScreenWidth ? true : false;
}

class NavigationSidebar extends StatefulWidget {
  const NavigationSidebar({super.key});

  @override
  State<NavigationSidebar> createState() => NavigationSidebarState();
}

class NavigationSidebarState extends State<NavigationSidebar> {
  int selectedIndex = 0;
  bool isCalendarOpened = false;

  void refreshState() {
    setState(() {});
  }

  void setSelectedIndex(index) {
    setState(() {
      selectedIndex = index;
    });
    FocusScope.of(context).unfocus();
    checkIfExchangeRateChangeAfter();
  }

  @override
  Widget build(BuildContext context) {
    double widthNavigationSidebar = getWidthNavigationSidebar(context);
    if (widthNavigationSidebar <= 0) {
      return SizedBox.shrink();
    }
    // print(selectedIndex);
    return Listener(
      onPointerDown: (_) {
        if (isCalendarOpened) maybePopRoute(navigatorKey.currentContext!);
        // Remove any open context menus when sidebar clicked
        ContextMenuController.removeAny();
      },
      child: AnimatedContainer(
        duration: appStateSettings["appAnimations"] != AppAnimations.all.index
            ? Duration.zero
            : Duration(milliseconds: 1500),
        curve: Curves.easeInOutCubicEmphasized,
        width: getWidthNavigationSidebar(context),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: BorderDirectional(
              end: BorderSide(
                color: appStateSettings["materialYou"]
                    ? dynamicPastel(context,
                        Theme.of(context).colorScheme.secondaryContainer,
                        amountLight: 0, amountDark: 0.6)
                    : getColor(context, "lightDarkAccent"),
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
                start: MediaQuery.viewPaddingOf(context).left),
            child: IgnorePointer(
              ignoring: appStateSettings["hasOnboarded"] == false ||
                  lockAppWaitForRestart == true,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: appStateSettings["hasOnboarded"] == false ||
                        lockAppWaitForRestart == true
                    ? 0.3
                    : 1,
                child: SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: MediaQuery.paddingOf(context).top),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.7,
                                child: AnimatedPadding(
                                  duration: appStateSettings["appAnimations"] !=
                                          AppAnimations.all.index
                                      ? Duration.zero
                                      : Duration(milliseconds: 1500),
                                  curve: Curves.easeInOutCubicEmphasized,
                                  padding: EdgeInsetsDirectional.only(
                                    bottom: appStateSettings[
                                            "expandedNavigationSidebar"]
                                        ? 0
                                        : 5,
                                    top: appStateSettings[
                                            "expandedNavigationSidebar"]
                                        ? 0
                                        : 7,
                                    start: appStateSettings[
                                            "expandedNavigationSidebar"]
                                        ? 0
                                        : 7,
                                  ),
                                  child: AnimatedRotation(
                                    duration:
                                        appStateSettings["appAnimations"] !=
                                                AppAnimations.all.index
                                            ? Duration.zero
                                            : Duration(milliseconds: 1500),
                                    turns: appStateSettings[
                                            "expandedNavigationSidebar"]
                                        ? 0
                                        : -0.5,
                                    curve: Curves.easeInOutCubicEmphasized,
                                    child: IconButton(
                                      padding: EdgeInsetsDirectional.all(15),
                                      onPressed: () {
                                        updateSettings(
                                            "expandedNavigationSidebar",
                                            !appStateSettings[
                                                "expandedNavigationSidebar"],
                                            updateGlobalState: true);
                                      },
                                      icon: Icon(
                                        appStateSettings["outlinedIcons"]
                                            ? Icons.chevron_left_outlined
                                            : Icons.chevron_left_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                              horizontal: 14),
                                      child: Tappable(
                                        borderRadius: 20,
                                        onTap: () async {
                                          isCalendarOpened = true;
                                          if (navigatorKey.currentContext !=
                                              null) {
                                            await showCustomDatePicker(
                                              navigatorKey.currentContext!,
                                              DateTime.now(),
                                              cancelText: "",
                                              helpText: "",
                                              confirmText: "close".tr(),
                                            );
                                            isCalendarOpened = false;
                                          }
                                        },
                                        child: AnimatedPadding(
                                          duration: appStateSettings[
                                                      "appAnimations"] !=
                                                  AppAnimations.all.index
                                              ? Duration.zero
                                              : Duration(milliseconds: 1500),
                                          curve:
                                              Curves.easeInOutCubicEmphasized,
                                          padding: EdgeInsetsDirectional.only(
                                            top: appStateSettings[
                                                    "expandedNavigationSidebar"]
                                                ? 12
                                                : 0,
                                            bottom: appStateSettings[
                                                    "expandedNavigationSidebar"]
                                                ? 18
                                                : 0,
                                          ),
                                          child: SidebarClock(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedContainer(
                                duration: appStateSettings["appAnimations"] !=
                                        AppAnimations.all.index
                                    ? Duration.zero
                                    : Duration(milliseconds: 1500),
                                curve: Curves.easeInOutCubicEmphasized,
                                height: appStateSettings[
                                        "expandedNavigationSidebar"]
                                    ? 40
                                    : 0,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "home",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "transactions",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "budgets",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "goals",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "subscriptions",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "scheduled",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "loans",
                                currentPageIndex: selectedIndex,
                              ),
                              // if (notificationsGlobalEnabled)
                              //   NavigationSidebarButtonWithNavBarIconData(
                              //     navBarIconDataKey: "notifications",
                              //     currentPageIndex: selectedIndex,
                              //   ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "allSpending",
                                currentPageIndex: selectedIndex,
                              ),
                              EditDataButtons(selectedIndex: selectedIndex),
                            ],
                          ),
                          Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 40),
                              GoogleAccountLoginButton(
                                navigationSidebarButton: true,
                                isButtonSelected: selectedIndex == 8,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "settings",
                                currentPageIndex: selectedIndex,
                              ),
                              NavigationSidebarButtonWithNavBarIconData(
                                navBarIconDataKey: "about",
                                currentPageIndex: selectedIndex,
                              ),
                              SyncButton(),
                              SizedBox(height: 10),
                              SizedBox(
                                  height:
                                      MediaQuery.viewPaddingOf(context).bottom),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarClock extends StatelessWidget {
  const SidebarClock({super.key});

  @override
  Widget build(BuildContext context) {
    return appStateSettings["expandedNavigationSidebar"]
        ? Center(
            key: ValueKey(appStateSettings["expandedNavigationSidebar"]),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.0)),
              child: TimerBuilder.periodic(
                Duration(seconds: 5),
                builder: (context) {
                  DateTime now = DateTime.now();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isSetting24HourFormat() ??
                              isSystem24HourFormat(context) == true
                          ? TextFont(
                              textColor: getColor(context, "black"),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              // Remove any am/pm indication by substring
                              // Add extra spaces so substring never fails
                              text: (getWordedTime(null, now) + "      ")
                                  .substring(0, 5)
                                  .trim(),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: TextFont(
                                    textColor: getColor(context, "black"),
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                    // Remove any am/pm indication by substring
                                    text: getWordedTime(null, now)
                                        .substring(0, 5)
                                        .trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                  ),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        bottom: 4.4, start: 7),
                                    child: TextFont(
                                      textColor: getColor(context, "black"),
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      text: getMeridiemString(now),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      TextFont(
                        textColor: getColor(context, "black").withOpacity(0.5),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        text: DateFormat('EEEE', context.locale.toString())
                            .format(now),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      SizedBox(height: 5),
                      TextFont(
                        textColor: getColor(context, "black").withOpacity(0.5),
                        fontSize: 18,
                        text: DateFormat.yMMMMd(context.locale.toString())
                            .format(now),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        : Container(
            key: ValueKey(appStateSettings["expandedNavigationSidebar"]),
          );
  }
}

class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  GlobalKey<RefreshButtonState> refreshButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget refreshButton = Opacity(
      opacity: 0.6,
      child: RefreshButton(
        key: refreshButtonKey,
        halfAnimation: true,
        customIcon: appStateSettings["outlinedIcons"]
            ? Icons.sync_outlined
            : Icons.sync_rounded,
        flipIcon: true,
        padding: EdgeInsetsDirectional.zero,
        iconOnly: true,
        onTap: () async {
          if (runningCloudFunctions == false) {
            await runAllCloudFunctions(
              context,
              forceSignIn: true,
            );
          }
        },
      ),
    );
    return AnimatedExpanded(
      expand: !(appStateSettings["currentUserEmail"] == "" ||
          appStateSettings["backupSync"] == false),
      child: Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 5, vertical: 1),
        child: Tappable(
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 50,
          onTap: () async {
            if (runningCloudFunctions == false) {
              refreshButtonKey.currentState?.startAnimation();
              await runAllCloudFunctions(
                context,
                forceSignIn: true,
              );
              refreshButtonKey.currentState?.startAnimation();
            }
          },
          // Do not use Animated Switcher because otherwise duplicate key!
          child: appStateSettings["expandedNavigationSidebar"]
              ? Padding(
                  key: ValueKey(appStateSettings["expandedNavigationSidebar"]),
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20, vertical: 13),
                  child: Row(
                    children: [
                      refreshButton,
                      SizedBox(width: 15),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          child: SizedBox(
                            key: ValueKey(appStateSettings["lastSynced"]),
                            child: TimerBuilder.periodic(
                              Duration(seconds: 5),
                              builder: (context) {
                                DateTime? dateTimeLastSynced =
                                    getTimeLastSynced();
                                int diff = DateTime.now()
                                    .difference(
                                        dateTimeLastSynced ?? DateTime.now())
                                    .inDays;
                                return TextFont(
                                  textAlign: TextAlign.start,
                                  textColor: diff > 1
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                          .withOpacity(0.5)
                                      : getColor(context, "textLight"),
                                  fontSize: 13,
                                  maxLines: 3,
                                  text: "synced".tr() +
                                      " " +
                                      (dateTimeLastSynced == null
                                          ? "never".tr()
                                          : getTimeAgo(dateTimeLastSynced)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  key: ValueKey(appStateSettings["expandedNavigationSidebar"]),
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 0, vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [refreshButton],
                  ),
                ),
        ),
      ),
    );
  }
}

DateTime? getTimeLastSynced() {
  DateTime? timeLastSynced = null;
  try {
    if (appStateSettings["lastSynced"] == null) throw ("lastSynced is null!");
    timeLastSynced = DateTime.tryParse(
      appStateSettings["lastSynced"],
    );
  } catch (e) {
    // print("Error parsing time last synced: " +
    //     e.toString());
  }
  return timeLastSynced;
}

class NavigationSidebarButtonWithNavBarIconData extends StatelessWidget {
  const NavigationSidebarButtonWithNavBarIconData({
    required this.navBarIconDataKey,
    required this.currentPageIndex,
    this.useLongLabel = false,
    super.key,
  });
  final String navBarIconDataKey;
  final int currentPageIndex;
  final bool useLongLabel;
  @override
  Widget build(BuildContext context) {
    return NavigationSidebarButton(
      icon: navBarIconsData[navBarIconDataKey]!.iconData,
      label: useLongLabel == true
          ? navBarIconsData[navBarIconDataKey]!.labelLong.tr()
          : navBarIconsData[navBarIconDataKey]!.label.tr(),
      isSelected:
          navBarIconsData[navBarIconDataKey]!.navigationIndexedStackIndex ==
              currentPageIndex,
      onTap: () {
        pageNavigationFrameworkKey.currentState!.changePage(
            navBarIconsData[navBarIconDataKey]!.navigationIndexedStackIndex,
            switchNavbar: true);
      },
      iconScale: navBarIconsData[navBarIconDataKey]?.iconScale ?? 1,
    );
  }
}

class NavigationSidebarButton extends StatelessWidget {
  const NavigationSidebarButton({
    super.key,
    required this.icon,
    this.iconScale = 1,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing = const SizedBox.shrink(),
    this.popRoutes = true,
  });

  final IconData icon;
  final double iconScale;
  final String label;
  final bool isSelected;
  final Widget trailing;
  final Function() onTap;
  final bool popRoutes;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Transform.scale(
      scale: iconScale,
      child: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.secondary,
      ),
    );
    return Padding(
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 5, vertical: 1),
      child: AnimatedSwitcher(
        duration: appStateSettings["appAnimations"] != AppAnimations.all.index
            ? Duration.zero
            : Duration(milliseconds: 250),
        child: Tappable(
          key: ValueKey(isSelected),
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 50,
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          onTap: () {
            if (popRoutes) {
              // pop all routes without animation
              navigatorKey.currentState!.pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        SizedBox(),
                    transitionDuration: Duration(seconds: 0),
                  ),
                  (route) => route.isFirst);
              navigatorKey.currentState!.pop();
            }
            onTap();
          },
          child: AnimatedSizeSwitcher(
            sizeDuration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 800),
            switcherDuration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 250),
            child: appStateSettings["expandedNavigationSidebar"]
                ? Padding(
                    key:
                        ValueKey(appStateSettings["expandedNavigationSidebar"]),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        iconWidget,
                        SizedBox(width: 15),
                        Expanded(
                          child: TextFont(
                            text: label.capitalizeFirst,
                            fontSize: 16,
                          ),
                        ),
                        trailing,
                      ],
                    ),
                  )
                : Padding(
                    key:
                        ValueKey(appStateSettings["expandedNavigationSidebar"]),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 0,
                      vertical: 13,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [iconWidget],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class EditDataButtons extends StatefulWidget {
  const EditDataButtons({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  State<EditDataButtons> createState() => _EdiDatatButtonsState();
}

class _EdiDatatButtonsState extends State<EditDataButtons> {
  bool showEditDataButtons = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavigationSidebarButton(
          icon: Icons.edit_document,
          label: "edit-data".tr(),
          isSelected: showEditDataButtons == false &&
              [9, 10, 11, 12].contains(widget.selectedIndex),
          onTap: () {
            setState(() {
              showEditDataButtons = !showEditDataButtons;
            });
          },
          popRoutes: false,
          trailing: AnimatedRotation(
            duration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 600),
            curve: Curves.easeInOutCubicEmphasized,
            turns: showEditDataButtons ? 0 : -0.5,
            child: Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.arrow_drop_up_outlined
                  : Icons.arrow_drop_up_rounded,
            ),
          ),
        ),
        AnimatedPadding(
          duration: appStateSettings["appAnimations"] != AppAnimations.all.index
              ? Duration.zero
              : Duration(milliseconds: 1500),
          curve: Curves.easeInOutCubicEmphasized,
          padding: EdgeInsetsDirectional.only(
              start: appStateSettings["expandedNavigationSidebar"] ? 8 : 0),
          child: AnimatedSizeSwitcher(
            sizeDuration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 800),
            switcherDuration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 250),
            child: !showEditDataButtons
                ? Container(key: ValueKey(1))
                : Column(
                    children: [
                      NavigationSidebarButtonWithNavBarIconData(
                        navBarIconDataKey: "accountDetails",
                        currentPageIndex: widget.selectedIndex,
                        useLongLabel: true,
                      ),
                      NavigationSidebarButtonWithNavBarIconData(
                        navBarIconDataKey: "budgetDetails",
                        currentPageIndex: widget.selectedIndex,
                        useLongLabel: true,
                      ),
                      NavigationSidebarButtonWithNavBarIconData(
                        navBarIconDataKey: "categoriesDetails",
                        currentPageIndex: widget.selectedIndex,
                        useLongLabel: true,
                      ),
                      NavigationSidebarButtonWithNavBarIconData(
                        navBarIconDataKey: "titlesDetails",
                        currentPageIndex: widget.selectedIndex,
                        useLongLabel: true,
                      ),
                      NavigationSidebarButtonWithNavBarIconData(
                        navBarIconDataKey: "goalsDetails",
                        currentPageIndex: widget.selectedIndex,
                        useLongLabel: true,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
