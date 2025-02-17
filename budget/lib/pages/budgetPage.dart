import 'dart:math';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/editBudgetLimitsPage.dart';
import 'package:budget/pages/homePage/homePageLineGraph.dart';
import 'package:budget/pages/pastBudgetsPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/spendingSummaryHelper.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/extraInfoBoxes.dart';
import 'package:budget/widgets/iconButtonScaled.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
import 'package:budget/widgets/budgetContainer.dart';
import 'package:budget/widgets/categoryEntry.dart';
import 'package:budget/widgets/categoryLimits.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/lineGraph.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/pieChart.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntries.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:budget/widgets/viewAllTransactionsButton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:async/async.dart' show StreamZip;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/countNumber.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:sliver_tools/sliver_tools.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({
    super.key,
    required this.budgetPk,
    this.dateForRange,
    this.dateForRangeIndex = 0,
    this.openedFromHistory = false,
  });
  final String budgetPk;
  final DateTime? dateForRange;
  final int dateForRangeIndex;
  final bool openedFromHistory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Budget>(
        stream: database.getBudget(budgetPk),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Color? accentColor = HexColor(snapshot.data?.colour);
            return CustomColorTheme(
              accentColor: snapshot.data?.colour == null ? null : accentColor,
              child: _BudgetPageContent(
                budget: snapshot.data!,
                dateForRange: dateForRange,
                dateForRangeIndex: dateForRangeIndex,
                openedFromHistory: openedFromHistory,
              ),
            );
          }
          return SizedBox.shrink();
        });
  }
}

class _BudgetPageContent extends StatefulWidget {
  const _BudgetPageContent({
    Key? key,
    required Budget this.budget,
    this.dateForRange,
    this.dateForRangeIndex = 0,
    this.openedFromHistory = false,
  }) : super(key: key);

  final Budget budget;
  final DateTime? dateForRange;
  final int dateForRangeIndex;
  final bool openedFromHistory;

  @override
  State<_BudgetPageContent> createState() => _BudgetPageContentState();
}

class _BudgetPageContentState extends State<_BudgetPageContent> {
  String? selectedMember = null;
  bool showAllSubcategories = appStateSettings["showAllSubcategories"] == true;
  TransactionCategory? selectedCategory =
      null; //We shouldn't always rely on this, if for example the user changes the category and we are still on this page. But for less important info and O(1) we can reference it quickly.
  GlobalKey<PieChartDisplayState> _pieChartDisplayStateKey = GlobalKey();
  bool showAllCategoriesWithCategoryLimit =
      appStateSettings["expandAllCategoriesWithSpendingLimits"] == true;
  final scrollController = ScrollController();
  late int dateForRangeIndex = widget.dateForRangeIndex;
  late DateTime dateForRange =
      widget.dateForRange == null ? DateTime.now() : widget.dateForRange!;
  bool budgetHistoryDismissedPremium = false;
  bool get isPastBudget => dateForRangeIndex != 0;
  bool get isPastBudgetButCurrentPeriod => dateForRangeIndex == 0;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (isPastBudget == true) premiumPopupPastBudgets(context);
    });
    super.initState();
  }

  void changeSelectedDateRange(int delta) async {
    int index = (dateForRangeIndex) - delta;
    if (index >= 0) {
      if (budgetHistoryDismissedPremium == false)
        budgetHistoryDismissedPremium = await premiumPopupPastBudgets(context);
      if (budgetHistoryDismissedPremium) {
        setState(() {
          dateForRangeIndex = index;
          dateForRange = getDatePastToDetermineBudgetDate(
            index,
            widget.budget,
          );
        });
      }
    }
  }

  void toggleAllSubcategories() {
    setState(() {
      showAllSubcategories = !showAllSubcategories;
    });
    Future.delayed(Duration(milliseconds: 10), () {
      _pieChartDisplayStateKey.currentState!
          .setTouchedCategoryPk(selectedCategory?.categoryPk);
    });

    updateSettings("showAllSubcategories", showAllSubcategories,
        updateGlobalState: false);
  }

  void toggleShowAllCategoriesWithCategoryLimit() {
    setState(() {
      showAllCategoriesWithCategoryLimit = !showAllCategoriesWithCategoryLimit;
      updateSettings("expandAllCategoriesWithSpendingLimits",
          showAllCategoriesWithCategoryLimit,
          updateGlobalState: false);
    });
  }

  Widget pieChart({
    required double totalSpent,
    required DateTimeRange budgetRange,
    required bool showAllSubcategories,
    required VoidCallback toggleAllSubCategories,
    required List<CategoryWithTotal> dataFilterUnassignedTransactions,
    required bool hasSubCategories,
    required Color? pageBackgroundColor,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              boxShadow: boxShadowCheck(
                boxShadowGeneral(context),
              ),
              borderRadius: BorderRadiusDirectional.circular(200)),
          child: PieChartWrapper(
            pieChartDisplayStateKey: _pieChartDisplayStateKey,
            data: dataFilterUnassignedTransactions,
            totalSpent: totalSpent,
            middleColor: pageBackgroundColor,
            setSelectedCategory: (categoryPk, category) async {
              setState(() {
                selectedCategory = category;
              });
              // If we want to select the subcategories main category when tapped
              // if (category?.mainCategoryPk != null) {
              //   TransactionCategory mainCategory = await database
              //       .getCategoryInstance(category!.mainCategoryPk!);
              //   setState(() {
              //     selectedCategory = mainCategory;
              //   });
              // } else {
              //   setState(() {
              //     selectedCategory = category;
              //   });
              // }
            },
          ),
        ),
        PieChartOptions(
          isIncomeBudget: widget.budget.income == true,
          hasSubCategories: hasSubCategories,
          selectedCategory: selectedCategory,
          onClearSelection: () {
            setState(() {
              selectedCategory = null;
            });
            _pieChartDisplayStateKey.currentState?.setTouchedIndex(-1);
          },
          onEditSpendingGoals: () {
            pushRoute(
              context,
              EditBudgetLimitsPage(
                budget: widget.budget,
              ),
            );
          },
          showAllSubcategories: showAllSubcategories,
          toggleAllSubCategories: toggleAllSubCategories,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double budgetAmount = budgetAmountToPrimaryCurrency(
        Provider.of<AllWallets>(context, listen: true), widget.budget);
    DateTimeRange budgetRange = getBudgetDate(widget.budget, dateForRange);
    String pageId = budgetRange.start.millisecondsSinceEpoch.toString() +
        widget.budget.name +
        budgetRange.end.millisecondsSinceEpoch.toString() +
        widget.budget.budgetPk;
    Color? pageBackgroundColor =
        Theme.of(context).brightness == Brightness.dark &&
                appStateSettings["forceFullDarkBackground"]
            ? Colors.black
            : appStateSettings["materialYou"]
                ? dynamicPastel(context, Theme.of(context).colorScheme.primary,
                    amount: 0.92)
                : null;
    bool showIncomeExpenseIcons = widget.budget.budgetTransactionFilters == null
        ? true
        : widget.budget.budgetTransactionFilters
                    ?.contains(BudgetTransactionFilters.includeIncome) ==
                true
            ? true
            : false;
    final double todayPercent = getPercentBetweenDates(
      budgetRange,
      //dateForRange,
      DateTime.now(),
    );
    String startDateString = getWordedDateShort(budgetRange.start);
    String endDateString = getWordedDateShort(budgetRange.end);
    String timeRangeString = startDateString == endDateString
        ? startDateString
        : startDateString + " – " + endDateString;
    bool showingSelectedPeriodAppBar = widget.openedFromHistory == true;
    return WillPopScope(
      onWillPop: () async {
        if ((globalSelectedID.value[pageId] ?? []).length > 0) {
          globalSelectedID.value[pageId] = [];
          globalSelectedID.notifyListeners();
          return false;
        } else {
          return true;
        }
      },
      child: PageFramework(
        belowAppBarPaddingWhenCenteredTitleSmall: 0,
        subtitle: StreamBuilder<List<CategoryWithTotal>>(
          stream:
              database.watchTotalSpentInEachCategoryInTimeRangeFromCategories(
            allWallets: Provider.of<AllWallets>(context),
            start: budgetRange.start,
            end: budgetRange.end,
            categoryFks: widget.budget.categoryFks,
            categoryFksExclude: widget.budget.categoryFksExclude,
            budgetTransactionFilters: widget.budget.budgetTransactionFilters,
            memberTransactionFilters: widget.budget.memberTransactionFilters,
            member: selectedMember,
            onlyShowTransactionsBelongingToBudgetPk:
                widget.budget.sharedKey != null ||
                        widget.budget.addedTransactionsOnly == true
                    ? widget.budget.budgetPk
                    : null,
            budget: widget.budget,
          ),
          builder: (context, snapshot) {
            double totalSpent = 0;
            if (snapshot.hasData) {
              snapshot.data!.forEach((category) {
                totalSpent = totalSpent + category.total;
              });
              totalSpent = totalSpent * determineBudgetPolarity(widget.budget);
            }

            if (snapshot.hasData) {
              return TotalSpent(
                budget: widget.budget,
                totalSpent: totalSpent,
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
        subtitleAlignment: AlignmentDirectional.bottomStart,
        subtitleSize: 10,
        backgroundColor: pageBackgroundColor,
        listID: pageId,
        floatingActionButton: AnimateFABDelayed(
          fab: AddFAB(
            tooltip: "add-transaction".tr(),
            openPage: AddTransactionPage(
              selectedBudget: widget.budget.sharedKey != null ||
                      widget.budget.addedTransactionsOnly == true
                  ? widget.budget
                  : null,
              routesToPopAfterDelete: RoutesToPopAfterDelete.One,
            ),
            color: Theme.of(context).colorScheme.secondary,
            colorIcon: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        actions: [
          CustomPopupMenuButton(
            showButtons: enableDoubleColumn(context),
            keepOutFirst: true,
            items: [
              DropdownItemMenu(
                id: "edit-budget",
                label: "edit-budget".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.edit_outlined
                    : Icons.edit_rounded,
                action: () {
                  pushRoute(
                    context,
                    AddBudgetPage(
                      budget: widget.budget,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                    ),
                  );
                },
              ),
              if (widget.budget.reoccurrence != BudgetReoccurence.custom &&
                  isPastBudget == false &&
                  isPastBudgetButCurrentPeriod == false)
                DropdownItemMenu(
                  id: "budget-history",
                  label: "budget-history".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.history_outlined
                      : Icons.history_rounded,
                  action: () {
                    pushRoute(
                      context,
                      PastBudgetsPage(budgetPk: widget.budget.budgetPk),
                    );
                  },
                ),
              // DropdownItemMenu(
              //   id: "spending-goals",
              //   label: widget.budget.income == true
              //    ? "saving-goals".tr()
              //    : "spending-goals".tr(),
              //   icon: appStateSettings["outlinedIcons"]
              //       ? Icons.fact_check_outlined
              //       : Icons.fact_check_rounded,
              //   action: () {
              //     pushRoute(
              //       context,
              //       EditBudgetLimitsPage(
              //         budget: widget.budget,
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ],
        title: widget.budget.name,
        capitalizeTitle: false,
        appBarBackgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        appBarBackgroundColorStart:
            Theme.of(context).colorScheme.secondaryContainer,
        textColor: getColor(context, "black"),
        dragDownToDismiss: true,
        scrollController: scrollController,
        slivers: [
          StreamBuilder<List<CategoryWithTotal>>(
              stream: database.watchAllCategoryLimitsInBudgetWithCategory(
                  widget.budget.budgetPk),
              builder: (context, allCategoryLimitsSnap) {
                return StreamBuilder<List<CategoryWithTotal>>(
                  stream: database
                      .watchTotalSpentInEachCategoryInTimeRangeFromCategories(
                    allWallets: Provider.of<AllWallets>(context),
                    start: budgetRange.start,
                    end: budgetRange.end,
                    categoryFks: widget.budget.categoryFks,
                    categoryFksExclude: widget.budget.categoryFksExclude,
                    budgetTransactionFilters:
                        widget.budget.budgetTransactionFilters,
                    memberTransactionFilters:
                        widget.budget.memberTransactionFilters,
                    member: selectedMember,
                    onlyShowTransactionsBelongingToBudgetPk:
                        widget.budget.sharedKey != null ||
                                widget.budget.addedTransactionsOnly == true
                            ? widget.budget.budgetPk
                            : null,
                    budget: widget.budget,
                    // Set to countUnassignedTransactons: false for the pie chart
                    //  includeAllSubCategories: showAllSubcategories,
                    // If implementing pie chart summary for subcategories, also need to implement ability to tap a subcategory from the pie chart
                    countUnassignedTransactions: true,
                    includeAllSubCategories: true,
                  ),
                  builder: (context, categoryWithTotalsSnap) {
                    //Ensure the main category always gets bundled in
                    List<CategoryWithTotal> allCategoryLimits =
                        (allCategoryLimitsSnap.data ?? []).where((c) {
                      if (c.categoryBudgetLimit != null) {
                        return true;
                      }
                      return (allCategoryLimitsSnap.data ?? []).any((other) =>
                          other.categoryBudgetLimit != null &&
                          other.category.mainCategoryPk ==
                              c.category.categoryPk);
                    }).toList();

                    // Remove all duplicates
                    Set<String> existingCategoryPks =
                        (categoryWithTotalsSnap.data ?? [])
                            .map((c) => c.category.categoryPk)
                            .toSet();
                    List<CategoryWithTotal> categoryWithTotals = [
                      ...(categoryWithTotalsSnap.data ?? []),
                      ...(allCategoryLimits).where((c) =>
                          !existingCategoryPks.contains(c.category.categoryPk)),
                    ];

                    //Count number of categories that have a spending limit, but no spending
                    int extraCategoriesCountWithSpendingLimit =
                        (allCategoryLimits)
                            .where((c) => !existingCategoryPks
                                .contains(c.category.categoryPk))
                            .length;

                    TotalSpentCategoriesSummary s =
                        watchTotalSpentInTimeRangeHelper(
                      dataInput: categoryWithTotals,
                      showAllSubcategories: showAllSubcategories,
                      multiplyTotalBy: determineBudgetPolarity(widget.budget),
                    );
                    List<Widget> categoryEntries = [];
                    double totalSpentPercent = 45 / 360;
                    categoryWithTotals.asMap().forEach(
                      (index, category) {
                        categoryEntries.add(
                          CategoryEntry(
                            alwaysHide:
                                showAllCategoriesWithCategoryLimit == false &&
                                    category.transactionCount == -1,
                            percentageOffset: totalSpentPercent,
                            getPercentageAfterText: (double categorySpent) {
                              if (widget.budget.income == true) {
                                return categorySpent < 0 &&
                                        showIncomeExpenseIcons
                                    ? "of-total".tr().toLowerCase()
                                    : "of-saving".tr().toLowerCase();
                              } else {
                                return categorySpent > 0 &&
                                        showIncomeExpenseIcons
                                    ? "of-total".tr().toLowerCase()
                                    : "of-spending".tr().toLowerCase();
                              }
                            },
                            selectedSubCategoryPk: selectedCategory?.categoryPk,
                            expandSubcategories: showAllSubcategories ||
                                category.category.categoryPk ==
                                    selectedCategory?.categoryPk ||
                                category.category.categoryPk ==
                                    selectedCategory?.mainCategoryPk,
                            subcategoriesWithTotalMap:
                                s.subCategorySpendingIndexedByMainCategoryPk,
                            todayPercent: todayPercent,
                            overSpentColor: category.total > 0
                                ? getColor(context, "incomeAmount")
                                : getColor(context, "expenseAmount"),
                            showIncomeExpenseIcons: showIncomeExpenseIcons,
                            onLongPress: (TransactionCategory category,
                                CategoryBudgetLimit? categoryBudgetLimit) {
                              enterCategoryLimitPopup(
                                context,
                                category,
                                categoryBudgetLimit,
                                widget.budget.budgetPk,
                                (p0) => null,
                                widget.budget.isAbsoluteSpendingLimit,
                              );
                            },
                            isAbsoluteSpendingLimit:
                                widget.budget.isAbsoluteSpendingLimit,
                            budgetLimit: budgetAmount,
                            categoryBudgetLimit: category.categoryBudgetLimit,
                            category: category.category,
                            totalSpent: s.totalSpent,
                            transactionCount: category.transactionCount,
                            categorySpent: showIncomeExpenseIcons == true
                                ? category.total
                                : category.total.abs(),
                            onTap: (TransactionCategory tappedCategory, _) {
                              if (selectedCategory?.categoryPk ==
                                  tappedCategory.categoryPk) {
                                setState(() {
                                  selectedCategory = null;
                                });
                                _pieChartDisplayStateKey.currentState
                                    ?.setTouchedIndex(-1);
                              } else {
                                if (showAllSubcategories ||
                                    tappedCategory.mainCategoryPk == null) {
                                  setState(() {
                                    selectedCategory = tappedCategory;
                                  });
                                  _pieChartDisplayStateKey.currentState
                                      ?.setTouchedCategoryPk(
                                          tappedCategory.categoryPk);
                                } else {
                                  // We are tapping a subcategoryEntry and it is not in the pie chart
                                  // because showAllSubcategories is false and mainCategoryPk is not null
                                  setState(() {
                                    selectedCategory = tappedCategory;
                                  });
                                  _pieChartDisplayStateKey.currentState
                                      ?.setTouchedCategoryPk(
                                          tappedCategory.mainCategoryPk);
                                }
                              }
                            },
                            selected: category.category.categoryPk ==
                                    selectedCategory?.mainCategoryPk ||
                                selectedCategory?.categoryPk ==
                                    category.category.categoryPk,
                            allSelected: selectedCategory == null,
                          ),
                        );
                        if (s.totalSpent != 0)
                          totalSpentPercent +=
                              category.total.abs() / s.totalSpent;
                      },
                    );
                    // print(s.totalSpent);
                    return MultiSliver(
                      children: [
                        SliverToBoxAdapter(
                          child: Container(
                            padding: EdgeInsetsDirectional.only(
                              bottom: showingSelectedPeriodAppBar
                                  ? isPastBudgetButCurrentPeriod == true
                                      ? 14
                                      : 5
                                  : 20,
                              start: 22,
                              end: 22,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            ),
                            child: AnimatedSizeSwitcher(
                              child: Column(
                                key: ValueKey(isPastBudgetButCurrentPeriod),
                                children: [
                                  Transform.scale(
                                    alignment:
                                        AlignmentDirectional.bottomCenter,
                                    scale: 1500,
                                    child: Container(
                                      height: 10,
                                      width: 100,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.symmetric(
                                      horizontal:
                                          getHorizontalPaddingConstrained(
                                              context),
                                    ),
                                    child: StreamBuilder<double?>(
                                      stream: database.watchTotalOfBudget(
                                        allWallets:
                                            Provider.of<AllWallets>(context),
                                        start: budgetRange.start,
                                        end: budgetRange.end,
                                        categoryFks: widget.budget.categoryFks,
                                        categoryFksExclude:
                                            widget.budget.categoryFksExclude,
                                        budgetTransactionFilters: widget
                                            .budget.budgetTransactionFilters,
                                        memberTransactionFilters: widget
                                            .budget.memberTransactionFilters,
                                        member: selectedMember,
                                        onlyShowTransactionsBelongingToBudgetPk:
                                            widget.budget.sharedKey != null ||
                                                    widget.budget
                                                            .addedTransactionsOnly ==
                                                        true
                                                ? widget.budget.budgetPk
                                                : null,
                                        budget: widget.budget,
                                        searchFilters: SearchFilters(
                                            paidStatus: [PaidStatus.notPaid]),
                                        paidOnly: false,
                                      ),
                                      builder: (context, snapshot) {
                                        return BudgetTimeline(
                                          dateForRange: dateForRange,
                                          budget: widget.budget,
                                          large: true,
                                          percent: budgetAmount == 0
                                              ? 0
                                              : s.totalSpent /
                                                  budgetAmount *
                                                  100,
                                          yourPercent: 0,
                                          todayPercent: isPastBudget == true
                                              ? -1
                                              : todayPercent,
                                          ghostPercent: budgetAmount == 0
                                              ? 0
                                              : (((snapshot.data ?? 0) *
                                                          determineBudgetPolarity(
                                                              widget.budget)) /
                                                      budgetAmount) *
                                                  100,
                                        );
                                      },
                                    ),
                                  ),
                                  isPastBudget == true
                                      ? SizedBox.shrink()
                                      : DaySpending(
                                          budget: widget.budget,
                                          totalAmount: s.totalSpent,
                                          large: true,
                                          budgetRange: budgetRange,
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  top: 15, bottom: 0),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPinnedHeader(
                          child: showingSelectedPeriodAppBar
                              // Based on SelectedPeriodHeaderLabel
                              ? Container(
                                  transform:
                                      Matrix4.translationValues(0, -1, 0),
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 3, top: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .symmetric(horizontal: 10),
                                        child: IconButtonScaled(
                                          iconData:
                                              appStateSettings["outlinedIcons"]
                                                  ? Icons.chevron_left_outlined
                                                  : Icons.chevron_left_rounded,
                                          iconSize: 18,
                                          scale: 1,
                                          onTap: () =>
                                              changeSelectedDateRange(-1),
                                        ),
                                      ),
                                      Flexible(
                                        child: AnimatedSizeSwitcher(
                                          child: TextFont(
                                            key: ValueKey(timeRangeString),
                                            text: timeRangeString,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            textAlign: TextAlign.center,
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .symmetric(horizontal: 10),
                                        child: DisabledButton(
                                          disabled: dateForRangeIndex == 0,
                                          child: IconButtonScaled(
                                            iconData: appStateSettings[
                                                    "outlinedIcons"]
                                                ? Icons.chevron_right_outlined
                                                : Icons.chevron_right_rounded,
                                            iconSize: 18,
                                            scale: 1,
                                            onTap: () =>
                                                changeSelectedDateRange(1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    boxShadow:
                                        boxShadowCheck(boxShadowSharp(context)),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                )
                              : Container(),
                        ),
                        SliverToBoxAdapter(
                            child: Column(children: [
                          appStateSettings["sharedBudgets"]
                              ? BudgetSpenderSummary(
                                  budget: widget.budget,
                                  budgetRange: budgetRange,
                                  setSelectedMember: (member) {
                                    setState(() {
                                      selectedMember = member;
                                      selectedCategory = null;
                                    });
                                    _pieChartDisplayStateKey.currentState
                                        ?.setTouchedIndex(-1);
                                  },
                                )
                              : SizedBox.shrink(),
                          if (categoryWithTotals.length > 0)
                            SizedBox(height: 37),

                          if (categoryWithTotals.length > 0)
                            pieChart(
                              budgetRange: budgetRange,
                              totalSpent: s.totalSpent,
                              showAllSubcategories: showAllSubcategories,
                              toggleAllSubCategories: toggleAllSubcategories,
                              dataFilterUnassignedTransactions:
                                  s.dataFilterUnassignedTransactions,
                              hasSubCategories: s.hasSubCategories,
                              pageBackgroundColor: pageBackgroundColor,
                            ),
                          // if (snapshot.data!.length > 0)
                          //   SizedBox(height: 35),
                          ...categoryEntries,
                          if (categoryWithTotals.length > 0)
                            SizedBox(height: 15),
                          AnimatedExpanded(
                            expand: selectedCategory == null &&
                                extraCategoriesCountWithSpendingLimit > 0,
                            child: Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 15),
                              child: AnimatedSizeSwitcher(
                                child: Center(
                                  key: ValueKey(
                                      "showAllCategoriesWithCategoryLimit" +
                                          showAllCategoriesWithCategoryLimit
                                              .toString()),
                                  child: LowKeyButton(
                                    onTap: () {
                                      toggleShowAllCategoriesWithCategoryLimit();
                                    },
                                    text: showAllCategoriesWithCategoryLimit
                                        ? "collapse-empty-categories".tr()
                                        : "expand-all-with-spending-goals".tr(),
                                    extraWidgetAtBeginning: true,
                                    extraWidget: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 3),
                                      child: Transform.scale(
                                        scale: 1.6,
                                        child: Icon(
                                          showAllCategoriesWithCategoryLimit
                                              ? appStateSettings[
                                                      "outlinedIcons"]
                                                  ? Icons.arrow_drop_up_outlined
                                                  : Icons.arrow_drop_up_rounded
                                              : appStateSettings[
                                                      "outlinedIcons"]
                                                  ? Icons
                                                      .arrow_drop_down_outlined
                                                  : Icons
                                                      .arrow_drop_down_rounded,
                                          size: 15,
                                          color: getColor(context, "black")
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]))
                      ],
                    );
                  },
                );
              }),
          SliverToBoxAdapter(
            child: AnimatedExpanded(
              expand: selectedCategory != null,
              child: Padding(
                key: ValueKey(1),
                padding: const EdgeInsetsDirectional.only(
                    start: 13, end: 15, top: 5, bottom: 15),
                child: Center(
                  child: TextFont(
                    text: "transactions-for-selected-category".tr(),
                    maxLines: 10,
                    textAlign: TextAlign.center,
                    fontSize: 13,
                    textColor: getColor(context, "textLight"),
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 13),
              child: Container(
                margin: EdgeInsetsDirectional.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadiusDirectional.all(Radius.circular(15)),
                  color: appStateSettings["materialYou"]
                      ? dynamicPastel(context,
                          Theme.of(context).colorScheme.secondaryContainer,
                          amount: 0.5)
                      : getColor(context, "lightDarkAccentHeavyLight"),
                  boxShadow: boxShadowCheck(boxShadowGeneral(context)),
                ),
                child: BudgetLineGraph(
                  budget: widget.budget,
                  dateForRange: dateForRange,
                  isPastBudget: isPastBudget,
                  selectedCategory: selectedCategory,
                  budgetRange: budgetRange,
                  showIfNone: false,
                ),
              ),
            ),
          ),
          TransactionEntries(
            budgetRange.start,
            budgetRange.end,
            categoryFks: selectedCategory != null
                ? [selectedCategory!.categoryPk]
                : widget.budget.categoryFks,
            categoryFksExclude: selectedCategory != null
                ? null
                : widget.budget.categoryFksExclude,
            listID: pageId,
            budgetTransactionFilters: widget.budget.budgetTransactionFilters,
            memberTransactionFilters: widget.budget.memberTransactionFilters,
            member: selectedMember,
            onlyShowTransactionsBelongingToBudgetPk:
                widget.budget.sharedKey != null ||
                        widget.budget.addedTransactionsOnly == true
                    ? widget.budget.budgetPk
                    : null,
            walletFks: widget.budget.walletFks ?? [],
            budget: widget.budget,
            dateDividerColor: pageBackgroundColor,
            transactionBackgroundColor: pageBackgroundColor,
            categoryTintColor: Theme.of(context).colorScheme.primary,
            noResultsExtraWidget:
                widget.budget.reoccurrence != BudgetReoccurence.custom &&
                        isPastBudget == false &&
                        isPastBudgetButCurrentPeriod == false
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(top: 20),
                        child: ExtraInfoButton(
                          onTap: () {
                            pushRoute(
                              context,
                              PastBudgetsPage(budgetPk: widget.budget.budgetPk),
                            );
                          },
                          text: "view-previous-budget-periods".tr(),
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.history_outlined
                              : Icons.history_rounded,
                          color: dynamicPastel(
                            context,
                            Theme.of(context).colorScheme.secondaryContainer,
                            amountLight:
                                appStateSettings["materialYou"] ? 0.25 : 0.4,
                            amountDark:
                                appStateSettings["materialYou"] ? 0.4 : 0.55,
                          ),
                          buttonIconColor: dynamicPastel(
                              context,
                              HexColor(widget.budget.colour,
                                  defaultColor:
                                      Theme.of(context).colorScheme.primary),
                              amount: 0.5),
                          buttonIconColorIcon: dynamicPastel(
                              context,
                              HexColor(widget.budget.colour,
                                  defaultColor:
                                      Theme.of(context).colorScheme.primary),
                              amount: 0.7,
                              inverse: true),
                        ),
                      )
                    : SizedBox.shrink(),
            showTotalCashFlow: true,
            showExcludedBudgetTag: (Transaction transaction) =>
                transaction.budgetFksExclude
                    ?.contains(widget.budget.budgetPk) ==
                true,
            renderType:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? TransactionEntriesRenderType.sliversNotSticky
                    : TransactionEntriesRenderType.implicitlyAnimatedSlivers,
          ),
          SliverToBoxAdapter(
            child: widget.budget.sharedDateUpdated == null
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 10, end: 10, bottom: 0),
                    child: TextFont(
                      text: "synced".tr() +
                          " " +
                          getTimeAgo(
                            widget.budget.sharedDateUpdated!,
                          ).toLowerCase() +
                          "\n Created by " +
                          getMemberNickname(
                              (widget.budget.sharedMembers ?? [""])[0]),
                      fontSize: 13,
                      textColor: getColor(context, "textLight"),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                    ),
                  ),
          ),
          // Wipe all remaining pixels off - sometimes graphics artifacts are left behind
          SliverToBoxAdapter(
            child: Container(height: 1, color: pageBackgroundColor),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 45))
        ],
        selectedTransactionsAppBar: SelectedTransactionsAppBar(
          pageID: pageId,
        ),
      ),
    );
  }
}

class WidgetPosition extends StatefulWidget {
  final Widget child;
  final Function(Offset position) onChange;

  const WidgetPosition({
    Key? key,
    required this.onChange,
    required this.child,
  }) : super(key: key);

  @override
  _WidgetPositionState createState() => _WidgetPositionState();
}

class _WidgetPositionState extends State<WidgetPosition> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  var widgetKey = GlobalKey();
  var oldPosition;

  void postFrameCallback(_) {
    var context = widgetKey.currentContext;
    if (context == null) return;

    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    Offset newPosition = renderBox.localToGlobal(Offset.zero);
    if (oldPosition == newPosition) return;

    oldPosition = newPosition;
    widget.onChange(newPosition);
  }
}

class BudgetLineGraph extends StatefulWidget {
  const BudgetLineGraph({
    required this.budget,
    required this.dateForRange,
    required this.isPastBudget,
    required this.selectedCategory,
    required this.budgetRange,
    this.showPastSpending = true,
    this.showIfNone = true,
    this.padding = EdgeInsetsDirectional.zero,
    super.key,
  });

  final Budget budget;
  final DateTime? dateForRange;
  final bool? isPastBudget;
  final TransactionCategory? selectedCategory;
  final DateTimeRange budgetRange;
  final bool showPastSpending;
  final bool showIfNone;
  final EdgeInsetsDirectional padding;

  @override
  State<BudgetLineGraph> createState() => _BudgetLineGraphState();
}

class _BudgetLineGraphState extends State<BudgetLineGraph> {
  Stream<List<List<Transaction>>>? mergedStreamsPastSpendingTotals;
  List<DateTimeRange> dateTimeRanges = [];
  int longestDateRange = 0;

  void didUpdateWidget(oldWidget) {
    if (oldWidget != widget) {
      _init();
    }
  }

  initState() {
    _init();
  }

  _init() {
    Future.delayed(
      Duration.zero,
      () async {
        dateTimeRanges = [];
        List<Stream<List<Transaction>>> watchedPastSpendingTotals = [];
        for (int index = 0;
            index <=
                (widget.showPastSpending == false
                    ? 0
                    : (appStateSettings["showPastSpendingTrajectory"] == true
                        ? 2
                        : 0));
            index++) {
          DateTime datePast = DateTime(
            (widget.dateForRange ?? DateTime.now()).year -
                (widget.budget.reoccurrence == BudgetReoccurence.yearly
                    ? index * widget.budget.periodLength
                    : 0),
            (widget.dateForRange ?? DateTime.now()).month -
                (widget.budget.reoccurrence == BudgetReoccurence.monthly
                    ? index * widget.budget.periodLength
                    : 0),
            (widget.dateForRange ?? DateTime.now()).day -
                (widget.budget.reoccurrence == BudgetReoccurence.daily
                    ? index * widget.budget.periodLength
                    : 0) -
                (widget.budget.reoccurrence == BudgetReoccurence.weekly
                    ? index * 7 * widget.budget.periodLength
                    : 0),
            0,
            0,
            1,
          );

          DateTimeRange budgetRange = getBudgetDate(widget.budget, datePast);
          dateTimeRanges.add(budgetRange);
          watchedPastSpendingTotals
              .add(database.getTransactionsInTimeRangeFromCategories(
            budgetRange.start,
            budgetRange.end,
            widget.selectedCategory != null
                ? [widget.selectedCategory!.categoryPk]
                : widget.budget.categoryFks,
            widget.selectedCategory != null
                ? []
                : widget.budget.categoryFksExclude,
            true,
            null,
            widget.budget.budgetTransactionFilters,
            widget.budget.memberTransactionFilters,
            onlyShowTransactionsBelongingToBudgetPk:
                widget.budget.sharedKey != null ||
                        widget.budget.addedTransactionsOnly == true
                    ? widget.budget.budgetPk
                    : null,
            budget: widget.budget,
          ));
          if (budgetRange.duration.inDays > longestDateRange) {
            longestDateRange = budgetRange.duration.inDays;
          }
        }

        setState(() {
          mergedStreamsPastSpendingTotals =
              StreamZip(watchedPastSpendingTotals);
        });
      },
    );
  }

  // Whether to always show all the days of the budget in the line graph
  bool showCompressedView = appStateSettings["showCompressedViewBudgetGraph"];

  @override
  Widget build(BuildContext context) {
    double budgetAmount = budgetAmountToPrimaryCurrency(
        Provider.of<AllWallets>(context, listen: true), widget.budget);

    return StreamBuilder<List<List<Transaction>>>(
      stream: mergedStreamsPastSpendingTotals,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0) return SizedBox.shrink();
          DateTime budgetRangeEnd = widget.budgetRange.end;
          if (showCompressedView && budgetRangeEnd.isAfter(DateTime.now())) {
            budgetRangeEnd = DateTime.now();
          }
          bool allZeroes = true;
          List<List<Pair>> pointsList = [];

          for (int snapshotIndex = 0;
              snapshotIndex < snapshot.data!.length;
              snapshotIndex++) {
            var p = CalculatePointsParams(
              transactions: snapshot.data![snapshotIndex],
              customStartDate: dateTimeRanges[snapshotIndex].start,
              customEndDate: showCompressedView
                  ? budgetRangeEnd
                  : dateTimeRanges[snapshotIndex].end,
              totalSpentBefore: 0,
              isIncome: null,
              allWallets: Provider.of<AllWallets>(context, listen: false),
              showCumulativeSpending:
                  appStateSettings["showCumulativeSpending"],
              invertPolarity:
                  determineBudgetPolarity(widget.budget) == -1 ? true : false,
              appStateSettingsPassed: appStateSettings,
            );
            List<Pair> points = calculatePoints(p);

            if (allZeroes == true) {
              for (Pair point in points) {
                if (point.y != 0) {
                  allZeroes = false;
                  break;
                }
              }
            }
            pointsList.add(points);
          }

          Color lineColor = widget.selectedCategory?.categoryPk != null &&
                  widget.selectedCategory != null
              ? HexColor(widget.selectedCategory!.colour,
                  defaultColor: Theme.of(context).colorScheme.primary)
              : Theme.of(context).colorScheme.primary;
          if (widget.showIfNone == false && allZeroes) return SizedBox.shrink();
          return Stack(
            children: [
              Padding(
                padding: widget.padding,
                child: LineChartWrapper(
                  keepHorizontalLineInView:
                      widget.selectedCategory == null ? true : false,
                  color: lineColor,
                  verticalLineAt: widget.isPastBudget == true
                      ? null
                      : (budgetRangeEnd
                              .difference(
                                  (widget.dateForRange ?? DateTime.now()))
                              .inDays)
                          .toDouble(),
                  endDate: budgetRangeEnd,
                  points: pointsList,
                  isCurved: true,
                  colors: [
                    for (int index = 0; index < snapshot.data!.length; index++)
                      index == 0
                          ? lineColor
                          : (widget.selectedCategory?.categoryPk != null &&
                                      widget.selectedCategory != null
                                  ? lineColor
                                  : Theme.of(context).colorScheme.tertiary)
                              .withOpacity((index) / snapshot.data!.length)
                  ],
                  horizontalLineAt: widget.isPastBudget == true ||
                          (widget.budget.reoccurrence ==
                                  BudgetReoccurence.custom &&
                              widget.budget.endDate.millisecondsSinceEpoch <
                                  DateTime.now().millisecondsSinceEpoch) ||
                          (widget.budget.addedTransactionsOnly &&
                              widget.budget.endDate.millisecondsSinceEpoch <
                                  DateTime.now().millisecondsSinceEpoch)
                      ? budgetAmount
                      : budgetAmount *
                          ((DateTime.now().millisecondsSinceEpoch -
                                  widget.budgetRange.start
                                      .millisecondsSinceEpoch) /
                              (widget.budgetRange.end.millisecondsSinceEpoch -
                                  widget.budgetRange.start
                                      .millisecondsSinceEpoch)),
                ),
              ),
              if (widget.isPastBudget == false &&
                  widget.budgetRange.end.isAfter(DateTime.now()))
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  child: Transform.translate(
                    offset: Offset(5, -5).withDirectionality(context),
                    child: Tooltip(
                      message: showCompressedView
                          ? "view-all-days".tr()
                          : "view-to-today".tr(),
                      child: IconButton(
                        color: Theme.of(context).colorScheme.primary,
                        icon: Transform.rotate(
                          angle: pi / 2,
                          child: ScaledAnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            keyToWatch: showCompressedView.toString(),
                            child: Icon(
                              showCompressedView
                                  ? appStateSettings["outlinedIcons"]
                                      ? Icons.expand_outlined
                                      : Icons.expand_rounded
                                  : appStateSettings["outlinedIcons"]
                                      ? Icons.compress_outlined
                                      : Icons.compress_rounded,
                              size: 22,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            showCompressedView = !showCompressedView;
                          });
                          updateSettings("showCompressedViewBudgetGraph",
                              showCompressedView,
                              updateGlobalState: false);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class TotalSpent extends StatefulWidget {
  const TotalSpent({
    super.key,
    required this.totalSpent,
    required this.budget,
  });

  final double totalSpent;
  final Budget budget;

  @override
  State<TotalSpent> createState() => _TotalSpentState();
}

class _TotalSpentState extends State<TotalSpent> {
  bool showTotalSpent = appStateSettings["showTotalSpentForBudget"];

  _swapTotalSpentDisplay() {
    setState(() {
      showTotalSpent = !showTotalSpent;
    });
    updateSettings("showTotalSpentForBudget", showTotalSpent,
        pagesNeedingRefresh: [0, 2], updateGlobalState: false);
  }

  @override
  Widget build(BuildContext context) {
    double budgetAmount = budgetAmountToPrimaryCurrency(
        Provider.of<AllWallets>(context, listen: true), widget.budget);

    return GestureDetector(
      onTap: () {
        _swapTotalSpentDisplay();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _swapTotalSpentDisplay();
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: IntrinsicWidth(
          child: budgetAmount - widget.totalSpent >= 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      child: CountNumber(
                        count: showTotalSpent
                            ? widget.totalSpent
                            : budgetAmount - widget.totalSpent,
                        duration: Duration(milliseconds: 400),
                        initialCount: (0),
                        textBuilder: (number) {
                          return TextFont(
                            text: convertToMoney(
                                Provider.of<AllWallets>(context), number,
                                finalNumber: showTotalSpent
                                    ? widget.totalSpent
                                    : budgetAmount - widget.totalSpent),
                            fontSize: 22,
                            textAlign: TextAlign.start,
                            fontWeight: FontWeight.bold,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.only(bottom: 1.5),
                      child: TextFont(
                        text: getBudgetSpentText(widget.budget.income) +
                            convertToMoney(
                                Provider.of<AllWallets>(context), budgetAmount),
                        fontSize: 15,
                        textAlign: TextAlign.start,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      child: CountNumber(
                        count: showTotalSpent
                            ? widget.totalSpent
                            : widget.totalSpent - budgetAmount,
                        duration: Duration(milliseconds: 400),
                        initialCount: (0),
                        textBuilder: (number) {
                          return TextFont(
                            text: convertToMoney(
                                Provider.of<AllWallets>(context), number,
                                finalNumber: showTotalSpent
                                    ? widget.totalSpent
                                    : widget.totalSpent - budgetAmount),
                            fontSize: 22,
                            textAlign: TextAlign.start,
                            fontWeight: FontWeight.bold,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.only(bottom: 1.5),
                      child: TextFont(
                        text: getBudgetOverSpentText(widget.budget.income) +
                            convertToMoney(
                                Provider.of<AllWallets>(context), budgetAmount),
                        fontSize: 15,
                        textAlign: TextAlign.start,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String getBudgetSpentText(bool isIncome) {
  if (isIncome == false) {
    return (appStateSettings["showTotalSpentForBudget"]
        ? " " + "spent-amount-of".tr() + " "
        : " " + "remaining-amount-of".tr() + " ");
  } else {
    return (appStateSettings["showTotalSpentForBudget"]
        ? " " + "saved-amount-of".tr() + " "
        : " " + "remaining-amount-of".tr() + " ");
  }
}

String getBudgetOverSpentText(bool isIncome) {
  if (isIncome == false) {
    return (appStateSettings["showTotalSpentForBudget"]
        ? " " + "spent-amount-of".tr() + " "
        : " " + "overspent-amount-of".tr() + " ");
  } else {
    return (appStateSettings["showTotalSpentForBudget"]
        ? " " + "saved-amount-of".tr() + " "
        : " " + "over-saved-amount-of".tr() + " ");
  }
}

int determineBudgetPolarity(Budget budget) {
  if (budget.income == true) {
    return 1;
  } else {
    return -1;
  }
}
