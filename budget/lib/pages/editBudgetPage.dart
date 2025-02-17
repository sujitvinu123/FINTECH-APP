import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/shareBudget.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/editRowEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/modified/reorderable_list.dart';
import 'package:provider/provider.dart';

String? hiddenOnSearchValue;

bool hideIfSearching(String? searchTerm, bool isFocused, BuildContext context) {
  // print(MediaQuery.sizeOf(context).height -
  //     getKeyboardHeight(context) -
  //     getExpandedHeaderHeight(context, null));

  // If it was once hidden when a user was searching for this, don't show options
  // We don't want the settings to pop in and out just because user decided to
  // scroll through results and therefore minimized the keyboard
  if (hiddenOnSearchValue != null && hiddenOnSearchValue == searchTerm) {
    return true;
  }
  if (kIsWeb == false &&
      isFocused == true &&
      MediaQuery.sizeOf(context).height < 950) {
    return true;
  }
  if (searchTerm == "" ||
      searchTerm == null ||
      MediaQuery.sizeOf(context).height -
              getKeyboardHeight(context) -
              getExpandedHeaderHeight(context, null) >
          400) {
    return false;
  }
  hiddenOnSearchValue = searchTerm;
  return true;
}

class EditBudgetPage extends StatefulWidget {
  EditBudgetPage({
    Key? key,
  }) : super(key: key);

  @override
  _EditBudgetPageState createState() => _EditBudgetPageState();
}

class _EditBudgetPageState extends State<EditBudgetPage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;
  String searchValue = "";
  bool isFocused = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      database.fixOrderBudgets();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (searchValue != "") {
          setState(() {
            searchValue = "";
          });
          return false;
        } else {
          return true;
        }
      },
      child: PageFramework(
        horizontalPaddingConstrained: true,
        dragDownToDismiss: true,
        dragDownToDismissEnabled: dragDownToDismissEnabled,
        title: "edit-budgets".tr(),
        scrollToTopButton: true,
        floatingActionButton: AnimateFABDelayed(
          fab: AddFAB(
            tooltip: "add-budget".tr(),
            openPage: AddBudgetPage(
              routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            ),
          ),
        ),
        actions: [
          CustomPopupMenuButton(
            showButtons: true,
            keepOutFirst: true,
            items: [
              DropdownItemMenu(
                id: "add-budget",
                label: "add-budget".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.add_outlined
                    : Icons.add_rounded,
                action: () => pushRoute(
                  context,
                  AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                  ),
                ),
              ),
              DropdownItemMenu(
                id: "settings",
                label: "settings".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.more_vert_outlined
                    : Icons.more_vert_rounded,
                action: () => openBottomSheet(
                  context,
                  PopupFramework(hasPadding: false, child: BudgetSettings()),
                ),
              ),
            ],
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: Focus(
                onFocusChange: (value) {
                  setState(() {
                    isFocused = value;
                  });
                },
                child: TextInput(
                  labelText: "search-budgets-placeholder".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.search_outlined
                      : Icons.search_rounded,
                  onSubmitted: (value) {
                    setState(() {
                      searchValue = value;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      searchValue = value;
                    });
                  },
                  autoFocus: false,
                ),
              ),
            ),
          ),
          // SliverToBoxAdapter(
          //   child: AnimatedExpanded(
          //     expand: hideIfSearching(searchValue, isFocused, context) == false,
          //     child: BudgetSettings(),
          //   ),
          // ),
          StreamBuilder<List<Budget>>(
            stream: database.watchAllBudgets(
                searchFor: searchValue == "" ? null : searchValue),
            builder: (context, snapshot) {
              if (snapshot.hasData && (snapshot.data ?? []).length <= 0) {
                return SliverToBoxAdapter(
                  child: NoResults(
                    message: "no-budgets-found".tr(),
                  ),
                );
              }
              if (snapshot.hasData && (snapshot.data ?? []).length > 0) {
                return SliverReorderableList(
                  onReorderStart: (index) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      dragDownToDismissEnabled = false;
                      currentReorder = index;
                    });
                  },
                  onReorderEnd: (_) {
                    setState(() {
                      dragDownToDismissEnabled = true;
                      currentReorder = -1;
                    });
                  },
                  itemBuilder: (context, index) {
                    Budget budget = snapshot.data![index];
                    DateTimeRange budgetRange =
                        getBudgetDate(budget, DateTime.now());
                    Color accentColor = dynamicPastel(
                        context,
                        HexColor(budget.colour,
                            defaultColor:
                                Theme.of(context).colorScheme.primary),
                        amountLight: 0.55,
                        amountDark: 0.35);
                    return Stack(
                      key: ValueKey(index),
                      children: [
                        EditRowEntry(
                          key: ValueKey(budget.budgetPk),
                          extraIcon: budget.archived
                              ? appStateSettings["outlinedIcons"]
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_off_rounded
                              : appStateSettings["outlinedIcons"]
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_rounded,
                          onExtra: () async {
                            Budget updatedBudget = budget.copyWith(
                              archived: !budget.archived,
                              pinned: budget.archived,
                            );
                            await database.createOrUpdateBudget(updatedBudget);
                          },
                          opacity: budget.archived ? 0.5 : 1,
                          canReorder: searchValue == "" &&
                              (snapshot.data ?? []).length != 1,
                          currentReorder:
                              currentReorder != -1 && currentReorder != index,
                          accentColor: accentColor,
                          onDelete: () async {
                            return (await deleteBudgetPopup(
                                  context,
                                  budget: budget,
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.None,
                                )) ==
                                DeletePopupAction.Delete;
                          },
                          openPage: AddBudgetPage(
                            budget: budget,
                            routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                          ),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFont(
                                text: budget.name,
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                              ),
                              Container(height: 2),
                              Row(
                                children: [
                                  TextFont(
                                    text: convertToMoney(
                                        Provider.of<AllWallets>(context),
                                        budget.amount,
                                        currencyKey:
                                            Provider.of<AllWallets>(context)
                                                .indexedByPk[budget.walletFk]
                                                ?.currency),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  TextFont(
                                    text: " / ",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  // budget.reoccurrence!.index != 0
                                  //     ? TextFont(
                                  //         text: budget.periodLength.toString() + " ",
                                  //         fontWeight: FontWeight.bold,
                                  //         fontSize: 16,
                                  //       )
                                  //     : SizedBox(),
                                  TextFont(
                                    text: budget.periodLength == 1
                                        ? nameRecurrence[budget.reoccurrence]
                                            .toString()
                                            .toLowerCase()
                                            .tr()
                                            .toLowerCase()
                                        : namesRecurrence[budget.reoccurrence]
                                            .toString()
                                            .toLowerCase()
                                            .tr()
                                            .toLowerCase(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ],
                              ),
                              TextFont(
                                text: getWordedDateShort(budgetRange.start) +
                                    " – " +
                                    getWordedDateShort(budgetRange.end),
                                fontSize: 15,
                              ),
                              Container(height: 2),
                              budget.sharedKey == null &&
                                      !budget.addedTransactionsOnly
                                  ? TextFont(
                                      text: budget.categoryFks == null ||
                                              budget.categoryFks!.length == 0
                                          ? "all-categories-budget".tr()
                                          : budget.categoryFks!.length
                                                  .toString() +
                                              " " +
                                              "category-budget".tr(),
                                      fontSize: 14,
                                    )
                                  : FutureBuilder<int?>(
                                      future: database
                                          .getTotalCountOfTransactionsInBudget(
                                              budget.budgetPk),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return TextFont(
                                            textAlign: TextAlign.start,
                                            text: snapshot.data!.toString() +
                                                " " +
                                                (snapshot.data! == 1
                                                    ? "transaction"
                                                        .tr()
                                                        .toLowerCase()
                                                    : "transactions"
                                                        .tr()
                                                        .toLowerCase()),
                                            fontSize: 14,
                                            textColor:
                                                getColor(context, "black")
                                                    .withOpacity(0.65),
                                          );
                                        } else {
                                          return TextFont(
                                            textAlign: TextAlign.start,
                                            text:
                                                "/" + " " + "transactions".tr(),
                                            fontSize: 14,
                                            textColor:
                                                getColor(context, "black")
                                                    .withOpacity(0.65),
                                          );
                                        }
                                      },
                                    ),
                              // List transaction category names on edit budgets page
                              // Wrap(
                              //   spacing: 0,
                              //   runSpacing: 0,
                              //   children: [
                              //     ...budget.categoryFks!
                              //         .asMap()
                              //         .entries
                              //         .map((categoryFk) {
                              //       return Padding(
                              //         padding: const EdgeInsetsDirectional.only(top: 1.4),
                              //         child: FutureBuilder(
                              //             future: database
                              //                 .getCategoryInstance(categoryFk.value),
                              //             builder: (context,
                              //                 AsyncSnapshot<TransactionCategory>
                              //                     snapshot) {
                              //               if (snapshot.hasData) {
                              //                 return Opacity(
                              //                   opacity: 0.4,
                              //                   child: TextFont(
                              //                     text: (snapshot.data?.name ?? "") +
                              //                         (budget.categoryFks!.length -
                              //                                     1 ==
                              //                                 categoryFk.key.toInt()
                              //                             ? ""
                              //                             : ", "),
                              //                     fontSize: 13,
                              //                   ),
                              //                 );
                              //               } else {
                              //                 return TextFont(
                              //                   text: " ",
                              //                   fontSize: 13,
                              //                 );
                              //               }
                              //             }),
                              //       );
                              //     }).toList(),
                              //   ],
                              // ),
                            ],
                          ),
                          index: index,
                        ),
                        budget.sharedKey != null
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    top: 15, end: 20),
                                child: Align(
                                  alignment: AlignmentDirectional.topEnd,
                                  child: Icon(
                                    appStateSettings["outlinedIcons"]
                                        ? Icons.people_alt_outlined
                                        : Icons.people_alt_rounded,
                                    size: 18,
                                    color: budget.colour == null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : dynamicPastel(
                                            context, HexColor(budget.colour),
                                            inverse: true, amount: 0.5),
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    );
                  },
                  itemCount: snapshot.data!.length,
                  onReorder: (_intPrevious, _intNew) async {
                    Budget oldBudget = snapshot.data![_intPrevious];

                    // print(oldBudget.name);
                    // print(oldBudget.order);

                    if (_intNew > _intPrevious) {
                      await database.moveBudget(
                          oldBudget.budgetPk, _intNew - 1, oldBudget.order);
                    } else {
                      await database.moveBudget(
                          oldBudget.budgetPk, _intNew, oldBudget.order);
                    }
                    return true;
                  },
                );
              }
              return SliverToBoxAdapter(
                child: Container(),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 75),
          ),
        ],
      ),
    );
  }
}

Future<DeletePopupAction?> deleteBudgetPopup(
  BuildContext context, {
  required Budget budget,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-budget-question".tr(),
    subtitle: budget.name,
  );
  if (action == DeletePopupAction.Delete) {
    dynamic result = true;
    if (budget.sharedKey != null) {
      result = await deleteSharedBudgetPopup(context, budget);
    } else if (budget.addedTransactionsOnly) {
      int? numTransactions =
          await database.getTotalCountOfTransactionsInBudget(budget.budgetPk);
      if (numTransactions != null && numTransactions > 0) {
        result = await openPopup(
          context,
          title: "remove-transactions-from-added-budget-question".tr(),
          description: "delete-budget-added-warning".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_outlined
              : Icons.warning_rounded,
          onCancel: () {
            popRoute(context, false);
          },
          onCancelLabel: "cancel".tr(),
          onSubmit: () async {
            popRoute(context, true);
          },
          onSubmitLabel: "delete-budget".tr(),
        );
      }
    }
    if (result == true) {
      if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
        popAllRoutes(context);
      } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
        popRoute(context);
      }
      openLoadingPopupTryCatch(() async {
        await database.deleteBudget(context, budget);
        openSnackbar(
          SnackbarMessage(
            title: "deleted-budget".tr(),
            icon: Icons.delete,
            description: budget.name,
          ),
        );
      });
    }
  }
  return action;
}

Future<dynamic> deleteSharedBudgetPopup(context, Budget budget) {
  if (budget.sharedOwnerMember == SharedOwnerMember.owner) {
    return openPopup(
      context,
      title: "Delete Shared Budget?",
      description:
          "You own this budget. Deleting it will remove it from the server. All transactions belonging to this budget will no longer be connected to a budget.",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.delete_outlined
          : Icons.delete_rounded,
      onCancel: () {
        popRoute(context, false);
      },
      onCancelLabel: "cancel".tr(),
      onSubmit: () async {
        popRoute(context, true);
      },
      onSubmitLabel: "delete".tr(),
    );
  } else {
    return openPopup(
      context,
      title: "Leave Shared Budget?",
      description:
          "You are a member of this budget. Deleting it will remove you from the shared group. All transactions belonging to this budget will no longer be connected to a budget, until you are added back.",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.delete_outlined
          : Icons.delete_rounded,
      onCancel: () {
        popRoute(context, false);
      },
      onCancelLabel: "cancel".tr(),
      onSubmit: () async {
        popRoute(context, true);
      },
      onSubmitLabel: "delete".tr(),
    );
  }
}

// either "none", null, or a Budget type
Future<dynamic> selectAddableBudgetPopup(BuildContext context,
    {String? removeWalletPk}) async {
  dynamic budget = await openBottomSheet(
    context,
    PopupFramework(
      title: "select-budget".tr(),
      child: StreamBuilder<List<Budget>>(
        stream: database.watchAllAddableBudgets(),
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              (snapshot.data != null && snapshot.data!.length > 0)) {
            List<Budget> addableBudgets = snapshot.data!;
            return RadioItems(
              ifNullSelectNone: true,
              items: [null, ...addableBudgets],
              colorFilter: (Budget? budget) {
                if (budget == null) return null;
                return dynamicPastel(
                  context,
                  lightenPastel(
                    HexColor(
                      budget.colour,
                      defaultColor: Theme.of(context).colorScheme.primary,
                    ),
                    amount: 0.2,
                  ),
                  amount: 0.1,
                );
              },
              displayFilter: (Budget? budget) {
                return budget?.name ?? "no-budget".tr();
              },
              initial: null,
              onChanged: (Budget? budget) async {
                if (budget == null)
                  popRoute(context, "none");
                else
                  popRoute(context, budget);
              },
              onLongPress: (Budget? budget) {
                pushRoute(
                  context,
                  AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    budget: budget,
                  ),
                );
              },
            );
          } else {
            return NoResultsCreate(
              message: "no-addable-budgets".tr(),
              buttonLabel: "create-addable-budget".tr(),
              route: AddBudgetPage(
                isAddedOnlyBudget: true,
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
              ),
            );
          }
        },
      ),
    ),
  );

  if (budget is Budget) return budget;
  if (budget == "none") return "none";
  return null;
}

class NoResultsCreate extends StatelessWidget {
  const NoResultsCreate(
      {required this.message,
      required this.buttonLabel,
      required this.route,
      super.key});
  final String message;
  final String buttonLabel;
  final Widget route;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
              child: TextFont(
                text: message.tr(),
                fontSize: 15,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        IntrinsicWidth(
          child: Button(
            label: buttonLabel.tr(),
            onTap: () {
              pushRoute(
                context,
                route,
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class BudgetSettings extends StatelessWidget {
  const BudgetSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return TotalSpentToggle();
  }
}

class TotalSpentToggle extends StatefulWidget {
  const TotalSpentToggle({bool this.isForGoalTotal = false, super.key});
  final bool isForGoalTotal; //Otherwise it's for the budget setting

  @override
  State<TotalSpentToggle> createState() => _TotalSpentToggleState();
}

class _TotalSpentToggleState extends State<TotalSpentToggle> {
  @override
  Widget build(BuildContext context) {
    String appSettingKey = widget.isForGoalTotal
        ? "showTotalSpentForObjective"
        : "showTotalSpentForBudget";
    String titleLabel = widget.isForGoalTotal
        ? "goal-total-type".tr()
        : "budget-total-type".tr();
    return SettingsContainer(
      title: titleLabel,
      description: appStateSettings[appSettingKey] == true
          ? "total-spent".tr().toLowerCase().capitalizeFirst
          : "total-remaining".tr().toLowerCase().capitalizeFirst,
      onTap: () {
        openBottomSheet(
          context,
          PopupFramework(
            title: titleLabel,
            child: RadioItems(
              items: ["total-remaining", "total-spent"],
              initial: appStateSettings[appSettingKey] == true
                  ? "total-spent"
                  : "total-remaining",
              displayFilter: (label) {
                return label.tr();
              },
              getDescription: (String label) {
                if (label == "total-remaining") {
                  return "total-remaining-example".tr();
                } else if (label == "total-spent") {
                  return "total-spent-example".tr();
                } else {
                  return "";
                }
              },
              onChanged: (option) async {
                bool result = option == "total-spent";
                if (widget.isForGoalTotal) {
                  await updateSettings(appSettingKey, result,
                      updateGlobalState: true);
                } else {
                  await updateSettings(appSettingKey, result,
                      pagesNeedingRefresh: [0, 2], updateGlobalState: false);
                }

                // Read the new settings value by setting state
                setState(() {});
                popRoute(context);
              },
            ),
          ),
        );
      },
      icon: appStateSettings["outlinedIcons"]
          ? Icons.center_focus_weak_outlined
          : Icons.center_focus_weak_rounded,
    );
  }
}

Future duplicateBudgetPopup(
  BuildContext context, {
  required Budget budget,
}) async {
  dynamic result = await openPopup(
    context,
    title: "duplicate-budget-question".tr(),
    subtitle: budget.name,
    onCancelLabel: "cancel".tr(),
    onCancel: () => Navigator.pop(context),
    onSubmitLabel: "duplicate".tr(),
    onSubmit: () => Navigator.pop(context, true),
  );
  if (result == true)
    openLoadingPopupTryCatch(
      () async {
        int? rowId = await database.createOrUpdateBudget(
          budget.copyWith(
            dateCreated: DateTime.now(),
            name: budget.name + " (" + "copy".tr() + ")",
          ),
          insert: true,
        );

        Budget? budgetJustAdded = null;
        budgetJustAdded = await database.getBudgetFromRowId(rowId);

        List<CategoryBudgetLimit> categoryLimits = await database
            .getAllCategorySpendingLimitsInBudget(budget.budgetPk);
        for (CategoryBudgetLimit categoryLimit in categoryLimits) {
          await database.createOrUpdateCategoryLimit(
            categoryLimit.copyWith(budgetFk: budgetJustAdded.budgetPk),
            insert: true,
          );
        }
        return budgetJustAdded;
      },
      onSuccess: (result) {
        if (result is Budget) {
          openSnackbar(
            SnackbarMessage(
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.file_copy_outlined
                  : Icons.file_copy_rounded,
              title: "created-copy".tr(),
              description: result.name,
            ),
          );
          Navigator.pop(context);
          pushRoute(
            context,
            AddBudgetPage(
              budget: result,
              routesToPopAfterDelete: RoutesToPopAfterDelete.One,
            ),
          );
        }
      },
    );
}
