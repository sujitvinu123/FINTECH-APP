import 'package:animations/animations.dart';
import 'package:budget/colors.dart';
import 'package:budget/database/initializeDefaultDatabase.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/aboutPage.dart';
import 'package:budget/pages/accountsPage.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addCategoryPage.dart';
import 'package:budget/pages/addObjectivePage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/pages/budgetsListPage.dart';
import 'package:budget/pages/editAssociatedTitlesPage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/pages/editObjectivesPage.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'package:budget/pages/homePage/homePage.dart';
import 'package:budget/pages/notificationsPage.dart';
import 'package:budget/pages/objectivesListPage.dart';
import 'package:budget/pages/onBoardingPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/pages/subscriptionsPage.dart';
import 'package:budget/pages/transactionsListPage.dart';
import 'package:budget/pages/upcomingOverdueTransactionsPage.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/pages/creditDebtTransactionsPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/struct/quickActions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/shareBudget.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/bottomNavBar.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/iconButtonScaled.dart';
import 'package:budget/widgets/importDB.dart';
import 'package:budget/widgets/moreIcons.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/notificationsSettings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/ratingPopup.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/selectChips.dart';
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
import 'package:budget/widgets/showChangelog.dart';
import 'package:budget/struct/initializeNotifications.dart';
import 'package:budget/widgets/globalLoadingProgress.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/struct/upcomingTransactionsFunctions.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:budget/widgets/transactionEntry/transactionLabel.dart';
import 'package:budget/widgets/util/checkWidgetLaunch.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:provider/provider.dart';
// import 'package:feature_discovery/feature_discovery.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handles onboarding too!
class InitialPageRouteNavigator extends StatelessWidget {
  const InitialPageRouteNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AnimatedSwitcher(
          duration: Duration(milliseconds: 1200),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inAnimation =
                Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
                    .animate(animation);
            final outAnimation =
                Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
                    .animate(animation);

            if (child.key == ValueKey("Onboarding")) {
              return ClipRect(
                child: SlideTransition(
                  position: inAnimation,
                  child: child,
                ),
              );
            } else {
              return ClipRect(
                child: SlideTransition(position: outAnimation, child: child),
              );
            }
          },
          child: appStateSettings["hasOnboarded"] != true
              ? OnBoardingPage(key: ValueKey("Onboarding"))
              : PageNavigationFrameworkSafeArea(
                  child: PageNavigationFramework(
                    key: pageNavigationFrameworkKey,
                    widthSideNavigationBar: getWidthNavigationSidebar(context),
                  ),
                ),
        ),
      ),
    );
  }
}

class PageNavigationFrameworkSafeArea extends StatelessWidget {
  const PageNavigationFrameworkSafeArea({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double rightPaddingSafeArea = MediaQuery.paddingOf(context).right;
    bool hasRightSafeArea = rightPaddingSafeArea > 0;
    double leftPaddingSafeArea = MediaQuery.paddingOf(context).left;
    bool hasLeftSafeArea =
        leftPaddingSafeArea > 0 && getIsFullScreen(context) == false;

    // Only enable left safe area if no navigation sidebar
    return Stack(
      children: [
        hasRightSafeArea || hasLeftSafeArea
            ? Container(
                color: Theme.of(context).colorScheme.background,
              )
            : SizedBox.shrink(),
        hasRightSafeArea || hasLeftSafeArea
            ? Padding(
                padding: EdgeInsets.only(
                  right: hasRightSafeArea ? rightPaddingSafeArea : 0,
                  left: hasLeftSafeArea ? leftPaddingSafeArea : 0,
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      right: hasRightSafeArea
                          ? Radius.circular(
                              getPlatform() == PlatformOS.isIOS ? 10 : 20)
                          : Radius.circular(0),
                      left: hasLeftSafeArea
                          ? Radius.circular(
                              getPlatform() == PlatformOS.isIOS ? 10 : 20)
                          : Radius.circular(0),
                    ),
                    child: child),
              )
            : child,
        hasRightSafeArea
            ? Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: rightPaddingSafeArea,
                  color: Theme.of(context).colorScheme.background,
                ),
              )
            : SizedBox.shrink(),
        hasLeftSafeArea
            ? Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: leftPaddingSafeArea,
                  color: Theme.of(context).colorScheme.background,
                ),
              )
            : SizedBox.shrink(),
        // Gradient fade to right overflow, disabled for now
        // because many pages have full screen elements/banners etc
        // hasRightSafeArea
        //     ? Padding(
        //         padding: EdgeInsets.only(
        //             right: rightPaddingSafeArea),
        //         child: Align(
        //           alignment: Alignment.centerRight,
        //           child: Container(
        //             width: 12,
        //             foregroundDecoration: BoxDecoration(
        //               gradient: LinearGradient(
        //                 colors: [
        //                   Theme.of(context)
        //                       .colorScheme.background
        //                       .withOpacity(0.0),
        //                   Theme.of(context).colorScheme.background,
        //                 ],
        //                 begin: Alignment.centerLeft,
        //                 end: Alignment.centerRight,
        //                 stops: [0.1, 1],
        //               ),
        //             ),
        //           ),
        //         ),
        //       )
        //     : SizedBox.shrink(),
      ],
    );
  }
}

class HandleWillPopScope extends StatelessWidget {
  const HandleWillPopScope({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        bool popResult = await maybePopRoute(navigatorKey.currentContext);
        if (popResult == true) return false;

        // Deselect selected transactions
        int notEmpty = 0;
        for (String key in globalSelectedID.value.keys) {
          if (globalSelectedID.value[key]?.isNotEmpty == true) notEmpty++;
          globalSelectedID.value[key] = [];
        }
        globalSelectedID.notifyListeners();

        // Allow the back button to exit the app when on home
        if (notEmpty <= 0) {
          if (pageNavigationFrameworkKey.currentState?.currentPage == 0) {
            return true;
          } else {
            // Allow back button deselect a selected category first on All Spending page
            if (pageNavigationFrameworkKey.currentState?.currentPage == 7 &&
                categoryIsSelectedOnAllSpending) {
              return true;
            }
            pageNavigationFrameworkKey.currentState?.changePage(0);
          }
        }
        return false;
      },
    );
  }
}

class PageNavigationFramework extends StatefulWidget {
  const PageNavigationFramework(
      {Key? key, required this.widthSideNavigationBar})
      : super(key: key);
  final double widthSideNavigationBar;

  //PageNavigationFramework.changePage(context, 0);
  static void changePage(BuildContext context, page,
      {bool switchNavbar = false}) {
    context
        .findAncestorStateOfType<PageNavigationFrameworkState>()!
        .changePage(page, switchNavbar: switchNavbar);
  }

  @override
  State<PageNavigationFramework> createState() =>
      PageNavigationFrameworkState();
}

//can also do GlobalKey<dynamic> for private state classes, but bad practice and no autocomplete
GlobalKey<HomePageState> homePageStateKey = GlobalKey();
GlobalKey<TransactionsListPageState> transactionsListPageStateKey = GlobalKey();
GlobalKey<BudgetsListPageState> budgetsListPageStateKey = GlobalKey();
GlobalKey<MoreActionsPageState> settingsPageStateKey = GlobalKey();
GlobalKey<SettingsPageFrameworkState> settingsPageFrameworkStateKey =
    GlobalKey();
GlobalKey<SubscriptionsPageState> subscriptionsPageStateKey = GlobalKey();
GlobalKey<WalletDetailsPageState> walletDetailsAllSpendingPageStateKey =
    GlobalKey();
GlobalKey<ObjectivesListPageState> objectivesListPageStateKey = GlobalKey();
GlobalKey<UpcomingOverdueTransactionsState>
    upcomingOverdueTransactionsStateKey = GlobalKey();
GlobalKey<CreditDebtTransactionsState> creditDebtTransactionsKey = GlobalKey();
GlobalKey<ProductsState> purchasesStateKey = GlobalKey();
GlobalKey<AccountsPageState> accountsPageStateKey = GlobalKey();
GlobalKey<GoogleAccountLoginButtonState> settingsGoogleAccountLoginButtonKey =
    GlobalKey();
GlobalKey<NavigationSidebarState> sidebarStateKey = GlobalKey();
GlobalKey<GlobalLoadingProgressState> loadingProgressKey = GlobalKey();
GlobalKey<GlobalLoadingIndeterminateState> loadingIndeterminateKey =
    GlobalKey();
GlobalKey<GlobalSnackbarState> snackbarKey = GlobalKey();
GlobalKey<RenderHomePageWidgetsState> renderHomePageWidgetsKey = GlobalKey();

late bool entireAppLoaded;
bool runningCloudFunctions = false;
bool errorSigningInDuringCloud = false;
Future<bool> runAllCloudFunctions(BuildContext context,
    {bool forceSignIn = false}) async {
  print("Running All Cloud Functions");
  runningCloudFunctions = true;
  errorSigningInDuringCloud = false;
  try {
    loadingIndeterminateKey.currentState?.setVisibility(true);
    await runForceSignIn(context);
    await syncData(context);
    if (appStateSettings["emailScanningPullToRefresh"] ||
        entireAppLoaded == false) {
      loadingIndeterminateKey.currentState?.setVisibility(true);
      await parseEmailsInBackground(context, forceParse: true);
    }
    loadingIndeterminateKey.currentState?.setVisibility(true);
    await syncPendingQueueOnServer(); //sync before download
    loadingIndeterminateKey.currentState?.setVisibility(true);
    await getCloudBudgets();
    loadingIndeterminateKey.currentState?.setVisibility(true);
    await createBackupInBackground(context);
    loadingIndeterminateKey.currentState?.setVisibility(true);
    await getExchangeRates();
  } catch (e) {
    print("Error running sync functions on load: " + e.toString());
    loadingIndeterminateKey.currentState?.setVisibility(false);
    runningCloudFunctions = false;
    canSyncData = true;
    if (e is DetailedApiRequestError &&
            e.status == 401 &&
            forceSignIn == true ||
        e is PlatformException) {
      // Request had invalid authentication credentials. Try logging out and back in.
      // This stems from silent sign-in not providing the credentials for GDrive API for e.g.
      await refreshGoogleSignIn();
      runAllCloudFunctions(context);
    } else {
      if (kIsWeb && appStateSettings["webForceLoginPopupOnLaunch"] == true) {
        signOutGoogle();
      }
    }
    return false;
  }
  loadingIndeterminateKey.currentState?.setVisibility(false);
  Future.delayed(Duration(milliseconds: 2000), () {
    runningCloudFunctions = false;
  });
  errorSigningInDuringCloud = false;
  return true;
}

class PageNavigationFrameworkState extends State<PageNavigationFramework> {
  final List<Widget> pages = [
    HomePage(key: homePageStateKey), // 0
    TransactionsListPage(key: transactionsListPageStateKey), //1
    BudgetsListPage(key: budgetsListPageStateKey, enableBackButton: false), //2
    MoreActionsPage(key: settingsPageStateKey), //3
  ];
  final List<Widget> pagesExtended = [
    MoreActionsPage(), //4
    SubscriptionsPage(key: subscriptionsPageStateKey), //5
    NotificationsPage(), //6
    WalletDetailsPage(
        key: walletDetailsAllSpendingPageStateKey, wallet: null), //7
    AccountsPage(key: accountsPageStateKey), // 8
    EditWalletsPage(), //9
    EditBudgetPage(), //10
    EditCategoriesPage(), //11
    EditAssociatedTitlesPage(), //12
    AboutPage(), //13
    ObjectivesListPage(key: objectivesListPageStateKey, backButton: false), //14
    EditObjectivesPage(objectiveType: ObjectiveType.goal), //15
    UpcomingOverdueTransactions(
        key: upcomingOverdueTransactionsStateKey,
        overdueTransactions: null), //16
    CreditDebtTransactions(key: creditDebtTransactionsKey, isCredit: null), //17
  ];

  late int currentPage = widget.widthSideNavigationBar <= 0
      ? (int.tryParse(navBarIconsData[appStateSettings["customNavBarShortcut0"]]
                  ?.navigationIndexedStackIndex
                  .toString() ??
              "") ??
          0)
      : 0;
  int previousPage = 0;

  void changePage(int page, {bool switchNavbar = true}) {
    if (switchNavbar) {
      sidebarStateKey.currentState?.setSelectedIndex(page);
    }
    setState(() {
      previousPage = currentPage;
      currentPage = page;
    });
    if (appStateSettings["tabNavigationHapticFeedback"] == true) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void initState() {
    super.initState();

    // Functions to run after entire UI loaded
    Future.delayed(Duration.zero, () async {
      sidebarStateKey.currentState?.setSelectedIndex(currentPage);

      SystemChrome.setSystemUIOverlayStyle(getSystemUiOverlayStyle(
          Theme.of(context).extension<AppColors>(),
          Theme.of(context).brightness));

      bool isDatabaseCorruptedPopupShown = openDatabaseCorruptedPopup(context);
      if (isDatabaseCorruptedPopupShown) return;

      await initializeNotificationsPlatform();

      bool isChangelogShown = showChangelog(context);
      bool isRatingPopupShown = false;
      if (isChangelogShown == false) {
        isRatingPopupShown = openRatingPopupCheck(context);
      }

      await setDailyNotifications(context);
      await initializeDefaultDatabase();
      runNotificationPayLoads(context);
      runQuickActionsPayLoads(context);
      initializeLocalizedMonthNames();
      initializeStoreAndPurchases(
          context: context, popRouteWithPurchase: false);

      if (entireAppLoaded == false) {
        await runAllCloudFunctions(context);
      }

      // Do this after cloud functions attempt (i.e. if user is not signed in we can show it)
      if (isRatingPopupShown == false && isChangelogShown == false) {
        openBackupReminderPopupCheck(context);
      }

      // Mark subscriptions as paid AFTER syncing with cloud
      // Maybe another device already marked them as paid
      await markSubscriptionsAsPaid(context);
      await markUpcomingAsPaid();

      // Should do this after syncing and after the subscriptions/upcoming transactions auto paid for
      // The upcoming transactions may have been modified after a sync
      await setUpcomingNotifications(context);

      await database.deleteWanderingTransactions();
      await database.deleteWanderingTitles();
      await database.fixDuplicateAssociatedTitles();

      entireAppLoaded = true;

      print("Entire app loaded");

      database.watchAllForAutoSync().listen((event) {
        // Must be logged in to perform an automatic sync - googleUser != null
        // If we remove this, it will ask the user to login though - but it can be annoying
        // Users can visually see the last time of sync, especially on web where sign-in is not automatic,
        // so it shouldn't be an issue
        if (runningCloudFunctions == false && googleUser != null) {
          createSyncBackup(changeMadeSync: true);
        }
      });

      if (kIsWeb) {
        // On web, disable the browser's context menu since this example uses a custom
        // Flutter-rendered context menu.
        // Refer here: https://api.flutter.dev/flutter/material/TextField/contextMenuBuilder.html
        BrowserContextMenu.disableContextMenu();
      }
    });

    // SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
    //   FeatureDiscovery.discoverFeatures(
    //     context,
    //     const <String>{
    //       'add_transaction_button',
    //     },
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        resizeToAvoidBottomInset: false,
        body: FadeIndexedStack(
          children: [...pages, ...pagesExtended],
          index: currentPage,
          duration: !kIsWeb
              ? Duration.zero
              : appStateSettings["batterySaver"]
                  ? Duration.zero
                  : Duration(milliseconds: 300),
        ),
        extendBody: false,
        bottomNavigationBar: BottomNavBar(
          currentNavigationStackedIndex: currentPage,
          onChanged: (index) {
            changePage(index);
          },
        ),
      ),
      Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: getHeightNavigationSidebar(context) + 15,
            end: 15,
          ),
          child: AnimateFAB(
            key: ValueKey(1),
            fab: AddFAB(
              tooltip: "add-transaction".tr(),
              openPage: AddTransactionPage(
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
              ),
            ),
            condition: [0, 1, 2, 14].contains(currentPage),
          ),
        ),
      ),
    ]);
  }
}

class AddMoreThingsPopup extends StatelessWidget {
  const AddMoreThingsPopup({super.key});

  createTransactionFromCommon({
    required BuildContext context,
    required TransactionWithCount transactionWithCount,
    required Map<String, TransactionCategory> categoriesIndexed,
    double? customAmount,
  }) async {
    popRoute(context);
    await duplicateTransaction(
      context,
      transactionWithCount.transaction.transactionPk,
      showDuplicatedMessage: false,
      useCurrentDate: true,
      customAmount: customAmount,
    );
    openSnackbar(
      SnackbarMessage(
        icon: navBarIconsData["transactions"]!.iconData,
        title: "created-transaction".tr(),
        description: getTransactionLabelSync(
          transactionWithCount.transaction,
          categoriesIndexed[transactionWithCount.transaction.categoryFk],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5),
        AddThing(
          iconData: navBarIconsData["accountDetails"]!.iconData,
          title: "account".tr(),
          openPage: AddWalletPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          widgetAfter: SelectChips(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 13),
            items: [
              if (Provider.of<AllWallets>(context).list.length > 1)
                "transfer-balance",
              "correct-total-balance"
            ],
            getSelected: (_) {
              return false;
            },
            onSelected: (String selection) async {
              if (selection == "transfer-balance") {
                popRoute(context);
                openBottomSheet(
                  context,
                  fullSnap: true,
                  TransferBalancePopup(
                    allowEditWallet: true,
                    wallet: Provider.of<AllWallets>(context, listen: false)
                        .indexedByPk[appStateSettings["selectedWalletPk"]]!,
                  ),
                );
              } else if (selection == "correct-total-balance") {
                TransactionWallet? wallet =
                    Provider.of<AllWallets>(context, listen: false)
                        .indexedByPk[appStateSettings["selectedWalletPk"]];
                if (Provider.of<AllWallets>(context, listen: false)
                        .list
                        .length >
                    1) {
                  wallet = await selectWalletPopup(
                    context,
                    allowEditWallet: true,
                  );
                }
                if (wallet != null) {
                  popRoute(context);
                  openBottomSheet(
                    context,
                    fullSnap: true,
                    CorrectBalancePopup(wallet: wallet),
                  );
                }
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  selection == "transfer-balance"
                      ? appStateSettings["outlinedIcons"]
                          ? Icons.compare_arrows_outlined
                          : Icons.compare_arrows_rounded
                      : appStateSettings["outlinedIcons"]
                          ? Icons.library_add_outlined
                          : Icons.library_add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        StreamBuilder<Map<String, TransactionCategory>>(
          stream: database.watchAllCategoriesIndexed(),
          builder: (context, snapshotCategories) {
            Map<String, TransactionCategory> categoriesIndexed =
                snapshotCategories.data ?? {};
            return StreamBuilder<List<TransactionWithCount>>(
              stream: database.getCommonTransactions(),
              builder: (context, snapshot) {
                List<TransactionWithCount> commonTransactions =
                    snapshot.data ?? [];
                if (commonTransactions.length <= 0) {
                  return AddThing(
                    iconData: navBarIconsData["transactions"]!.iconData,
                    title: "transaction".tr(),
                    openPage: AddTransactionPage(
                        routesToPopAfterDelete: RoutesToPopAfterDelete.None),
                  );
                }
                return AddThing(
                  infoButton: IconButtonScaled(
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.info_outlined
                        : Icons.info_outline_rounded,
                    iconSize: 14,
                    scale: 1.8,
                    padding: EdgeInsetsDirectional.all(5),
                    onTap: () {
                      openPopup(
                        context,
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.dynamic_feed_outlined
                            : Icons.dynamic_feed_rounded,
                        title: "most-common-transactions".tr(),
                        description:
                            "most-common-transactions-description".tr(),
                        onSubmit: () {
                          popRoute(context);
                        },
                        onSubmitLabel: "ok".tr(),
                      );
                    },
                  ),
                  iconData: navBarIconsData["transactions"]!.iconData,
                  title: "transaction".tr(),
                  openPage: AddTransactionPage(
                      routesToPopAfterDelete: RoutesToPopAfterDelete.None),
                  widgetAfter: SelectChips(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 13),
                    items: commonTransactions,
                    getSelected: (_) {
                      return false;
                    },
                    onLongPress:
                        (TransactionWithCount transactionWithCount) async {
                      double amount = await openBottomSheet(
                        context,
                        fullSnap: true,
                        PopupFramework(
                          title: "enter-amount".tr(),
                          underTitleSpace: false,
                          child: SelectAmount(
                            setSelectedAmount: (_, __) {},
                            nextLabel: "set-amount".tr(),
                            popWithAmount: true,
                          ),
                        ),
                      );
                      amount = amount.abs() *
                          (transactionWithCount.transaction.income ? 1 : -1);
                      createTransactionFromCommon(
                        context: context,
                        transactionWithCount: transactionWithCount,
                        categoriesIndexed: categoriesIndexed,
                        customAmount: amount,
                      );
                    },
                    onSelected:
                        (TransactionWithCount transactionWithCount) async {
                      createTransactionFromCommon(
                        context: context,
                        transactionWithCount: transactionWithCount,
                        categoriesIndexed: categoriesIndexed,
                      );
                    },
                    getLabel: (TransactionWithCount transactionWithCount) {
                      // Keep the currency displayed in the primary currency
                      // Therefore no need to convert using the code below...
                      //
                      // double amountInPrimary =
                      //     transactionWithCount.transaction.amount *
                      //         (amountRatioToPrimaryCurrencyGivenPk(
                      //             Provider.of<AllWallets>(context),
                      //             transactionWithCount.transaction.walletFk));
                      // convertToMoney(
                      //       Provider.of<AllWallets>(context),
                      //       amountInPrimary,
                      //       currencyKey: Provider.of<AllWallets>(context)
                      //           .indexedByPk[
                      //               transactionWithCount.transaction.walletFk]
                      //           ?.currency,
                      //     )
                      return getTransactionLabelSync(
                            transactionWithCount.transaction,
                            categoriesIndexed[
                                transactionWithCount.transaction.categoryFk],
                          ) +
                          " " +
                          "(" +
                          convertToMoney(
                            Provider.of<AllWallets>(context),
                            transactionWithCount.transaction.amount,
                            currencyKey: Provider.of<AllWallets>(context)
                                .indexedByPk[
                                    transactionWithCount.transaction.walletFk]
                                ?.currency,
                          ) +
                          ")";
                    },
                    getCustomBorderColor:
                        (TransactionWithCount transactionWithCount) {
                      return dynamicPastel(
                        context,
                        lightenPastel(
                          HexColor(
                            categoriesIndexed[
                                    transactionWithCount.transaction.categoryFk]
                                ?.colour,
                            defaultColor: Theme.of(context).colorScheme.primary,
                          ),
                          amount: 0.3,
                        ),
                        amount: 0.4,
                      );
                    },
                    getAvatar: (TransactionWithCount transactionWithCount) {
                      return LayoutBuilder(builder: (context, constraints) {
                        return CategoryIcon(
                          categoryPk: "-1",
                          category: categoriesIndexed[
                              transactionWithCount.transaction.categoryFk],
                          emojiSize: constraints.maxWidth * 0.73,
                          emojiScale: 1.2,
                          size: constraints.maxWidth,
                          sizePadding: 0,
                          noBackground: true,
                          canEditByLongPress: false,
                          margin: EdgeInsetsDirectional.zero,
                        );
                      });
                    },
                  ),
                );
              },
            );
          },
        ),
        AddThing(
          iconData: navBarIconsData["loans"]!.iconData,
          title: navBarIconsData["loans"]!.label.tr(),
          openPage: AddObjectivePage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            objectiveType: ObjectiveType.loan,
          ),
          widgetAfter: SelectChips(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 13),
            items: ["long-term", "one-time"],
            getSelected: (_) {
              return false;
            },
            // extraWidget: SelectChipsAddButtonExtraWidget(
            //   openPage: AddObjectivePage(
            //     routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            //   ),
            //   shouldPushRoute: true,
            //   popCurrentRoute: true,
            // ),
            // extraWidgetAtBeginning: true,
            onSelected: (String selection) async {
              popRoute(context);
              if (selection == "long-term") {
                pushRoute(
                  context,
                  AddObjectivePage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                    objectiveType: ObjectiveType.loan,
                  ),
                );
              } else {
                pushRoute(
                  context,
                  AddTransactionPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                    selectedType: TransactionSpecialType.credit,
                  ),
                );
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  selection == "long-term"
                      ? appStateSettings["outlinedIcons"]
                          ? Icons.av_timer_outlined
                          : Icons.av_timer_rounded
                      : appStateSettings["outlinedIcons"]
                          ? Icons.event_available_outlined
                          : Icons.event_available_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        AddThing(
          iconData: navBarIconsData["goals"]!.iconData,
          title: "goal".tr(),
          openPage: AddObjectivePage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          widgetAfter: SelectChips(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 13),
            items: ["installment"],
            getSelected: (_) {
              return false;
            },
            // extraWidget: SelectChipsAddButtonExtraWidget(
            //   openPage: AddObjectivePage(
            //     routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            //   ),
            //   shouldPushRoute: true,
            //   popCurrentRoute: true,
            // ),
            // extraWidgetAtBeginning: true,
            onSelected: (String selection) async {
              if (navigatorKey.currentContext == null) {
                startCreatingInstallment(context: context);
              } else {
                popRoute(context);
                startCreatingInstallment(context: navigatorKey.currentContext!);
              }
            },
            getLabel: (String selection) {
              return selection.tr();
            },
            getAvatar: (String selection) {
              return LayoutBuilder(builder: (context2, constraints) {
                return Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.punch_clock_outlined
                      : Icons.punch_clock_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: constraints.maxWidth,
                );
              });
            },
          ),
        ),
        AddThing(
          iconData: navBarIconsData["budgets"]!.iconData,
          title: "budget".tr(),
          openPage: AddBudgetPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
          iconScale: navBarIconsData["budgets"]!.iconScale,
        ),
        AddThing(
          iconData: navBarIconsData["categoriesDetails"]!.iconData,
          title: "category".tr(),
          openPage: AddCategoryPage(
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
        ),
      ],
    );
  }
}

class AddThing extends StatelessWidget {
  const AddThing({
    required this.iconData,
    required this.title,
    required this.openPage,
    this.onTap,
    this.widgetAfter,
    this.infoButton,
    this.iconScale = 1,
    super.key,
  });

  final IconData iconData;
  final String title;
  final Widget openPage;
  final VoidCallback? onTap;
  final Widget? widgetAfter;
  final Widget? infoButton;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: 5,
        top: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButtonStacked(
              filled: false,
              alignStart: true,
              alignBeside: true,
              padding: widgetAfter != null
                  ? EdgeInsetsDirectional.only(
                      start: 20, end: 20, top: 20, bottom: 5)
                  : EdgeInsetsDirectional.symmetric(
                      horizontal: 20, vertical: 20),
              text: title.capitalizeFirst,
              iconData: iconData,
              iconScale: iconScale,
              onTap: () {
                if (onTap != null) {
                  onTap!();
                } else {
                  popRoute(context);
                  pushRoute(context, openPage);
                }
              },
              afterWidget: widgetAfter,
              afterWidgetPadding: widgetAfter != null
                  ? EdgeInsetsDirectional.only(bottom: 8)
                  : EdgeInsetsDirectional.zero,
              infoButton: infoButton,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimateFAB extends StatelessWidget {
  const AnimateFAB({required this.condition, required this.fab, super.key});

  final bool condition;
  final Widget fab;

  @override
  Widget build(BuildContext context) {
    if (appStateSettings["appAnimations"] != AppAnimations.all.index)
      return condition ? fab : SizedBox.shrink();
    // return AnimatedOpacity(
    //   duration: Duration(milliseconds: 400),
    //   opacity: condition ? 1 : 0,
    //   child: AnimatedScale(
    //     duration: Duration(milliseconds: 1100),
    //     scale: condition ? 1 : 0,
    //     curve: Curves.easeInOutCubicEmphasized,
    //     child: fab,
    //     alignment: Alignment(0.7, 0.7),
    //   ),
    // );
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutCubicEmphasized,
      switchOutCurve: Curves.ease,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeScaleTransitionButton(
          animation: animation,
          child: child,
          alignment: Alignment(0.7, 0.7),
        );
      },
      child: condition
          ? fab
          : Container(
              key: ValueKey(1),
              width: 50,
              height: 50,
            ),
    );
  }
}

class FadeScaleTransitionButton extends StatelessWidget {
  const FadeScaleTransitionButton({
    Key? key,
    required this.animation,
    required this.alignment,
    this.child,
  }) : super(key: key);

  final Animation<double> animation;
  final Widget? child;
  final Alignment alignment;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: const Interval(0.0, 0.7),
  );
  static final Animatable<double> _scaleInTransition = Tween<double>(
    begin: 0.30,
    end: 1.00,
  );
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0,
  );
  static final Animatable<double> _scaleOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleInTransition.animate(animation),
            child: child,
            alignment: alignment,
          ),
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleOutTransition.animate(animation),
            child: child,
            alignment: alignment,
          ),
        );
      },
      child: child,
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  FadeIndexedStackState createState() => FadeIndexedStackState();
}

class FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: LazyIndexedStack(
        index: (widget.index >= 0 && widget.index < widget.children.length)
            ? widget.index
            : 0,
        alignment: widget.alignment,
        textDirection: widget.textDirection,
        sizing: widget.sizing,
        children: widget.children,
      ),
    );
  }
}
