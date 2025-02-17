import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addCategoryPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/categoryLimits.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/animatedCircularProgress.dart';
import 'package:provider/provider.dart';
import 'package:budget/colors.dart';

class CategoryEntry extends StatelessWidget {
  CategoryEntry({
    Key? key,
    required this.category,
    required this.transactionCount,
    required this.categorySpent,
    required this.totalSpent,
    required this.onTap,
    required this.selected,
    required this.allSelected,
    this.categoryBudgetLimit,
    this.onLongPress,
    this.extraText,
    this.showIncomeExpenseIcons = false,
    this.isAbsoluteSpendingLimit = false,
    this.budgetLimit = 0,
    this.overSpentColor,
    this.todayPercent,
    this.subcategoriesWithTotalMap,
    this.expandSubcategories = true,
    this.selectedSubCategoryPk,
    this.alwaysShow = false,
    this.alwaysHide = false,
    this.isSubcategory = false,
    this.mainCategorySpentIfSubcategory = 0,
    this.useHorizontalPaddingConstrained = true,
    this.getPercentageAfterText,
    this.percentageOffset = 0,
  }) : super(key: key);

  final TransactionCategory category;
  final int transactionCount;
  final double totalSpent;
  final double categorySpent;
  final Function(TransactionCategory category,
      CategoryBudgetLimit? categoryBudgetLimit) onTap;
  final bool selected;
  final bool allSelected;
  final CategoryBudgetLimit? categoryBudgetLimit;
  final Function(TransactionCategory category,
      CategoryBudgetLimit? categoryBudgetLimit)? onLongPress;
  final String? extraText;
  final bool showIncomeExpenseIcons;
  final bool isAbsoluteSpendingLimit;
  final double budgetLimit;
  final Color? overSpentColor;
  final double? todayPercent;
  final Map<String, List<CategoryWithTotal>>? subcategoriesWithTotalMap;
  final bool expandSubcategories;
  final String? selectedSubCategoryPk;
  final bool alwaysShow;
  final bool alwaysHide;
  final bool isSubcategory;
  final double mainCategorySpentIfSubcategory;
  final bool useHorizontalPaddingConstrained;
  final String Function(double categorySpent)? getPercentageAfterText;
  final double percentageOffset;

  @override
  Widget build(BuildContext context) {
    Widget component;

    double categoryLimitAmount = categoryBudgetLimit == null
        ? 0
        : isAbsoluteSpendingLimit
            ? categoryBudgetLimitToPrimaryCurrency(
                Provider.of<AllWallets>(context, listen: true),
                categoryBudgetLimit!)
            : categoryBudgetLimit!.amount;

    List<CategoryWithTotal> subCategoriesWithTotal =
        subcategoriesWithTotalMap?[category.categoryPk] ?? [];

    if (category.mainCategoryPk != null && subcategoriesWithTotalMap != null)
      return SizedBox.shrink();

    bool hasSubCategories =
        subCategoriesWithTotal.length > 0 && expandSubcategories != false;

    double percentSpentWithCategoryLimit = isSubcategory
        ? (categorySpent / mainCategorySpentIfSubcategory).abs()
        : (categorySpent / totalSpent).abs();
    percentSpentWithCategoryLimit =
        removeNaNAndInfinity(percentSpentWithCategoryLimit);

    double percentSpent;
    if (categoryBudgetLimit == null) {
      percentSpent = percentSpentWithCategoryLimit;
    } else {
      double ratio;
      if (isAbsoluteSpendingLimit) {
        ratio = (categorySpent / categoryLimitAmount).abs();
      } else {
        double adjustedCategoryLimit = categoryLimitAmount / 100 * budgetLimit;
        ratio = (categorySpent / adjustedCategoryLimit).abs();
      }
      percentSpent = clampDouble(ratio, 0, 1);
    }
    percentSpent = removeNaNAndInfinity(percentSpent);

    double amountSpent = categorySpent.abs();
    double spendingLimit = categoryBudgetLimit == null
        ? 0
        : isAbsoluteSpendingLimit
            ? categoryLimitAmount
            : categoryLimitAmount / 100 * budgetLimit;
    bool isOverspent = categoryBudgetLimit == null
        ? false
        : isAbsoluteSpendingLimit
            ? categorySpent.abs() > categoryLimitAmount
            : categorySpent.abs() > (categoryLimitAmount / 100 * budgetLimit);
    component = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: isSubcategory == false
            ? getHorizontalPaddingConstrained(context,
                enabled: useHorizontalPaddingConstrained)
            : 0,
      ),
      child: Builder(
        builder: (context) {
          Widget mainCategoryWidget = Padding(
            padding: hasSubCategories
                ? EdgeInsetsDirectional.zero
                : EdgeInsetsDirectional.only(
                    start: 20, end: 25, top: 8, bottom: 8),
            child: Row(
              children: [
                CategoryIconPercent(
                  category: category,
                  percent: percentSpentWithCategoryLimit * 100,
                  percentageOffset:
                      appStateSettings["circularProgressRotation"] == true
                          ? percentageOffset
                          : 0,
                  progressBackgroundColor: appStateSettings["materialYou"]
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : selected
                          ? getColor(context, "white")
                          : getColor(context, "lightDarkAccentHeavy"),
                  size: 28,
                  insetPadding: 18,
                ),
                Container(
                  width: 15,
                ),
                Expanded(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFont(
                                text: category.name,
                                fontSize: 17,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 10),
                            categorySpent == 0 ||
                                    showIncomeExpenseIcons == false
                                ? SizedBox.shrink()
                                : Transform.translate(
                                    offset: Offset(3, 0),
                                    child: Transform.rotate(
                                      angle: categorySpent >= 0 ? pi : 0,
                                      child: Icon(
                                        appStateSettings["outlinedIcons"]
                                            ? Icons.arrow_drop_down_outlined
                                            : Icons.arrow_drop_down_rounded,
                                        color: showIncomeExpenseIcons
                                            ? categorySpent > 0
                                                ? getColor(
                                                    context, "incomeAmount")
                                                : getColor(
                                                    context, "expenseAmount")
                                            : getColor(context, "black"),
                                      ),
                                    ),
                                  ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextFont(
                                  fontWeight: FontWeight.bold,
                                  text: convertToMoney(
                                      Provider.of<AllWallets>(context),
                                      amountSpent),
                                  fontSize: 20,
                                  textColor: isOverspent
                                      ? overSpentColor ??
                                          getColor(context, "expenseAmount")
                                      : showIncomeExpenseIcons &&
                                              categorySpent != 0
                                          ? categorySpent > 0
                                              ? getColor(
                                                  context, "incomeAmount")
                                              : getColor(
                                                  context, "expenseAmount")
                                          : getColor(context, "black"),
                                ),
                                categoryBudgetLimit == null
                                    ? SizedBox.shrink()
                                    : Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                bottom: 1),
                                        child: TextFont(
                                          text: " / " +
                                              convertToMoney(
                                                  Provider.of<AllWallets>(
                                                      context),
                                                  spendingLimit),
                                          fontSize: 14,
                                          textColor: isOverspent
                                              ? overSpentColor ??
                                                  getColor(
                                                      context, "expenseAmount")
                                              : getColor(context, "black")
                                                  .withOpacity(0.3),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 1,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: categoryBudgetLimit != null
                                  ? Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        top: 3,
                                        end: 13,
                                        bottom: 3,
                                      ),
                                      child: ThinProgress(
                                        backgroundColor:
                                            appStateSettings["materialYou"]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondaryContainer
                                                : selected
                                                    ? getColor(context, "white")
                                                    : getColor(context,
                                                        "lightDarkAccentHeavy"),
                                        color: dynamicPastel(
                                          context,
                                          HexColor(
                                            category.colour,
                                            defaultColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          inverse: true,
                                          amountLight: 0.1,
                                          amountDark: 0.1,
                                        ),
                                        progress: percentSpent,
                                        dotProgress: todayPercent == null
                                            ? null
                                            : (todayPercent ?? 0) / 100,
                                      ),
                                    )
                                  : Builder(builder: (context) {
                                      String percentString = convertToPercent(
                                        percentSpent * 100,
                                        useLessThanZero: true,
                                      );
                                      String text = percentString +
                                          " " +
                                          (isSubcategory
                                              ? "of-category".tr().toLowerCase()
                                              : getPercentageAfterText == null
                                                  ? ""
                                                  : getPercentageAfterText!(
                                                      categorySpent));

                                      return TextFont(
                                        text: text,
                                        fontSize: 14,
                                        textColor: selected
                                            ? getColor(context, "black")
                                                .withOpacity(0.4)
                                            : getColor(context, "textLight"),
                                      );
                                    }),
                            ),
                            TextFont(
                              text: max(transactionCount, 0).toString() +
                                  " " +
                                  (transactionCount == 1
                                      ? "transaction".tr().toLowerCase()
                                      : "transactions".tr().toLowerCase()),
                              fontSize: 14,
                              textColor: selected
                                  ? getColor(context, "black").withOpacity(0.4)
                                  : getColor(context, "textLight"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          if (subCategoriesWithTotal.length <= 0) return mainCategoryWidget;

          Widget subCategoriesSummaryWidget = AnimatedExpanded(
            duration:
                appStateSettings["appAnimations"] != AppAnimations.all.index
                    ? Duration.zero
                    : Duration(milliseconds: 425),
            key: ValueKey(1),
            expand: selected == true || allSelected,
            child: SubCategoriesContainer(
              onTap: () {
                onTap(category, categoryBudgetLimit);
              },
              key: ValueKey(category.categoryPk),
              mainCategory: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 20, end: 25, top: 8, bottom: 8),
                child: mainCategoryWidget,
              ),
              subCategoryEntries: Padding(
                padding: const EdgeInsetsDirectional.only(top: 5),
                child: Builder(builder: (context) {
                  List<Widget> categoryEntries = [];
                  double totalSpentPercent =
                      percentageOffset + percentSpentWithCategoryLimit;
                  subCategoriesWithTotal
                      .asMap()
                      .forEach((index, subcategoryWithTotal) {
                    categoryEntries.add(
                      CategoryEntry(
                        percentageOffset: totalSpentPercent,
                        onTap: onTap,
                        todayPercent: todayPercent,
                        overSpentColor: showIncomeExpenseIcons
                            ? subcategoryWithTotal.total > 0
                                ? getColor(context, "incomeAmount")
                                : getColor(context, "expenseAmount")
                            : null,
                        showIncomeExpenseIcons: showIncomeExpenseIcons,
                        onLongPress: onLongPress,
                        isAbsoluteSpendingLimit: isAbsoluteSpendingLimit,
                        budgetLimit: categoryBudgetLimit == null
                            ? budgetLimit
                            : isAbsoluteSpendingLimit
                                ? categoryLimitAmount
                                : categoryLimitAmount * budgetLimit / 100,
                        categoryBudgetLimit:
                            subcategoryWithTotal.categoryBudgetLimit,
                        category: subcategoryWithTotal.category,
                        totalSpent: totalSpent,
                        transactionCount: subcategoryWithTotal.transactionCount,
                        categorySpent: showIncomeExpenseIcons == true
                            ? subcategoryWithTotal.total
                            : subcategoryWithTotal.total.abs(),
                        selected: selectedSubCategoryPk ==
                            subcategoryWithTotal.category.categoryPk,
                        allSelected: allSelected,
                        alwaysShow: selected,
                        alwaysHide: alwaysHide,
                        isSubcategory: true,
                        mainCategorySpentIfSubcategory: amountSpent,
                      ),
                    );
                    if (amountSpent != 0)
                      totalSpentPercent +=
                          subcategoryWithTotal.total.abs() / amountSpent;
                  });
                  return Column(
                    children: categoryEntries,
                  );
                }),
              ),
            ),
          );

          return AnimatedSizeSwitcher(
            child: expandSubcategories == true
                ? subCategoriesSummaryWidget
                : mainCategoryWidget,
          );
        },
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        if (allSelected == false && selected) {
          onTap(category, categoryBudgetLimit);
          return false;
        }
        return true;
      },
      child: AnimatedExpanded(
        expand:
            alwaysHide == false && (!(!selected && !allSelected) || alwaysShow),
        duration: appStateSettings["appAnimations"] != AppAnimations.all.index
            ? Duration.zero
            : Duration(milliseconds: 650),
        sizeCurve: Curves.easeInOutCubic,
        child: Tappable(
          borderRadius: 0,
          onTap: () {
            onTap(category, categoryBudgetLimit);
          },
          onLongPress: onLongPress != null
              ? () => onLongPress!(category, categoryBudgetLimit)
              : () => pushRoute(
                    context,
                    AddCategoryPage(
                      category: category,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  ),
          color: Colors.transparent,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: allSelected || alwaysShow
                ? 1
                : selected
                    ? 1
                    : 0.3,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                color: selected && hasSubCategories == false
                    ? dynamicPastel(
                            context, Theme.of(context).colorScheme.primary,
                            amount: 0.3)
                        .withAlpha(80)
                    : Colors.transparent,
              ),
              curve: Curves.easeInOut,
              duration: Duration(milliseconds: 500),
              child: component,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryIconPercent extends StatelessWidget {
  CategoryIconPercent({
    Key? key,
    required this.category,
    this.size = 30,
    required this.percent,
    this.insetPadding = 23,
    required this.progressBackgroundColor,
    required this.percentageOffset,
  }) : super(key: key);

  final TransactionCategory category;
  final double size;
  final double percent;
  final double insetPadding;
  final Color progressBackgroundColor;
  final double percentageOffset;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = dynamicPastel(
        context,
        HexColor(category.colour,
            defaultColor: Theme.of(context).colorScheme.primary),
        amountLight: 0.55,
        amountDark: 0.35);
    return Stack(alignment: AlignmentDirectional.center, children: [
      // Padding(
      //   padding: EdgeInsetsDirectional.all(insetPadding / 2),
      //   child: SimpleShadow(
      //     child: Image.asset(
      //       "assets/categories/" + (category.iconName ?? ""),
      //       width: size - 3,
      //     ),
      //     opacity: 0.8,
      //     color: HexColor(category.colour),
      //     offset: Offset(0, 0),
      //     sigma: 1,
      //   ),
      // ),
      category.iconName != null && category.emojiIconName == null
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? backgroundColor
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              height: size + insetPadding,
              width: size + insetPadding,
              padding: EdgeInsetsDirectional.all(10),
              child: CacheCategoryIcon(
                iconName: category.iconName ?? "",
                size: size,
              ),
            )
          : SizedBox.shrink(),
      category.emojiIconName != null
          ? Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? backgroundColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  height: size + insetPadding,
                  width: size + insetPadding,
                  padding: EdgeInsetsDirectional.all(10),
                ),
                EmojiIcon(
                  emojiIconName: category.emojiIconName,
                  size: size * 0.92,
                ),
              ],
            )
          : SizedBox.shrink(),

      AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(progressBackgroundColor.toString()),
          height: size + insetPadding,
          width: size + insetPadding,
          child: AnimatedCircularProgress(
            rotationOffsetPercent: percentageOffset,
            percent: clampDouble(percent / 100, 0, 1),
            backgroundColor: progressBackgroundColor,
            foregroundColor: dynamicPastel(
              context,
              HexColor(
                category.colour,
                defaultColor: Theme.of(context).colorScheme.primary,
              ),
              inverse: true,
              amountLight: 0.1,
              amountDark: 0.1,
            ),
          ),
        ),
      ),
    ]);
  }
}

class ThinProgress extends StatelessWidget {
  final Color color;
  final Color backgroundColor;
  final double progress;
  final double? dotProgress;

  ThinProgress({
    required this.color,
    required this.backgroundColor,
    required this.progress,
    this.dotProgress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, boxConstraints) {
        double x = boxConstraints.maxWidth * (dotProgress ?? 0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadiusDirectional.circular(100),
              child: Stack(
                children: [
                  Container(
                    color: backgroundColor,
                    height: 5,
                  ),
                  AnimatedFractionallySizedBox(
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeInOutCubicEmphasized,
                    child: ClipRRect(
                      borderRadius: BorderRadiusDirectional.circular(100),
                      child: Container(
                        color: color,
                        height: 5,
                      ),
                    ),
                    widthFactor: progress,
                  ),
                ],
              ),
            ),
            if (dotProgress != null && dotProgress! >= 0 && dotProgress! <= 1)
              PositionedDirectional(
                start: x - 5,
                top: -3 / 2,
                child: Container(
                  height: 8,
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadiusDirectional.circular(100),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
