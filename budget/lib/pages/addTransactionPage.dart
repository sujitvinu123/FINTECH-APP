import 'package:budget/database/generatePreviewData.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addCategoryPage.dart';
import 'package:budget/pages/addObjectivePage.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/editAssociatedTitlesPage.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/pages/sharedBudgetSettings.dart';
import 'package:budget/pages/transactionsListPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/upcomingTransactionsFunctions.dart';
import 'package:budget/struct/uploadAttachment.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:flutter/scheduler.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/incomeExpenseTabSelector.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/sliverStickyLabelDivider.dart';
import 'package:budget/widgets/timeDigits.dart';
import 'package:budget/struct/initializeNotifications.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/selectChips.dart';
import 'package:budget/widgets/saveBottomButton.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:budget/widgets/transactionEntry/transactionEntryTypeButton.dart';
import 'package:budget/widgets/transactionEntry/transactionLabel.dart';
import 'package:budget/widgets/util/contextMenu.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:budget/widgets/viewAllTransactionsButton.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/util/showTimePicker.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/iconButtonScaled.dart';
import 'package:budget/struct/linkHighlighter.dart';
import 'package:budget/widgets/listItem.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/tappableTextEntry.dart';

//TODO
//only show the tags that correspond to selected category
//put recent used tags at the top? when no category selected

dynamic transactionTypeDisplayToEnum = {
  "Default": null,
  "Upcoming": TransactionSpecialType.upcoming,
  "Subscription": TransactionSpecialType.subscription,
  "Repetitive": TransactionSpecialType.repetitive,
  "Borrowed": TransactionSpecialType.debt,
  "Lent": TransactionSpecialType.credit,
  null: "Default",
  TransactionSpecialType.upcoming: "Upcoming",
  TransactionSpecialType.subscription: "Subscription",
  TransactionSpecialType.repetitive: "Repetitive",
  TransactionSpecialType.debt: "Borrowed",
  TransactionSpecialType.credit: "Lent",
};

class AddTransactionPage extends StatefulWidget {
  AddTransactionPage({
    Key? key,
    this.transaction,
    this.selectedBudget,
    this.selectedType,
    this.selectedObjective,
    this.selectedIncome,
    this.useCategorySelectedIncome = false,
    this.selectedAmount,
    this.selectedTitle,
    this.selectedCategory,
    this.selectedSubCategory,
    this.selectedWallet,
    this.selectedDate,
    this.selectedNotes,
    this.startInitialAddTransactionSequence = true,
    this.transferBalancePopup = false,
    required this.routesToPopAfterDelete,
  }) : super(key: key);

  //When a transaction is passed in, we are editing that transaction
  final Transaction? transaction;
  final Budget? selectedBudget;
  final TransactionSpecialType? selectedType;
  final Objective? selectedObjective;
  final RoutesToPopAfterDelete routesToPopAfterDelete;
  final bool? selectedIncome;
  final bool useCategorySelectedIncome;
  final double? selectedAmount;
  final String? selectedTitle;
  final TransactionCategory? selectedCategory;
  final TransactionCategory? selectedSubCategory;
  final TransactionWallet? selectedWallet;
  final DateTime? selectedDate;
  final String? selectedNotes;
  final bool startInitialAddTransactionSequence;
  final bool transferBalancePopup;

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  TransactionCategory? selectedCategory;
  TransactionCategory? selectedSubCategory;
  double? selectedAmount;
  String? selectedAmountCalculation;
  String? selectedTitle;
  TransactionSpecialType? selectedType = null;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedEndDate = null;
  int selectedPeriodLength = 1;
  String selectedRecurrence = "Monthly";
  String selectedRecurrenceDisplay = "month";
  BudgetReoccurence selectedRecurrenceEnum = BudgetReoccurence.monthly;
  bool selectedIncome = false;
  bool initiallySettingSelectedIncome = false;
  String? selectedPayer;
  String? selectedObjectivePk;
  String? selectedObjectiveLoanPk;
  String? selectedBudgetPk;
  Budget? selectedBudget;
  bool selectedPaid = true;
  bool selectedBudgetIsShared = false;
  String selectedWalletPk = appStateSettings["selectedWalletPk"];
  bool notesInputFocused = false;
  bool showMoreOptions = false;
  List<String> selectedExcludedBudgetPks = [];
  late bool isAddedToLoanObjective =
      widget.selectedObjective?.type == ObjectiveType.loan ||
          widget.transaction?.objectiveLoanFk != null;
  // bool isSettingUpBalanceTransfer = false;

  String? textAddTransaction = "add-transaction".tr();

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked =
        await showCustomDatePicker(context, selectedEndDate ?? DateTime.now());
    if (picked != null) setSelectedEndDate(picked);
  }

  setSelectedEndDate(DateTime? date) {
    if (date != selectedEndDate) {
      setState(() {
        selectedEndDate = date;
      });
    }
  }

  void clearSelectedCategory() {
    setState(() {
      selectedCategory = null;
      selectedSubCategory = null;
    });
  }

  void setSelectedCategory(TransactionCategory category,
      {bool setIncome = true}) {
    if (isAddedToLoanObjective == false &&
        setIncome &&
        category.categoryPk != "0" &&
        selectedType != TransactionSpecialType.credit &&
        selectedType != TransactionSpecialType.debt) {
      setSelectedIncome(category.income);
    }
    setState(() {
      if (selectedCategory != category) selectedSubCategory = null;
      selectedCategory = category;
    });
    return;
  }

  void setSelectedSubCategory(TransactionCategory? category, {toggle = false}) {
    setState(() {
      if (category == null) {
        selectedSubCategory = null;
      } else if (selectedSubCategory?.categoryPk == category.categoryPk &&
          toggle) {
        selectedSubCategory = null;
      } else {
        selectedSubCategory = category;
      }
    });
    return;
  }

  void setSelectedAmount(double amount, String amountCalculation) {
    if (amount == double.infinity ||
        amount == double.negativeInfinity ||
        amount.isNaN) {
      return;
    }
    if (amount == selectedAmount) {
      selectedAmountCalculation = amountCalculation;
    } else {
      setState(() {
        selectedAmount = amount;
        selectedAmountCalculation = amountCalculation;
      });
    }
    return;
  }

  void setSelectedTitle(String title, {bool setInput = true}) {
    if (setInput) setTextInput(_titleInputController, title);
    selectedTitle = title.trim();
    return;
  }

  void setSelectedTitleController(String title, {bool setInput = true}) {
    if (setInput) setTextInput(_titleInputController, title);
    selectedTitle = title;
    return;
  }

  void setSelectedNoteController(String note, {bool setInput = true}) {
    if (setInput) setTextInput(_noteInputController, note);
    return;
  }

  void setSelectedType(String type) {
    setState(() {
      selectedType = transactionTypeDisplayToEnum[type];
      if (selectedType == TransactionSpecialType.credit) {
        selectedIncome = false;
      } else if (selectedType == TransactionSpecialType.debt) {
        selectedIncome = true;
      }

      if (widget.transaction != null &&
          selectedType == null &&
          widget.transaction?.type == null &&
          widget.transaction?.paid == false) {
        selectedPaid = false;
      } else if (widget.transaction != null && selectedType != null) {
        selectedPaid = widget.transaction!.paid;
      } else if (selectedType == null) {
        selectedPaid = true;
      } else {
        selectedPaid = false;
      }

      if ((widget.transaction?.type != TransactionSpecialType.credit &&
              selectedType == TransactionSpecialType.credit) ||
          (widget.transaction?.type != TransactionSpecialType.debt &&
              selectedType == TransactionSpecialType.debt)) {
        selectedPaid = true;
      }
      if ((widget.transaction?.type != TransactionSpecialType.subscription &&
              selectedType == TransactionSpecialType.subscription) ||
          (widget.transaction?.type != TransactionSpecialType.repetitive &&
              selectedType == TransactionSpecialType.repetitive) ||
          (widget.transaction?.type != TransactionSpecialType.upcoming &&
              selectedType == TransactionSpecialType.upcoming)) {
        selectedPaid = false;
      }
    });
    return;
  }

  void setSelectedPayer(String payer) {
    setState(() {
      selectedPayer = payer;
    });
    return;
  }

  void setSelectedBudgetPk(Budget? selectedBudgetPassed,
      {bool isSharedBudget = false}) {
    setState(() {
      selectedBudgetPk =
          selectedBudgetPassed == null ? null : selectedBudgetPassed.budgetPk;
      selectedBudget = selectedBudgetPassed;
      selectedBudgetIsShared = isSharedBudget;
      if (selectedBudgetPk != null && selectedPayer == null)
        selectedPayer = appStateSettings["currentUserEmail"] ?? "";
      if (isSharedBudget == false || selectedBudgetPassed?.sharedKey == null) {
        selectedPayer = null;
      }
    });
    return;
  }

  void setSelectedExcludedBudgetPks(List<String>? budgetPks) {
    setState(() {
      selectedExcludedBudgetPks = budgetPks ?? [];
    });
    return;
  }

  void setSelectedObjectivePk(String? selectedObjectivePkPassed) {
    setState(() {
      selectedObjectivePk = selectedObjectivePkPassed;
      setSelectedLoanObjectivePk(null);
    });
    return;
  }

  void setSelectedLoanObjectivePk(String? selectedLoanObjectivePkPassed) {
    setState(() {
      selectedObjectiveLoanPk = selectedLoanObjectivePkPassed;
      if (selectedLoanObjectivePkPassed == null) {
        isAddedToLoanObjective = false;
      } else {
        isAddedToLoanObjective = true;
        selectedObjectivePk = null;
        if (selectedType == TransactionSpecialType.credit ||
            selectedType == TransactionSpecialType.debt)
          setSelectedType("Default");
      }
    });
    return;
  }

  TransactionWallet? getSelectedWallet({required bool listen}) {
    return Provider.of<AllWallets>(context, listen: listen)
        .indexedByPk[selectedWalletPk];
  }

  void setSelectedIncome(bool value, {bool initiallySetting = false}) {
    setState(() {
      selectedIncome = value;
      initiallySettingSelectedIncome = initiallySetting;

      // Flip credit/debt selection if income/expense changed
      if (selectedType == TransactionSpecialType.credit &&
          selectedIncome == true) {
        setSelectedType("Borrowed");
      } else if (selectedType == TransactionSpecialType.debt &&
          selectedIncome == false) {
        setSelectedType("Lent");
      }
    });
  }

  void setSelectedWalletPk(String selectedWalletPkPassed) {
    setState(() {
      selectedWalletPk = selectedWalletPkPassed;
    });
  }

  Future<Transaction> addDefaultMissingValues(Transaction transaction) async {
    bool getSelectedPaid = selectedPaid;
    try {
      if ((widget.transaction?.budgetFksExclude?.length ?? 0) > 0) {
        getSelectedPaid = (await database
                .getTransactionFromPk(widget.transaction!.transactionPk))
            .paid;
      }
    } catch (e) {}

    return transaction.copyWith(
      reoccurrence:
          Value(transaction.reoccurrence ?? BudgetReoccurence.monthly),
      periodLength: Value(transaction.periodLength ?? 1),
      paid: getSelectedPaid,
    );
  }

  bool lockAddTransaction = false;
  Future<bool> addTransaction() async {
    if (lockAddTransaction) return false;
    lockAddTransaction = true;

    bool result = await addTransactionLocked();
    //Wait for the UI frame to finish updating to allow smooth animation afterwards
    await SchedulerBinding.instance.endOfFrame;

    lockAddTransaction = false;
    savingHapticFeedback();
    return result;
  }

  Future<bool> addTransactionLocked() async {
    if (appStateSettings["canShowTransactionActionButtonTip"] == true &&
        selectedType != null) {
      await openBottomSheet(
        context,
        fullSnap: true,
        PopupFramework(
          title: "transaction-type".tr(),
          child: Column(
            children: [
              SelectTransactionTypePopup(
                setTransactionType: (type) {},
                selectedTransactionType: null,
                onlyShowOneTransactionType: selectedType,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12),
                child: Row(
                  children: [
                    Flexible(
                      child: Button(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                        label: "do-not-show-again".tr(),
                        onTap: () {
                          updateSettings(
                              "canShowTransactionActionButtonTip", false,
                              updateGlobalState: false);
                          popRoute(context);
                        },
                        expandedLayout: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Button(
                        label: "ok".tr(),
                        onTap: () {
                          popRoute(context);
                        },
                        expandedLayout: true,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }
    try {
      print("Added transaction");
      if (selectedTitle != null &&
          selectedCategory != null &&
          selectedTitle != "") {
        // if (selectedSubCategory != null) {
        //   await addAssociatedTitles(selectedTitle!, selectedSubCategory!);
        // } else {
        //   await addAssociatedTitles(selectedTitle!, selectedCategory!);
        // }
        await addAssociatedTitles(selectedTitle!, selectedCategory!);
      }

      Transaction createdTransaction = await createTransaction();

      if (widget.transaction != null) {
        // Only ask if changes were made that will affect other balance correction
        // set in the logic of updateCloselyRelatedBalanceTransfer

        // If these fields are touched they will not trigger the popup
        if ((await addDefaultMissingValues(widget.transaction!)).copyWith(
              dateTimeModified: Value(null),
              walletFk: "",
              name: "",
              note: "",
              income: false,
              amount: widget.transaction!.amount.abs(),
              objectiveFk: Value(null),
              objectiveLoanFk: Value(null),
            ) !=
            createdTransaction.copyWith(
              dateTimeModified: Value(null),
              walletFk: "",
              name: "",
              note: "",
              income: false,
              amount: createdTransaction.amount.abs(),
              objectiveFk: Value(null),
              objectiveLoanFk: Value(null),
            )) {
          Transaction? closelyRelatedTransferCorrectionTransaction =
              await database.getCloselyRelatedBalanceCorrectionTransaction(
                  widget.transaction!);

          if (closelyRelatedTransferCorrectionTransaction != null) {
            await openPopup(
              context,
              title: "update-both-transfers-question".tr(),
              description: "update-both-transfers-question-description".tr(),
              descriptionWidget: IgnorePointer(
                child: Column(
                  children: [
                    HorizontalBreak(
                        padding:
                            EdgeInsetsDirectional.only(top: 15, bottom: 10)),
                    TransactionEntry(
                      useHorizontalPaddingConstrained: false,
                      openPage: Container(),
                      transaction: createTransaction(),
                      containerColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.4),
                      customPadding: EdgeInsetsDirectional.zero,
                    ),
                    SizedBox(height: 5),
                    TransactionEntry(
                      useHorizontalPaddingConstrained: false,
                      openPage: Container(),
                      transaction: closelyRelatedTransferCorrectionTransaction,
                      containerColor: Colors.transparent,
                      customPadding: EdgeInsetsDirectional.zero,
                    ),
                  ],
                ),
              ),
              onCancel: () {
                popRoute(context);
              },
              onCancelLabel: "only-current".tr(),
              onSubmit: () async {
                AllWallets allWallets =
                    Provider.of<AllWallets>(context, listen: false);
                await database.updateCloselyRelatedBalanceTransfer(
                  allWallets,
                  createdTransaction,
                  closelyRelatedTransferCorrectionTransaction,
                );
                popRoute(context);
              },
              onSubmitLabel: "update-both".tr(),
            );
          }
        }
      }

      final int? rowId = await database.createOrUpdateTransaction(
        insert: widget.transaction == null,
        createdTransaction,
        originalTransaction: widget.transaction,
      );

      if (rowId != null) {
        final Transaction transactionJustAdded =
            await database.getTransactionFromRowId(rowId);
        print("Transaction just added:");
        print(transactionJustAdded);

        // Do the flash animation only if the date was changed
        if (transactionJustAdded.dateCreated !=
            widget.transaction?.dateCreated) {
          flashTransaction(transactionJustAdded.transactionPk);

          // If a new transaction with an added date of 5 minutes of less before, flash only a bit
          if (widget.transaction == null &&
              transactionJustAdded.dateCreated.isAfter(
                DateTime.now().subtract(
                  Duration(minutes: 5),
                ),
              )) {
            flashTransaction(transactionJustAdded.transactionPk, flashCount: 2);
          } else {
            flashTransaction(transactionJustAdded.transactionPk);
          }
        }
      }

      if ([
        TransactionSpecialType.repetitive,
        TransactionSpecialType.subscription,
        TransactionSpecialType.upcoming
      ].contains(createdTransaction.type)) {
        setUpcomingNotifications(context);
      }

      // recentlyAddedTransactionID.value =

      if (widget.transaction == null &&
          appStateSettings["purchaseID"] == null) {
        updateSettings("premiumPopupAddTransactionCount",
            (appStateSettings["premiumPopupAddTransactionCount"] ?? 0) + 1,
            updateGlobalState: false);
      }

      return true;
    } catch (e) {
      if (e.toString() == "category-no-longer-exists") {
        openSnackbar(SnackbarMessage(
          title: "cannot-create-transaction".tr(),
          description: "category-no-longer-exists".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_amber_outlined
              : Icons.warning_amber_rounded,
        ));
        clearSelectedCategory();
      } else {
        openSnackbar(SnackbarMessage(
          title: "cannot-create-transaction".tr(),
          description: e.toString(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_amber_outlined
              : Icons.warning_amber_rounded,
        ));
      }
      return false;
    }
  }

  Transaction createTransaction({bool removeShared = false}) {
    bool? createdAnotherFutureTransaction = widget.transaction != null
        ? widget.transaction!.createdAnotherFutureTransaction
        : null;
    bool paid = widget.transaction != null
        ? widget.transaction!.paid
        : selectedType == null;
    bool skipPaid = widget.transaction != null
        ? widget.transaction!.skipPaid
        : selectedType == null;

    if (selectedType != null &&
        widget.transaction != null &&
        widget.transaction!.type != selectedType) {
      createdAnotherFutureTransaction = false;

      if ([TransactionSpecialType.credit, TransactionSpecialType.debt]
          .contains(selectedType)) {
        paid = true;
        skipPaid = false;
      } else {
        paid = false;
        skipPaid = false;
      }
    }

    Transaction createdTransaction = Transaction(
      transactionPk:
          widget.transaction != null ? widget.transaction!.transactionPk : "-1",
      pairedTransactionFk: widget.transaction?.pairedTransactionFk,
      name: (selectedTitle ?? "").trim(),
      amount: (selectedIncome || selectedAmount == 0 //Prevent negative 0
          ? (selectedAmount ?? 0).abs()
          : (selectedAmount ?? 0).abs() * -1),
      note: _noteInputController.text,
      categoryFk: selectedCategory?.categoryPk ?? "-1",
      subCategoryFk: selectedSubCategory?.categoryPk,
      dateCreated: selectedDate,
      endDate: selectedEndDate,
      dateTimeModified: null,
      income: selectedIncome,
      walletFk: selectedWalletPk,
      paid: selectedPaid,
      skipPaid: skipPaid,
      type: selectedType,
      reoccurrence: selectedRecurrenceEnum,
      periodLength: selectedPeriodLength <= 0 && selectedType != null
          ? 1
          : selectedPeriodLength,
      methodAdded:
          widget.transaction != null ? widget.transaction!.methodAdded : null,
      createdAnotherFutureTransaction: createdAnotherFutureTransaction,
      sharedKey: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedKey
          : null,
      sharedOldKey:
          widget.transaction != null ? widget.transaction!.sharedOldKey : null,
      transactionOwnerEmail: selectedPayer,
      transactionOriginalOwnerEmail:
          removeShared == false && widget.transaction != null
              ? widget.transaction!.transactionOriginalOwnerEmail
              : null,
      sharedStatus: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedStatus
          : null,
      sharedDateUpdated: removeShared == false && widget.transaction != null
          ? widget.transaction!.sharedDateUpdated
          : null,
      sharedReferenceBudgetPk: selectedBudgetPk,
      upcomingTransactionNotification: widget.transaction != null
          ? widget.transaction!.upcomingTransactionNotification
          : null,
      originalDateDue: widget.transaction != null
          ? widget.transaction!.originalDateDue
          : null,
      objectiveFk: selectedObjectivePk,
      objectiveLoanFk: selectedObjectiveLoanPk,
      budgetFksExclude:
          selectedExcludedBudgetPks.isEmpty ? null : selectedExcludedBudgetPks,
    );

    return createdTransaction;
  }

  Transaction? transactionInitial;

  // If a change was made, show the discard changes popup
  // When creating a new entry only
  void showDiscardChangesPopupIfNotEditing() {
    Transaction transactionCreated = createTransaction();
    if (transactionCreated != transactionInitial &&
        widget.transaction == null) {
      discardChangesPopup(context, forceShow: true);
    } else {
      popRoute(context);
    }
  }

  late TextEditingController _titleInputController;
  late TextEditingController _noteInputController;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      //We are editing a transaction
      //Fill in the information from the passed in transaction
      _titleInputController =
          new TextEditingController(text: widget.transaction!.name);
      _noteInputController =
          new LinkHighlighter(initialText: widget.transaction!.note);
      selectedTitle = widget.transaction!.name;
      selectedDate = widget.transaction!.dateCreated;
      selectedEndDate = widget.transaction!.endDate;
      selectedWalletPk = widget.transaction!.walletFk;
      selectedAmount = widget.transaction!.amount.abs();
      selectedType = widget.transaction!.type;
      selectedPeriodLength = widget.transaction!.periodLength ?? 1;
      selectedRecurrenceEnum =
          widget.transaction!.reoccurrence ?? BudgetReoccurence.monthly;
      selectedRecurrence = enumRecurrence[selectedRecurrenceEnum];
      if (selectedPeriodLength == 1) {
        selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
      } else {
        selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
      }
      selectedPaid = widget.transaction!.paid;
      selectedIncome = widget.transaction!.income;
      selectedPayer = widget.transaction!.transactionOwnerEmail;
      selectedBudgetPk = widget.transaction!.sharedReferenceBudgetPk;
      selectedObjectivePk = widget.transaction!.objectiveFk;
      selectedObjectiveLoanPk = widget.transaction!.objectiveLoanFk;
      selectedExcludedBudgetPks = widget.transaction!.budgetFksExclude ?? [];
      // var amountString = widget.transaction!.amount.toStringAsFixed(2);
      // if (amountString.substring(amountString.length - 2) == "00") {
      //   selectedAmountCalculation =
      //       amountString.substring(0, amountString.length - 3);
      // } else {
      //   selectedAmountCalculation = amountString;
      // }
      textAddTransaction = "save-changes".tr();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateInitial();
      });
    } else {
      if (widget.selectedType != null) {
        setSelectedType(transactionTypeDisplayToEnum[widget.selectedType]);
      }

      _titleInputController = new TextEditingController();
      _noteInputController = new LinkHighlighter();

      Future.delayed(Duration(milliseconds: 0), () async {
        if (widget.transferBalancePopup) {
          openTransferBalancePopup();
          return;
        }
        await premiumPopupAddTransaction(context);
        if (widget.startInitialAddTransactionSequence == false) return;
        if (appStateSettings["askForTransactionTitle"]) {
          openBottomSheet(
            context,
            // Only allow full snap when entering a title
            popupWithKeyboard: true,
            SelectTitle(
              selectedTitle: selectedTitle,
              setSelectedNote: setSelectedNoteController,
              setSelectedTitle: setSelectedTitleController,
              setSelectedCategory: setSelectedCategory,
              setSelectedSubCategory: setSelectedSubCategory,
              next: () {
                afterSetTitle();
              },
              noteInputController: _noteInputController,
              setSelectedNoteController: setSelectedNoteController,
              setSelectedDateTime: (DateTime date) {
                setState(() {
                  selectedDate = date;
                });
              },
              selectedDate: widget.selectedDate,
            ),
          );
        } else {
          afterSetTitle();
        }
      });
    }
    if (widget.selectedBudget != null) {
      selectedBudget = widget.selectedBudget;
      selectedBudgetPk = widget.selectedBudget!.budgetPk;
      selectedPayer = appStateSettings["currentUserEmail"];
      selectedBudgetIsShared = widget.selectedBudget!.sharedKey != null;
    }
    if (widget.selectedObjective != null) {
      if (widget.selectedObjective?.type == ObjectiveType.loan) {
        selectedObjectiveLoanPk = widget.selectedObjective!.objectivePk;
      } else {
        selectedObjectivePk = widget.selectedObjective!.objectivePk;
      }
    }
    if (widget.selectedAmount != null) {
      selectedAmount = (widget.selectedAmount ?? 0).abs();
      selectedIncome = (widget.selectedAmount ?? -1).isNegative == false;
    }
    if (widget.selectedCategory != null) {
      selectedCategory = widget.selectedCategory;
      if (widget.useCategorySelectedIncome)
        selectedIncome = selectedCategory?.income ?? selectedIncome;
    }
    if (widget.selectedSubCategory != null) {
      selectedSubCategory = widget.selectedSubCategory;
    }
    if (widget.selectedTitle != null) {
      selectedTitle = widget.selectedTitle;
      Future.delayed(Duration.zero, () {
        setSelectedTitle(widget.selectedTitle ?? "");
      });
    }
    if (widget.selectedIncome != null) {
      selectedIncome = widget.selectedIncome!;
    }
    if (widget.selectedWallet != null) {
      selectedWalletPk = widget.selectedWallet!.walletPk;
    }
    if (widget.selectedDate != null) {
      selectedDate = widget.selectedDate!;
    }
    if (widget.selectedNotes != null) {
      setSelectedNoteController(widget.selectedNotes ?? "");
    }
    if (widget.transaction == null) {
      Future.delayed(Duration.zero, () {
        transactionInitial = createTransaction();
      });
    }

    setState(() {});
  }

  updateInitial() async {
    if (widget.transaction != null) {
      TransactionCategory? getSelectedCategory =
          await database.getCategoryInstance(widget.transaction!.categoryFk);

      TransactionCategory? getSelectedSubCategory =
          widget.transaction!.subCategoryFk == null
              ? null
              : await database.getCategoryInstanceOrNull(
                  widget.transaction!.subCategoryFk!);
      Budget? getBudget;
      try {
        getBudget = await database.getBudgetInstance(
            widget.transaction!.sharedReferenceBudgetPk ?? "-1");
      } catch (e) {}

      // Fix the default value when a transaction is opened but excluded from a budget
      bool getSelectedPaid = selectedPaid;
      try {
        if ((widget.transaction?.budgetFksExclude?.length ?? 0) > 0) {
          getSelectedPaid = (await database
                  .getTransactionFromPk(widget.transaction!.transactionPk))
              .paid;
        }
      } catch (e) {}

      setState(() {
        selectedPaid = getSelectedPaid;
        selectedCategory = getSelectedCategory;
        selectedSubCategory = getSelectedSubCategory;
        selectedBudget = getBudget;
        selectedBudgetIsShared =
            getBudget == null ? false : getBudget.sharedKey != null;
      });
    }
  }

  Future afterSetTitle() async {
    MainAndSubcategory mainAndSubcategory = await selectCategorySequence(
      context,
      selectedCategory: selectedCategory,
      setSelectedCategory: (TransactionCategory category) {
        setSelectedCategory(category,
            setIncome: initiallySettingSelectedIncome == false);
      },
      selectedSubCategory: selectedSubCategory,
      setSelectedSubCategory: setSelectedSubCategory,
      setSelectedIncome: (value) {
        setSelectedIncome(value == true, initiallySetting: value != null);
      },
      skipIfSet: true,
      selectedIncomeInitial: null,
      extraWidgetAfter: Column(
        children: [
          SelectAddedBudget(
            setSelectedBudget: setSelectedBudgetPk,
            selectedBudgetPk: selectedBudgetPk,
            extraHorizontalPadding: 13,
            wrapped: false,
          ),
          SelectObjective(
            setSelectedObjective: setSelectedObjectivePk,
            selectedObjectivePk: selectedObjectivePk,
            extraHorizontalPadding: 13,
            wrapped: false,
            objectiveType: ObjectiveType.goal,
          ),
        ],
      ),
    );

    if (mainAndSubcategory.main != null &&
        mainAndSubcategory.ignoredSubcategorySelection == false) {
      selectAmountPopup(
        next: () async {
          await addTransaction();
          popRoute(context);
          popRoute(context);
        },
        nextLabel: textAddTransaction,
      );
    }
  }

  selectAmountPopup({VoidCallback? next, String? nextLabel}) async {
    await openBottomSheet(
      context,
      fullSnap: true,
      PopupFramework(
        title: "enter-amount".tr(),
        hasPadding: false,
        underTitleSpace: false,
        child: SelectAmount(
          enableWalletPicker: true,
          selectedWalletPk: selectedWalletPk,
          setSelectedWalletPk: setSelectedWalletPk,
          padding: EdgeInsetsDirectional.symmetric(horizontal: 18),
          walletPkForCurrency: selectedWalletPk,
          // onlyShowCurrencyIcon:
          //     appStateSettings[
          //             "selectedWalletPk"] ==
          //         selectedWalletPk,
          onlyShowCurrencyIcon: true,
          amountPassed: (selectedAmount ?? "0").toString(),
          setSelectedAmount: setSelectedAmount,
          next: next ??
              () async {
                popRoute(context);
              },
          nextLabel: nextLabel ?? "set-amount".tr(),
        ),
      ),
    );
  }

  // void initializeBalanceTransfer() async {
  //   if (isSettingUpBalanceTransfer == false) {
  //     isSettingUpBalanceTransfer = true;
  //     TransactionCategory balanceCorrectionCategory =
  //         await initializeBalanceCorrectionCategory();
  //     setSelectedCategory(balanceCorrectionCategory);
  //     setSelectedWalletPk(appStateSettings["selectedWalletPk"]);
  //     setState(() {});
  //   }
  // }

  // void resetInitializeBalanceTransfer() {
  //   if (isSettingUpBalanceTransfer == true) {
  //     print("RESET");
  //     clearSelectedCategory();
  //     setState(() {
  //       isSettingUpBalanceTransfer = false;
  //     });
  //   }
  // }

  Future openTransferBalancePopup() async {
    bool? initialIsNegative;
    if (selectedObjectiveLoanPk != null) {
      initialIsNegative = selectedIncome;
    }
    dynamic result = await openBottomSheet(
      context,
      fullSnap: true,
      TransferBalancePopup(
        allowEditWallet: true,
        wallet: Provider.of<AllWallets>(context, listen: false)
            .indexedByPk[appStateSettings["selectedWalletPk"]]!,
        showAllEditDetails: true,
        initialAmount: selectedAmount,
        initialDate: selectedDate,
        initialTitle: selectedTitle,
        initialObjectiveLoanPk: selectedObjectiveLoanPk,
        initialIsNegative: initialIsNegative,
      ),
    );
    if (result == true) {
      popRoute(context);
    }
  }

  void openSelectSpecialTransactionTypeInfo() {
    openBottomSheet(
      context,
      fullSnap: false,
      PopupFramework(
        title: "select-transaction-type".tr(),
        child: SelectTransactionTypePopup(
          setTransactionType: (type) {
            setSelectedType(
              transactionTypeDisplayToEnum[type],
            );
          },
          selectedTransactionType: selectedType,
          transactionTypesToShow:
              getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
            widget.selectedType,
            isAddedToLoanObjective,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color categoryColor = dynamicPastel(
      context,
      HexColor(
        selectedCategory?.colour,
        defaultColor: dynamicPastel(
          context,
          Theme.of(context).colorScheme.primary,
          amount: appStateSettings["materialYou"] ? 0.55 : 0.2,
        ),
      ),
      amount: 0.35,
    );

    Widget transactionTextInput = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        enableDoubleColumn(context)
            ? Container(height: 20)
            : Container(height: 10),
        TitleInput(
          clearWhenUnfocused: true,
          tryToCompleteSearch: true,
          setSelectedTitle: (title) {
            setSelectedTitle(title, setInput: false);
          },
          titleInputController: _titleInputController,
          setSelectedCategory: setSelectedCategory,
          setSelectedSubCategory: setSelectedSubCategory,
        ),
        Container(height: 14),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
          child: TransactionNotesTextInput(
            noteInputController: _noteInputController,
            setNotesInputFocused: (isFocused) {
              setState(() {
                notesInputFocused = isFocused;
              });
            },
            setSelectedNoteController: setSelectedNoteController,
          ),
        ),
      ],
    );

    Widget transactionDetailsParameters = Flexible(
      child: Container(
        constraints: BoxConstraints(maxWidth: 900),
        child: FractionallySizedBox(
          widthFactor: enableDoubleColumn(context) == false ? 1 : 0.95,
          child: Column(
            children: [
              Container(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: DateButton(
                    internalPadding: EdgeInsetsDirectional.only(
                        start: 12, bottom: 6, top: 6, end: 8),
                    key: ValueKey(selectedDate.toString()),
                    initialSelectedDate: selectedDate,
                    initialSelectedTime: TimeOfDay(
                        hour: selectedDate.hour, minute: selectedDate.minute),
                    setSelectedDate: (date) {
                      selectedDate = date;
                    },
                    setSelectedTime: (time) {
                      selectedDate = selectedDate.copyWith(
                          hour: time.hour, minute: time.minute);
                    },
                  ),
                ),
              ),
              enableDoubleColumn(context) == false
                  ? SizedBox(height: 5)
                  : SizedBox.shrink(),
              HorizontalBreakAbove(
                enabled: enableDoubleColumn(context),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 5),
                  child: SelectChips(
                    allowMultipleSelected: false,
                    wrapped: enableDoubleColumn(context),
                    onLongPress: (item) {
                      openSelectSpecialTransactionTypeInfo();
                    },
                    extraWidgetBefore: Transform.scale(
                      scale: 1.3,
                      child: IconButton(
                        padding: EdgeInsetsDirectional.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          appStateSettings["outlinedIcons"]
                              ? Icons.info_outlined
                              : Icons.info_outline_rounded,
                          size: 19,
                        ),
                        onPressed: openSelectSpecialTransactionTypeInfo,
                      ),
                    ),
                    items:
                        getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
                            widget.selectedType, isAddedToLoanObjective),
                    getLabel: (item) {
                      if (item is TransactionSpecialType || item == null) {
                        return transactionTypeDisplayToEnum[item]
                                ?.toString()
                                .toLowerCase()
                                .tr() ??
                            "";
                      } else {
                        return "installments".tr();
                      }
                    },
                    onSelected: (item) async {
                      if (item == "installments") {
                        openPopup(
                          context,
                          title: "track-installments".tr(),
                          description: "track-installments-description".tr(),
                          icon: navBarIconsData["goals"]!.iconData,
                          onSubmit: () async {
                            popRoute(context);
                            dynamic result = await startCreatingInstallment(
                                context: context);
                            if (result == true) popRoute(context);
                          },
                          onSubmitLabel: "ok".tr(),
                          onCancel: () {
                            popRoute(context);
                          },
                          onCancelLabel: "cancel".tr(),
                        );
                      } else if (item is TransactionSpecialType ||
                          item == null) {
                        setSelectedType(transactionTypeDisplayToEnum[item]);
                      }
                    },
                    getSelected: (item) {
                      if (item is TransactionSpecialType || item == null) {
                        return selectedType == item;
                      } else {
                        return false;
                      }
                    },
                  ),
                ),
              ),
              AnimatedExpanded(
                expand: selectedType == TransactionSpecialType.repetitive ||
                    selectedType == TransactionSpecialType.subscription,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 9),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextFont(
                              text: "repeat-every".tr(),
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TappableTextEntry(
                                  addTappableBackground: true,
                                  title: selectedPeriodLength.toString(),
                                  placeholder: "0",
                                  showPlaceHolderWhenTextEquals: "0",
                                  onTap: () {
                                    selectPeriodLength(
                                      context: context,
                                      selectedPeriodLength:
                                          selectedPeriodLength,
                                      setSelectedPeriodLength: (period) =>
                                          setSelectedPeriodLength(
                                        period: period,
                                        selectedRecurrence: selectedRecurrence,
                                        setPeriodLength: (selectedPeriodLength,
                                            selectedRecurrenceDisplay) {
                                          this.selectedPeriodLength =
                                              selectedPeriodLength;
                                          this.selectedRecurrenceDisplay =
                                              selectedRecurrenceDisplay;
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  internalPadding:
                                      EdgeInsetsDirectional.symmetric(
                                          vertical: 4, horizontal: 6),
                                  padding: EdgeInsetsDirectional.symmetric(
                                      vertical: 0, horizontal: 4),
                                ),
                                TappableTextEntry(
                                  addTappableBackground: true,
                                  title: selectedRecurrenceDisplay
                                      .toString()
                                      .toLowerCase()
                                      .tr()
                                      .toLowerCase(),
                                  placeholder: "",
                                  onTap: () {
                                    selectRecurrence(
                                      context: context,
                                      selectedRecurrence: selectedRecurrence,
                                      selectedPeriodLength:
                                          selectedPeriodLength,
                                      onChanged: (selectedRecurrence,
                                          selectedRecurrenceEnum,
                                          selectedRecurrenceDisplay) {
                                        this.selectedRecurrence =
                                            selectedRecurrence;
                                        this.selectedRecurrenceEnum =
                                            selectedRecurrenceEnum;
                                        this.selectedRecurrenceDisplay =
                                            selectedRecurrenceDisplay;
                                        setState(() {});
                                      },
                                    );
                                  },
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  internalPadding:
                                      EdgeInsetsDirectional.symmetric(
                                          vertical: 4, horizontal: 6),
                                  padding: EdgeInsetsDirectional.symmetric(
                                      vertical: 0, horizontal: 3),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedExpanded(
                              expand: selectedEndDate != null,
                              axis: Axis.horizontal,
                              child: TextFont(
                                text: "until".tr(),
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Flexible(
                              child: TappableTextEntry(
                                title: (selectedEndDate == null
                                    ? ""
                                    : getWordedDateShort(
                                        selectedEndDate!,
                                        includeYear: selectedEndDate!.year !=
                                            DateTime.now().year,
                                      )),
                                placeholder: selectedObjectiveLoanPk != null
                                    ? "until-loan-reached".tr()
                                    : selectedObjectivePk != null
                                        ? "until-goal-reached".tr()
                                        : "until-forever".tr(),
                                showPlaceHolderWhenTextEquals: "",
                                onTap: () {
                                  selectEndDate(context);
                                },
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                internalPadding:
                                    EdgeInsetsDirectional.symmetric(
                                        vertical: 5, horizontal: 4),
                                padding: EdgeInsetsDirectional.symmetric(
                                    vertical: 0, horizontal: 5),
                              ),
                            ),
                            Builder(builder: (context) {
                              int? numberRepeats = widget.transaction
                                          ?.createdAnotherFutureTransaction ==
                                      true
                                  ? null
                                  : countTransactionOccurrences(
                                      type: selectedType,
                                      reoccurrence: selectedRecurrenceEnum,
                                      periodLength: selectedPeriodLength,
                                      dateCreated: selectedDate,
                                      endDate: selectedEndDate,
                                    );
                              return AnimatedSizeSwitcher(
                                child: numberRepeats != null
                                    ? Padding(
                                        padding: const EdgeInsetsDirectional
                                            .symmetric(horizontal: 4),
                                        child: TextFont(
                                          key: ValueKey(1),
                                          fontSize: 14.5,
                                          textColor:
                                              getColor(context, "textLight"),
                                          text: "( ×" +
                                              numberRepeats.toString() +
                                              " )",
                                        ),
                                      )
                                    : Container(
                                        key: ValueKey(2),
                                      ),
                              );
                            }),
                            AnimatedSizeSwitcher(
                              child: selectedEndDate != null
                                  ? Opacity(
                                      key: ValueKey(1),
                                      opacity: 0.5,
                                      child: IconButtonScaled(
                                        tooltip: "clear".tr(),
                                        iconData: Icons.close_rounded,
                                        iconSize: 16,
                                        scale: 1.5,
                                        onTap: () {
                                          setSelectedEndDate(null);
                                        },
                                      ),
                                    )
                                  : Container(
                                      key: ValueKey(2),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Wallet picker is in Select Amount... consider removing?
              Provider.of<AllWallets>(context).list.length <= 1
                  ? SizedBox.shrink()
                  : HorizontalBreakAbove(
                      enabled: enableDoubleColumn(context),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        child: SelectChips(
                          wrapped: enableDoubleColumn(context),
                          extraWidgetBeforeSticky: true,
                          allowMultipleSelected: false,
                          onLongPress: (TransactionWallet wallet) {
                            pushRoute(
                              context,
                              AddWalletPage(
                                wallet: wallet,
                                routesToPopAfterDelete:
                                    RoutesToPopAfterDelete.PreventDelete,
                              ),
                            );
                          },
                          items: Provider.of<AllWallets>(context).list,
                          getSelected: (TransactionWallet wallet) {
                            return getSelectedWallet(listen: false)?.walletPk ==
                                wallet.walletPk;
                          },
                          onSelected: (TransactionWallet wallet) {
                            setSelectedWalletPk(wallet.walletPk);
                          },
                          extraWidgetBefore: Provider.of<AllWallets>(context,
                                              listen: false)
                                          .indexedByPk
                                          .length >
                                      3 &&
                                  enableDoubleColumn(context) == false
                              ? SelectChipsAddButtonExtraWidget(
                                  openPage: null,
                                  onTap: () async {
                                    dynamic result = await selectWalletPopup(
                                      context,
                                      selectedWallet: Provider.of<AllWallets>(
                                              context,
                                              listen: false)
                                          .indexedByPk[selectedWalletPk],
                                      allowEditWallet: true,
                                      allowDeleteWallet: false,
                                    );
                                    if (result is TransactionWallet) {
                                      setSelectedWalletPk(result.walletPk);
                                    }
                                  },
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.expand_more_outlined
                                      : Icons.expand_more_rounded,
                                )
                              : null,
                          getCustomBorderColor: (TransactionWallet item) {
                            return dynamicPastel(
                              context,
                              lightenPastel(
                                HexColor(
                                  item.colour,
                                  defaultColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                amount: 0.3,
                              ),
                              amount: 0.4,
                            );
                          },
                          getLabel: (TransactionWallet wallet) {
                            return getWalletStringName(
                                Provider.of<AllWallets>(context), wallet);
                          },
                          extraWidgetAfter: SelectChipsAddButtonExtraWidget(
                            openPage: AddWalletPage(
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.None,
                            ),
                          ),
                        ),
                      ),
                    ),
              SelectAddedBudget(
                selectedBudgetPk: selectedBudgetPk,
                setSelectedBudget: setSelectedBudgetPk,
                horizontalBreak: true,
              ),
              AnimatedExpanded(
                axis: Axis.vertical,
                expand: isAddedToLoanObjective == false,
                child: SelectObjective(
                  setSelectedObjective: setSelectedObjectivePk,
                  selectedObjectivePk: selectedObjectivePk,
                  horizontalBreak: true,
                  objectiveType: ObjectiveType.goal,
                ),
              ),
              SelectObjective(
                setSelectedObjective: setSelectedLoanObjectivePk,
                selectedObjectivePk: selectedObjectiveLoanPk,
                setSelectedIncome: setSelectedIncome,
                horizontalBreak: true,
                objectiveType: ObjectiveType.loan,
              ),
              AnimatedExpanded(
                expand:
                    selectedBudgetPk != null && selectedBudgetIsShared == true,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 5),
                  child: SelectChips(
                    allowMultipleSelected: false,
                    wrapped: enableDoubleColumn(context),
                    items: <String>[...(selectedBudget?.sharedMembers ?? [])],
                    getLabel: (String item) {
                      return getMemberNickname(item);
                    },
                    onSelected: (String item) {
                      setSelectedPayer(item);
                    },
                    getSelected: (String item) {
                      return selectedPayer == item;
                    },
                    onLongPress: (String item) {
                      memberPopup(context, item);
                    },
                  ),
                ),
              ),
              enableDoubleColumn(context)
                  ? SizedBox.shrink()
                  : transactionTextInput,
              SizedBox(height: 10),
              AnimatedExpanded(
                expand: showMoreOptions == false &&
                    selectedType == null &&
                    widget.transaction?.paid == false,
                child: Column(
                  children: [
                    HorizontalBreakAbove(
                      enabled: enableDoubleColumn(context),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 22,
                          end: 22,
                          bottom: 8,
                          top: 5,
                        ),
                        child: SelectIncludeAmount(
                          selectedPaid: selectedPaid,
                          onSwitched: (value) {
                            setState(() {
                              selectedPaid = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedExpanded(
                  expand: showMoreOptions == false &&
                      widget.transaction?.budgetFksExclude != null,
                  child: Column(
                    children: [
                      HorizontalBreakAbove(
                        enabled: enableDoubleColumn(context),
                        child: StickyLabelDivider(
                          info: "exclude-from-budget".tr(),
                        ),
                      ),
                      SelectExcludeBudget(
                        setSelectedExcludedBudgets:
                            setSelectedExcludedBudgetPks,
                        selectedExcludedBudgetPks: selectedExcludedBudgetPks,
                      ),
                    ],
                  )),
              AnimatedSizeSwitcher(
                child: showMoreOptions == false
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        child: LowKeyButton(
                          key: ValueKey(1),
                          onTap: () {
                            setState(() {
                              showMoreOptions = true;
                            });
                          },
                          text: "more-options".tr(),
                        ),
                      )
                    : Column(
                        key: ValueKey(2),
                        children: [
                          HorizontalBreakAbove(
                            enabled: enableDoubleColumn(context) &&
                                (selectedType == null ||
                                    widget.transaction != null),
                            child: Column(
                              children: [
                                if (selectedType == null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 22,
                                      end: 22,
                                      bottom: 8,
                                      top: 5,
                                    ),
                                    child: SelectIncludeAmount(
                                      selectedPaid: selectedPaid,
                                      onSwitched: (value) {
                                        setState(() {
                                          selectedPaid = value;
                                        });
                                      },
                                    ),
                                  ),
                                if (widget.transaction != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 22,
                                      end: 22,
                                      bottom: 8,
                                      top: 5,
                                    ),
                                    child: Button(
                                      flexibleLayout: true,
                                      icon: appStateSettings["outlinedIcons"]
                                          ? Icons.file_copy_outlined
                                          : Icons.file_copy_rounded,
                                      label: "duplicate".tr(),
                                      onTap: () async {
                                        bool result = await addTransaction();
                                        if (result) popRoute(context);
                                        duplicateTransaction(context,
                                            widget.transaction!.transactionPk);
                                      },
                                      onLongPress: () async {
                                        bool result = await addTransaction();
                                        if (result) popRoute(context);
                                        duplicateTransaction(context,
                                            widget.transaction!.transactionPk,
                                            useCurrentDate: true);
                                      },
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      textColor: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          HorizontalBreakAbove(
                            enabled: enableDoubleColumn(context),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(top: 4),
                              child: StickyLabelDivider(
                                info: "exclude-from-budget".tr(),
                              ),
                            ),
                          ),
                          SelectExcludeBudget(
                            setSelectedExcludedBudgets:
                                setSelectedExcludedBudgetPks,
                            selectedExcludedBudgetPks:
                                selectedExcludedBudgetPks,
                          ),
                        ],
                      ),
              ),

              if (appStateSettings["showTransactionPk"] == true ||
                  appStateSettings["showMethodAdded"] == true)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 10, end: 10, top: 10),
                  child: Column(
                    children: [
                      if (widget.transaction?.methodAdded != null &&
                          appStateSettings["showMethodAdded"] == true)
                        TextFont(
                          text: "Added via: " +
                              (widget.transaction?.methodAdded?.name
                                      .toString()
                                      .capitalizeFirstofEach ??
                                  ""),
                          fontSize: 13,
                          textColor: getColor(context, "textLight"),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                        ),
                      if (appStateSettings["showTransactionPk"] == true)
                        TextFont(
                          text: widget.transaction?.transactionPk ?? "",
                          fontSize: 13,
                          textColor: getColor(context, "textLight"),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                        ),
                    ],
                  ),
                ),

              widget.transaction == null ||
                      widget.transaction!.sharedDateUpdated == null
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10, vertical: 28),
                      child: TextFont(
                        text: "synced".tr() +
                            " " +
                            getTimeAgo(
                              widget.transaction!.sharedDateUpdated!,
                            ).toLowerCase() +
                            "\n Created by " +
                            (widget.transaction!
                                    .transactionOriginalOwnerEmail ??
                                ""),
                        fontSize: 13,
                        textColor: getColor(context, "textLight"),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );

    bool enableBalanceTransferTab = widget.transaction == null &&
        Provider.of<AllWallets>(context).indexedByPk.keys.length > 1;

    Widget transactionAmountAndCategoryHeader = AnimatedContainer(
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300),
      color: categoryColor,
      child: Column(
        children: [
          GestureDetector(
            onLongPress: () async {
              if (enableBalanceTransferTab) {
                await openBottomSheet(
                  context,
                  PopupFramework(
                    hasPadding: false,
                    child: ShowTransactionsBalanceTransferTabSettingToggle(),
                  ),
                );
                setState(() {});
              }
            },
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: IncomeExpenseTabSelector(
                      hasBorderRadius: false,
                      onTabChanged: setSelectedIncome,
                      initialTabIsIncome: selectedIncome,
                      syncWithInitial: true,
                      color: categoryColor,
                      unselectedColor: Colors.black.withOpacity(0.2),
                      unselectedLabelColor: Colors.white.withOpacity(0.3),
                      incomeLabel: isAddedToLoanObjective
                          ? "collected".tr()
                          : selectedType == TransactionSpecialType.debt ||
                                  selectedType == TransactionSpecialType.credit
                              ? "borrowed".tr()
                              : selectedCategory?.categoryPk == "0"
                                  ? "transfer-in".tr()
                                  : null,
                      incomeIconColor: isAddedToLoanObjective ||
                              selectedType == TransactionSpecialType.debt ||
                              selectedType == TransactionSpecialType.credit
                          ? getColor(context, "unPaidOverdue")
                          : null,
                      expenseLabel: isAddedToLoanObjective
                          ? "paid".tr()
                          : selectedType == TransactionSpecialType.debt ||
                                  selectedType == TransactionSpecialType.credit
                              ? "lent".tr()
                              : selectedCategory?.categoryPk == "0"
                                  ? "transfer-out".tr()
                                  : null,
                      expenseIconColor: isAddedToLoanObjective ||
                              selectedType == TransactionSpecialType.debt ||
                              selectedType == TransactionSpecialType.credit
                          ? getColor(context, "unPaidUpcoming")
                          : null,
                    ),
                  ),
                  if (appStateSettings["showTransactionsBalanceTransferTab"] ==
                          true &&
                      enableBalanceTransferTab)
                    Flexible(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: Tappable(
                              color: Colors.black.withOpacity(0.2),
                              onTap: () async {
                                openTransferBalancePopup();
                              },
                              child: ExpenseIncomeSelectorLabel(
                                selectedIncome: false,
                                showIcons: false,
                                label: "transfer".tr(),
                                isIncome: true,
                                customIcon: Icon(
                                  appStateSettings["outlinedIcons"]
                                      ? Icons.compare_arrows_outlined
                                      : Icons.compare_arrows_rounded,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Tappable(
                onLongPress: () async {
                  await pushRoute(
                    context,
                    AddCategoryPage(
                      category: selectedCategory,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  );
                  if (selectedCategory != null) {
                    TransactionCategory category = await database
                        .getCategory(selectedCategory!.categoryPk)
                        .$2;
                    setSelectedCategory(category,
                        setIncome: selectedCategory?.income != category.income);
                  }
                },
                onTap: () async {
                  //resetInitializeBalanceTransfer();
                  await selectCategorySequence(
                    context,
                    selectedCategory: selectedCategory,
                    setSelectedCategory: setSelectedCategory,
                    selectedSubCategory: selectedSubCategory,
                    setSelectedSubCategory: setSelectedSubCategory,
                    skipIfSet: false,
                    selectedIncomeInitial: selectedIncome,
                  );
                },
                color: Colors.transparent,
                child: Container(
                  height: 136,
                  padding: const EdgeInsetsDirectional.only(start: 17, end: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: CategoryIcon(
                          tintEnabled: false,
                          canEditByLongPress: false,
                          noBackground: true,
                          key: ValueKey(selectedCategory?.categoryPk ?? ""),
                          category: selectedCategory,
                          size: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomContextMenu(
                  buttonItems: [
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.copy,
                      onPressed: () {
                        ContextMenuController.removeAny();
                        copyToClipboard(
                          convertToMoney(
                            Provider.of<AllWallets>(context, listen: false),
                            currencyKey:
                                Provider.of<AllWallets>(context, listen: false)
                                    .indexedByPk[selectedWalletPk]
                                    ?.currency,
                            selectedAmount ?? 0,
                            finalNumber: selectedAmount ?? 0,
                            decimals:
                                getSelectedWallet(listen: false)?.decimals,
                          ),
                        );
                      },
                    ),
                    ContextMenuButtonItem(
                      type: ContextMenuButtonType.paste,
                      onPressed: () async {
                        ContextMenuController.removeAny();
                        double? amount = await readAmountFromClipboard();
                        if (amount != null) {
                          setSelectedAmount(amount, amount.toString());
                        }
                      },
                    ),
                  ],
                  tappableBuilder: (onLongPress) {
                    return Tappable(
                      color: Colors.transparent,
                      onLongPress: onLongPress,
                      onTap: selectAmountPopup,
                      child: Container(
                        padding: const EdgeInsetsDirectional.only(end: 37),
                        height: 136,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(height: 5),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 350),
                              child: Align(
                                key: ValueKey(selectedWalletPk.toString() +
                                    selectedAmount.toString()),
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextFont(
                                  textAlign: TextAlign.end,
                                  text: convertToMoney(
                                    Provider.of<AllWallets>(context),
                                    selectedAmount ?? 0,
                                    decimals: getSelectedWallet(listen: true)
                                        ?.decimals,
                                    currencyKey: getSelectedWallet(listen: true)
                                        ?.currency,
                                    addCurrencyName:
                                        ((getSelectedWallet(listen: true)
                                                ?.currency) !=
                                            Provider.of<AllWallets>(context)
                                                .indexedByPk[appStateSettings[
                                                    "selectedWalletPk"]]
                                                ?.currency),
                                  ),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 1,
                                  autoSizeText: true,
                                ),
                              ),
                            ),
                            Provider.of<AllWallets>(context).list.length <= 1 ||
                                    selectedWalletPk ==
                                        appStateSettings["selectedWalletPk"] ||
                                    ((getSelectedWallet(listen: true)
                                            ?.currency) ==
                                        Provider.of<AllWallets>(context)
                                            .indexedByPk[appStateSettings[
                                                "selectedWalletPk"]]
                                            ?.currency)
                                ? AnimatedSizeSwitcher(
                                    switcherDuration:
                                        Duration(milliseconds: 350),
                                    child: Container(
                                      key: ValueKey(
                                          selectedCategory?.name ?? ""),
                                      width: double.infinity,
                                      child: TextFont(
                                        textAlign: TextAlign.end,
                                        fontSize: 18,
                                        text: selectedCategory?.name ?? "",
                                        maxLines: 2,
                                      ),
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: Duration(milliseconds: 350),
                                    child: Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextFont(
                                        textAlign: TextAlign.end,
                                        text: convertToMoney(
                                          Provider.of<AllWallets>(context),
                                          (selectedAmount ?? 0) *
                                              (amountRatioToPrimaryCurrencyGivenPk(
                                                  Provider.of<AllWallets>(
                                                      context),
                                                  selectedWalletPk)),
                                        ),
                                        fontSize: 18,
                                        maxLines: 1,
                                        autoSizeText: true,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (selectedCategory != null)
            SelectSubcategoryChips(
              setSelectedSubCategory: (category) {
                setSelectedSubCategory(category, toggle: true);
              },
              selectedCategoryPk: selectedCategory!.categoryPk,
              selectedSubCategoryPk: selectedSubCategory?.categoryPk,
              padding: const EdgeInsetsDirectional.only(bottom: 6),
            )
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        if (widget.transaction != null) {
          discardChangesPopup(
            context,
            previousObject: await addDefaultMissingValues(widget.transaction!),
            currentObject: await createTransaction(),
          );
        } else {
          showDiscardChangesPopupIfNotEditing();
        }
        return false;
      },
      child: PageFramework(
        belowAppBarPaddingWhenCenteredTitleSmall: 0,
        resizeToAvoidBottomInset: true,
        title: widget.transaction == null
            ? isAddedToLoanObjective
                ? "add-record".tr()
                : "add-transaction".tr()
            : isAddedToLoanObjective
                ? "edit-record".tr()
                : "edit-transaction".tr(),
        dragDownToDismiss: true,
        onBackButton: () async {
          if (widget.transaction != null) {
            discardChangesPopup(
              context,
              previousObject:
                  await addDefaultMissingValues(widget.transaction!),
              currentObject: await createTransaction(),
            );
          } else {
            showDiscardChangesPopupIfNotEditing();
          }
        },
        onDragDownToDismiss: () async {
          if (widget.transaction != null) {
            discardChangesPopup(
              context,
              previousObject:
                  await addDefaultMissingValues(widget.transaction!),
              currentObject: await createTransaction(),
            );
          } else {
            showDiscardChangesPopupIfNotEditing();
          }
        },
        actions: [
          widget.transaction != null
              ? IconButton(
                  padding: EdgeInsetsDirectional.all(15),
                  tooltip: "delete-transaction".tr(),
                  onPressed: () async {
                    deleteTransactionPopup(
                      context,
                      transaction: widget.transaction!,
                      category: selectedCategory,
                      routesToPopAfterDelete: widget.routesToPopAfterDelete,
                    );
                  },
                  icon: Icon(appStateSettings["outlinedIcons"]
                      ? Icons.delete_outlined
                      : Icons.delete_rounded),
                )
              : SizedBox.shrink()
        ],
        overlay: MinimizeKeyboardFABOverlay(isEnabled: notesInputFocused),
        staticOverlay: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: AddGradientOnTop(
            child: Row(
              children: [
                Expanded(
                  child: selectedCategory == null
                      ? Button(
                          hasBottomExtraSafeArea: true,
                          label: "select-category".tr(),
                          onTap: () {
                            selectCategorySequence(
                              context,
                              selectedCategory: selectedCategory,
                              setSelectedCategory: setSelectedCategory,
                              selectedSubCategory: selectedSubCategory,
                              setSelectedSubCategory: setSelectedSubCategory,
                              skipIfSet: false,
                              selectedIncomeInitial: selectedIncome,
                            );
                          },
                        )
                      : selectedAmount == null
                          ? Button(
                              hasBottomExtraSafeArea: true,
                              label: "enter-amount".tr(),
                              onTap: () {
                                selectAmountPopup();
                              },
                            )
                          : Button(
                              hasBottomExtraSafeArea: true,
                              label: widget.transaction != null
                                  ? "save-changes".tr()
                                  : textAddTransaction ?? "",
                              onTap: () async {
                                bool result = await addTransaction();
                                if (result) popRoute(context);
                              },
                            ),
                ),
                AnimatedSizeSwitcher(
                  clipBehavior: Clip.none,
                  child: widget.transaction != null && selectedType != null
                      ? Container(
                          key: ValueKey(1),
                          padding: EdgeInsetsDirectional.only(start: 5),
                          child: Button(
                            hasBottomExtraSafeArea: true,
                            color: isTransactionActionDealtWith(
                                    createTransaction())
                                ? Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer
                                : null,
                            textColor: isTransactionActionDealtWith(
                                    createTransaction())
                                ? Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer
                                : null,
                            label: widget.transaction != null
                                ? getTransactionActionNameFromType(
                                        createTransaction())
                                    .tr()
                                : "",
                            onTap: () async {
                              if (widget.transaction != null &&
                                  selectedType != null) {
                                await openTransactionActionFromType(
                                  context,
                                  createTransaction(),
                                  runBefore: () async {
                                    await addTransaction();
                                    popRoute(context);
                                  },
                                );
                              }
                            },
                          ),
                        )
                      : Container(
                          key: ValueKey(2),
                        ),
                ),
              ],
            ),
          ),
        ),
        listWidgets: [
          enableDoubleColumn(context) == false
              ? transactionAmountAndCategoryHeader
              : SizedBox.shrink(),
          enableDoubleColumn(context)
              ? SizedBox(height: 50)
              : SizedBox.shrink(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              enableDoubleColumn(context) == false
                  ? SizedBox.shrink()
                  : Flexible(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 900),
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 13),
                              child: ClipRRect(
                                child: transactionAmountAndCategoryHeader,
                                borderRadius:
                                    BorderRadiusDirectional.circular(15),
                              ),
                            ),
                            transactionTextInput,
                          ],
                        ),
                      ),
                    ),
              transactionDetailsParameters,
            ],
          ),
        ],
      ),
    );
  }
}

class SelectIncludeAmount extends StatelessWidget {
  const SelectIncludeAmount(
      {required this.selectedPaid, required this.onSwitched, super.key});
  final bool selectedPaid;
  final Function(bool) onSwitched;

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      icon: selectedPaid
          ? appStateSettings["outlinedIcons"]
              ? Icons.check_circle_outlined
              : Icons.check_circle_rounded
          : appStateSettings["outlinedIcons"]
              ? Icons.cancel_outlined
              : Icons.cancel_rounded,
      title: "include-amount".tr(),
      enableBorderRadius: true,
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
      initialValue: selectedPaid,
      onSwitched: onSwitched,
    );
  }
}

class SelectedWalletButton extends StatelessWidget {
  const SelectedWalletButton({
    Key? key,
    required this.onTap,
    required this.selectedWalletName,
  }) : super(key: key);
  final VoidCallback onTap;
  final String selectedWalletName;
  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: 10,
      child: Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            ButtonIcon(
              onTap: onTap,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.account_balance_wallet_outlined
                  : Icons.account_balance_wallet_rounded,
              size: 41,
            ),
            SizedBox(width: 15),
            Expanded(
              child: TextFont(
                text: selectedWalletName,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateButton extends StatefulWidget {
  const DateButton({
    Key? key,
    required this.initialSelectedDate,
    required this.initialSelectedTime,
    required this.setSelectedDate,
    required this.setSelectedTime,
    this.internalPadding =
        const EdgeInsetsDirectional.only(start: 20, top: 6, bottom: 6, end: 4),
    this.timeBackgroundColor,
  }) : super(key: key);
  final DateTime initialSelectedDate;
  final TimeOfDay initialSelectedTime;
  final Function(DateTime) setSelectedDate;
  final Function(TimeOfDay) setSelectedTime;
  final EdgeInsetsDirectional internalPadding;
  final Color? timeBackgroundColor;

  @override
  State<DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {
  late DateTime selectedDate = widget.initialSelectedDate;
  late TimeOfDay selectedTime = widget.initialSelectedTime;

  @override
  Widget build(BuildContext context) {
    String wordedDate = getWordedDateShortMore(selectedDate,
        includeYear: selectedDate.year != DateTime.now().year);
    String wordedDateShort = getWordedDateShort(selectedDate,
        includeYear: selectedDate.year != DateTime.now().year);

    return Tappable(
      color: Colors.transparent,
      onLongPress: () {
        if (DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ) !=
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              DateTime.now().hour,
              DateTime.now().minute,
            )) {
          openSnackbar(
            SnackbarMessage(
              title: "date-reset".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.today_outlined
                  : Icons.today_rounded,
              description: "set-to-current-date-and-time".tr(),
            ),
          );
        }
        widget.setSelectedDate(DateTime.now());
        widget.setSelectedTime(TimeOfDay.now());
        setState(() {
          selectedDate = DateTime.now();
          selectedTime = TimeOfDay.now();
        });
      },
      onTap: () async {
        final DateTime picked =
            (await showCustomDatePicker(context, selectedDate) ?? selectedDate);
        setState(() {
          selectedDate = selectedDate.copyWith(
            year: picked.year,
            month: picked.month,
            day: picked.day,
            hour: selectedTime.hour,
            minute: selectedTime.minute,
          );
        });
        widget.setSelectedDate(selectedDate);
      },
      borderRadius: 10,
      child: Padding(
        padding: widget.internalPadding,
        child: Row(
          children: [
            IgnorePointer(
              child: ButtonIcon(
                onTap: () {},
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.calendar_month_outlined
                    : Icons.calendar_month_rounded,
                size: 41,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: TextFont(
                text: wordedDate,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                minFontSize: 18,
                maxLines: 1,
                autoSizeText: true,
                overflowReplacement: TextFont(
                  text: wordedDateShort,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                  minFontSize: 15,
                  maxLines: 1,
                  autoSizeText: true,
                ),
              ),
            ),
            SizedBox(width: 10),
            Tappable(
              color: Colors.transparent,
              onTap: () async {
                TimeOfDay? newTime = await showCustomTimePicker(
                  context,
                  selectedTime,
                );
                if (newTime != null) {
                  setState(() {
                    selectedTime = newTime;
                  });
                }
                widget.setSelectedTime(newTime ?? selectedTime);
              },
              borderRadius: 5,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(4),
                child: TimeDigits(
                  timeOfDay: TimeOfDay(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  ),
                  backgroundColor: widget.timeBackgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectTitle extends StatefulWidget {
  SelectTitle({
    Key? key,
    required this.setSelectedTitle,
    required this.setSelectedNote,
    required this.setSelectedCategory,
    required this.setSelectedSubCategory,
    required this.setSelectedDateTime,
    this.selectedTitle,
    this.selectedDate,
    required this.noteInputController,
    required this.setSelectedNoteController,
    this.next,
    this.disableAskForNote = false,
    this.customTitleInputWidgetBuilder,
  }) : super(key: key);
  final Function(String) setSelectedTitle;
  final Function(String) setSelectedNote;
  final Function(TransactionCategory) setSelectedCategory;
  final Function(TransactionCategory) setSelectedSubCategory;
  final Function(DateTime) setSelectedDateTime;
  final String? selectedTitle;
  final DateTime? selectedDate;
  final TextEditingController noteInputController;
  final dynamic Function(String, {bool setInput}) setSelectedNoteController;
  final VoidCallback? next;
  final bool disableAskForNote;
  final Widget Function(FocusNode enterTitleFocus)?
      customTitleInputWidgetBuilder;

  @override
  _SelectTitleState createState() => _SelectTitleState();
}

class _SelectTitleState extends State<SelectTitle> {
  int selectedIndex = 0;
  String selectedText = "";
  TransactionAssociatedTitleWithCategory? selectedAssociatedTitle;
  DateTime selectedDateTime = DateTime.now();
  bool customDateTimeSelected = false;
  bool get foundFromCategory {
    return selectedAssociatedTitle?.type == TitleType.CategoryName ||
        selectedAssociatedTitle?.type == TitleType.SubCategoryName;
  }

  FocusNode enterTitleFocus = FocusNode();

  @override
  void dispose() {
    enterTitleFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.selectedDate != null) {
      selectedDateTime = widget.selectedDate ?? DateTime.now();
      customDateTimeSelected = true;
    }

    super.initState();
  }

  void selectTitle() async {
    if (selectedAssociatedTitle?.category != null) {
      if (selectedAssociatedTitle?.type == TitleType.SubCategoryName ||
          selectedAssociatedTitle?.category.mainCategoryPk != null) {
        if (selectedAssociatedTitle!.category.mainCategoryPk != null) {
          widget.setSelectedCategory(await database.getCategoryInstance(
              selectedAssociatedTitle!.category.mainCategoryPk!));
          widget.setSelectedSubCategory(selectedAssociatedTitle!.category);
        }
      } else {
        widget.setSelectedCategory(selectedAssociatedTitle!.category);
      }

      if (foundFromCategory == false)
        widget.setSelectedTitle(selectedAssociatedTitle?.title.title ?? "");
      else
        widget.setSelectedTitle("");
    }

    popRoute(context);
    if (widget.next != null) {
      widget.next!();
    }
  }

  void resetTitleSearch() {
    setState(() {
      selectedAssociatedTitle = null;
    });
    // Update the size of the bottom sheet
    Future.delayed(Duration(milliseconds: 300), () {
      bottomSheetControllerGlobal.snapToExtent(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: customDateTimeSelected == true &&
              getPlatform() == PlatformOS.isAndroid &&
              getIsFullScreen(context)
          ? null
          : "enter-title".tr(),
      outsideExtraWidget: customDateTimeSelected
          ? null
          : OutsideExtraWidgetIconButton(
              iconData: appStateSettings["outlinedIcons"]
                  ? Icons.calendar_month_outlined
                  : Icons.calendar_month_rounded,
              onPressed: () async {
                DateTime? dateTimeSelected =
                    await selectDateAndTimeSequence(context, selectedDateTime);
                if (dateTimeSelected != null) {
                  setState(() {
                    customDateTimeSelected = true;
                    selectedDateTime = dateTimeSelected;
                  });
                  widget.setSelectedDateTime(selectedDateTime);
                }
                // Update the size of the bottom sheet
                Future.delayed(Duration(milliseconds: 100), () {
                  bottomSheetControllerGlobal.snapToExtent(0);
                  enterTitleFocus.requestFocus();
                });
              },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedExpanded(
            expand: customDateTimeSelected,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 13),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: DateButton(
                  internalPadding: EdgeInsetsDirectional.zero,
                  key: ValueKey(selectedDateTime.toString()),
                  initialSelectedDate: selectedDateTime,
                  initialSelectedTime: TimeOfDay(
                      hour: selectedDateTime.hour,
                      minute: selectedDateTime.minute),
                  setSelectedDate: (date) {
                    selectedDateTime = date;
                    widget.setSelectedDateTime(selectedDateTime);
                    enterTitleFocus.requestFocus();
                  },
                  setSelectedTime: (time) {
                    selectedDateTime = selectedDateTime.copyWith(
                        hour: time.hour, minute: time.minute);
                    widget.setSelectedDateTime(selectedDateTime);
                    enterTitleFocus.requestFocus();
                  },
                  timeBackgroundColor: (appStateSettings["materialYou"]
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : getColor(context, "canvasContainer")),
                ),
              ),
            ),
          ),
          ...(widget.customTitleInputWidgetBuilder != null
              ? [widget.customTitleInputWidgetBuilder!(enterTitleFocus)]
              : [
                  TextInput(
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.title_outlined
                        : Icons.title_rounded,
                    initialValue: widget.selectedTitle,
                    autoFocus: true,
                    focusNode: enterTitleFocus,
                    onEditingComplete: selectTitle,
                    onChanged: (text) async {
                      selectedText = text;
                      widget.setSelectedTitle(text.trim());

                      if (text.trim() == "" || text.trim().length < 2) {
                        resetTitleSearch();
                        return;
                      }

                      TransactionAssociatedTitleWithCategory?
                          selectedTitleLocal =
                          (await database.getSimilarAssociatedTitles(
                                  title: text, limit: 1))
                              .firstOrNull;

                      if (selectedTitleLocal != null) {
                        // Update the size of the bottom sheet
                        Future.delayed(Duration(milliseconds: 100), () {
                          bottomSheetControllerGlobal.snapToExtent(0);
                        });
                        setState(() {
                          selectedAssociatedTitle = selectedTitleLocal;
                        });
                      } else {
                        resetTitleSearch();
                      }
                    },
                    labelText: "title-placeholder".tr(),
                    padding: EdgeInsetsDirectional.zero,
                  ),
                  AnimatedSizeSwitcher(
                    sizeDuration: Duration(milliseconds: 400),
                    sizeCurve: Curves.easeInOut,
                    child: selectedAssociatedTitle == null
                        ? Container(
                            key: ValueKey(0),
                          )
                        : Container(
                            key: ValueKey(
                                selectedAssociatedTitle?.category.categoryPk),
                            padding: EdgeInsetsDirectional.only(top: 13),
                            child: Tappable(
                              borderRadius: 15,
                              color: Colors.transparent,
                              onTap: () {
                                selectTitle();
                              },
                              child: Row(
                                children: [
                                  CategoryIcon(
                                    categoryPk: "-1",
                                    size: 40,
                                    category: selectedAssociatedTitle?.category,
                                    margin: EdgeInsetsDirectional.zero,
                                    onTap: () {
                                      selectTitle();
                                    },
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFont(
                                          text: selectedAssociatedTitle
                                                  ?.category.name ??
                                              "",
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        !foundFromCategory
                                            ? TextFont(
                                                text: "",
                                                richTextSpan: generateSpans(
                                                  context: context,
                                                  fontSize: 16,
                                                  mainText:
                                                      selectedAssociatedTitle
                                                              ?.title.title ??
                                                          "",
                                                  boldedText:
                                                      selectedAssociatedTitle
                                                          ?.partialTitleString,
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (widget.disableAskForNote == false &&
                          getIsFullScreen(context) ||
                      appStateSettings["askForTransactionNoteWithTitle"])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 13),
                      child: Container(
                        child: TransactionNotesTextInput(
                          noteInputController: widget.noteInputController,
                          setNotesInputFocused: (isFocused) {},
                          setSelectedNoteController: (note,
                              {bool setInput = true}) {
                            widget.setSelectedNoteController(note,
                                setInput: setInput);
                          },
                        ),
                      ),
                    ),
                  // AnimatedSwitcher(
                  //   duration: Duration(milliseconds: 300),
                  //   child: CategoryIcon(
                  //     key: ValueKey(selectedCategory?.categoryPk ?? ""),
                  //     margin: EdgeInsetsDirectional.zero,
                  //     categoryPk: selectedCategory?.categoryPk ?? 0,
                  //     size: 55,
                  //     onTap: () {
                  //       openBottomSheet(
                  //         context,
                  //         PopupFramework(
                  //           title: "select-category".tr(),
                  //           child: SelectCategory(
                  //             setSelectedCategory: (TransactionCategory category) {
                  //               widget.setSelectedCategory(category);
                  //               setState(() {
                  //                 selectedCategory = category;
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  SizedBox(height: 15),
                  widget.next != null
                      ? Button(
                          label: "select-category".tr(),
                          onTap: () {
                            popRoute(context);
                            if (widget.next != null) {
                              widget.next!();
                            }
                          },
                        )
                      : SizedBox.shrink(),
                ])
        ],
      ),
    );
  }
}

// class SelectTag extends StatefulWidget {
//   SelectTag({Key? key, this.setSelectedCategory}) : super(key: key);
//   final Function(TransactionCategoryOld)? setSelectedCategory;

//   @override
//   _SelectTagState createState() => _SelectTagState();
// }

// class _SelectTagState extends State<SelectTag> {
//   int selectedIndex = 0;
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsetsDirectional.only(bottom: 8.0),
//       child: Center(
//         child: Wrap(
//           alignment: WrapAlignment.center,
//           spacing: 10,
//           children: listTag()
//               .asMap()
//               .map(
//                 (index, tag) => MapEntry(
//                   index,
//                   TagIcon(
//                     tag: tag,
//                     size: 17,
//                     onTap: () {},
//                   ),
//                 ),
//               )
//               .values
//               .toList(),
//         ),
//       ),
//     );
//   }
// }

class SelectText extends StatefulWidget {
  SelectText({
    Key? key,
    required this.setSelectedText,
    this.selectedText,
    this.labelText = "",
    this.next,
    this.nextWithInput,
    this.placeholder,
    this.icon,
    this.autoFocus = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.requestLateAutoFocus = false,
    this.popContext = true,
    this.popContextWhenSet = false,
    this.inputFormatters,
    this.backgroundColor,
    this.widgetBeside,
    required this.buttonLabel,
    this.maxLength,
    this.enableButton = true,
  }) : super(key: key);
  final Function(String) setSelectedText;
  final String? selectedText;
  final VoidCallback? next;
  final Function(String)? nextWithInput;
  final String labelText;
  final String? placeholder;
  final IconData? icon;
  final bool autoFocus;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final bool requestLateAutoFocus;
  final bool popContext;
  final bool popContextWhenSet;
  final List<TextInputFormatter>? inputFormatters;
  final Color? backgroundColor;
  final Widget? widgetBeside;
  final String? buttonLabel;
  final int? maxLength;
  final bool enableButton;

  @override
  _SelectTextState createState() => _SelectTextState();
}

class _SelectTextState extends State<SelectText> {
  String? input = "";
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    input = widget.selectedText;
    _focusNode = new FocusNode();
    if (widget.requestLateAutoFocus)
      Future.delayed(Duration(milliseconds: 250), () {
        _focusNode.requestFocus();
      });
  }

  onEditingComplete() {
    widget.setSelectedText(input ?? "");
    if (widget.popContext) {
      popRoute(context, input);
    }
    if (widget.next != null) {
      widget.next!();
    }
    if (widget.nextWithInput != null) {
      widget.nextWithInput!(input ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextInput(
                maxLength: widget.maxLength,
                backgroundColor: widget.backgroundColor,
                inputFormatters: widget.inputFormatters,
                focusNode: _focusNode,
                textCapitalization: widget.textCapitalization,
                icon: widget.icon != null
                    ? widget.icon
                    : appStateSettings["outlinedIcons"]
                        ? Icons.title_outlined
                        : Icons.title_rounded,
                initialValue: widget.selectedText,
                autoFocus: widget.autoFocus,
                readOnly: widget.readOnly,
                onEditingComplete: onEditingComplete,
                onChanged: (text) {
                  input = text;
                  widget.setSelectedText(input!);
                  if (widget.popContextWhenSet) {
                    popRoute(context, input);
                  }
                },
                labelText: widget.placeholder ?? widget.labelText,
                padding: EdgeInsetsDirectional.zero,
              ),
            ),
            if (widget.widgetBeside != null) widget.widgetBeside!,
          ],
        ),
        SizedBox(
          height: widget.buttonLabel != null ? 15 : 5,
        ),
        if (widget.buttonLabel != null)
          Button(
            label: widget.buttonLabel ?? "",
            onTap: onEditingComplete,
            disabled: !widget.enableButton,
          ),
      ],
    );
  }
}

class EnterTextButton extends StatefulWidget {
  const EnterTextButton({
    Key? key,
    required this.title,
    required this.placeholder,
    this.defaultValue,
    required this.setSelectedText,
    this.icon,
  }) : super(key: key);

  final String title;
  final String placeholder;
  final String? defaultValue;
  final Function(String) setSelectedText;
  final IconData? icon;

  @override
  State<EnterTextButton> createState() => _EnterTextButtonState();
}

class _EnterTextButtonState extends State<EnterTextButton> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    if (widget.defaultValue != null) {
      _textController = new TextEditingController(text: widget.defaultValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 19),
      child: Tappable(
        color: getColor(context, "canvasContainer"),
        onTap: () {
          openBottomSheet(
            context,
            popupWithKeyboard: true,
            PopupFramework(
              title: widget.title,
              child: SelectText(
                setSelectedText: (text) {
                  setTextInput(_textController, text);
                  widget.setSelectedText(text);
                },
                labelText: widget.title,
                selectedText: _textController.text,
                placeholder: widget.placeholder,
                buttonLabel: null,
              ),
            ),
          );
        },
        borderRadius: 15,
        child: IgnorePointer(
          child: TextInput(
            padding: EdgeInsetsDirectional.zero,
            readOnly: true,
            labelText: widget.placeholder,
            icon: widget.icon,
            controller: _textController,
          ),
        ),
      ),
    );
  }
}

Future<bool> addAssociatedTitles(
    String selectedTitle, TransactionCategory selectedCategory) async {
  if (appStateSettings["autoAddAssociatedTitles"]) {
    try {
      TransactionAssociatedTitleWithCategory? foundTitle =
          (await database.getSimilarAssociatedTitles(
        title: selectedTitle,
        limit: 1,
      ))
              .firstOrNull;

      if (foundTitle?.type == TitleType.CategoryName ||
          foundTitle?.type == TitleType.SubCategoryName) {
        return false;
      }

      print("Found associated title: " + foundTitle.toString());

      if (foundTitle != null &&
          (foundTitle.category.categoryPk == selectedCategory.categoryPk ||
              foundTitle.category.mainCategoryPk ==
                  selectedCategory.categoryPk) &&
          (foundTitle.partialTitleString?.trim() == selectedTitle.trim() ||
              (foundTitle.partialTitleString == null &&
                  foundTitle.title.title.trim() == selectedTitle.trim()))) {
        // If there is an existing title, move to top
        print("Already has this title, moving to top");

        // This is more efficient than shifting the associated title since this uses batching
        await database.deleteAssociatedTitle(
            foundTitle.title.associatedTitlePk, foundTitle.title.order);
        int length = await database.getAmountOfAssociatedTitles();
        await database.createOrUpdateAssociatedTitle(
            foundTitle.title.copyWith(order: length));
        return true;
      } else {
        // If there is no existing title, create one
        print("Creating new associated title");
        int length = await database.getAmountOfAssociatedTitles();
        await database.createOrUpdateAssociatedTitle(
          insert: true,
          TransactionAssociatedTitle(
            associatedTitlePk: "-1",
            categoryFk: selectedCategory.categoryPk,
            isExactMatch: false,
            title: selectedTitle.trim(),
            dateCreated: DateTime.now(),
            dateTimeModified: null,
            order: length,
          ),
        );
      }
    } catch (e) {
      print("Error adding associated title: " + e.toString());
    }
  }
  return true;
}

class SelectAddedBudget extends StatefulWidget {
  const SelectAddedBudget({
    required this.setSelectedBudget,
    this.selectedBudgetPk,
    this.extraHorizontalPadding,
    this.wrapped,
    this.horizontalBreak,
    super.key,
  });
  final Function(Budget?, {bool isSharedBudget}) setSelectedBudget;
  final String? selectedBudgetPk;
  final double? extraHorizontalPadding;
  final bool? wrapped;
  final bool? horizontalBreak;

  @override
  State<SelectAddedBudget> createState() => _SelectAddedBudgetState();
}

class _SelectAddedBudgetState extends State<SelectAddedBudget> {
  late String? selectedBudgetPk = widget.selectedBudgetPk;

  @override
  void didUpdateWidget(covariant SelectAddedBudget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedBudgetPk != widget.selectedBudgetPk) {
      setState(() {
        selectedBudgetPk = widget.selectedBudgetPk;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: database.watchAllAddableBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0) return Container();
          return HorizontalBreakAbove(
            enabled:
                enableDoubleColumn(context) && widget.horizontalBreak == true,
            child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 5),
                child: SelectChips(
                  allowMultipleSelected: false,
                  wrapped: widget.wrapped ?? enableDoubleColumn(context),
                  extraHorizontalPadding: widget.extraHorizontalPadding,
                  onLongPress: (Budget? item) {
                    pushRoute(
                      context,
                      AddBudgetPage(
                        budget: item,
                        routesToPopAfterDelete:
                            RoutesToPopAfterDelete.PreventDelete,
                      ),
                    );
                  },
                  extraWidgetAfter: SelectChipsAddButtonExtraWidget(
                    openPage: AddBudgetPage(
                      isAddedOnlyBudget: true,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  ),
                  items: [null, ...snapshot.data!],
                  getLabel: (Budget? item) {
                    return item?.name ?? "no-budget".tr();
                  },
                  onSelected: (Budget? item) {
                    widget.setSelectedBudget(
                      item,
                      isSharedBudget: item?.sharedKey != null,
                    );
                    setState(() {
                      selectedBudgetPk = item?.budgetPk;
                    });
                  },
                  getSelected: (Budget? item) {
                    return selectedBudgetPk == item?.budgetPk;
                  },
                  getCustomBorderColor: (Budget? item) {
                    return dynamicPastel(
                      context,
                      lightenPastel(
                        HexColor(
                          item?.colour,
                          defaultColor: Theme.of(context).colorScheme.primary,
                        ),
                        amount: 0.3,
                      ),
                      amount: 0.4,
                    );
                  },
                )),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SelectObjective extends StatefulWidget {
  const SelectObjective({
    required this.setSelectedObjective,
    this.selectedObjectivePk,
    this.extraHorizontalPadding,
    this.wrapped,
    this.horizontalBreak = false,
    required this.objectiveType,
    this.setSelectedIncome,
    super.key,
  });
  final Function(String?) setSelectedObjective;
  final String? selectedObjectivePk;
  final double? extraHorizontalPadding;
  final bool? wrapped;
  final bool horizontalBreak;
  final ObjectiveType objectiveType;
  final Function(bool isIncome)? setSelectedIncome;

  @override
  State<SelectObjective> createState() => _SelectObjectiveState();
}

class _SelectObjectiveState extends State<SelectObjective> {
  late String? selectedObjectivePk = widget.selectedObjectivePk;

  @override
  void didUpdateWidget(covariant SelectObjective oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedObjectivePk != widget.selectedObjectivePk) {
      setState(() {
        selectedObjectivePk = widget.selectedObjectivePk;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Objective>>(
      stream: database.watchAllObjectives(
          objectiveType: widget.objectiveType, archivedLast: true),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0) return Container();
          return HorizontalBreakAbove(
            enabled:
                enableDoubleColumn(context) && widget.horizontalBreak == true,
            child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 5),
                child: SelectChips(
                  allowMultipleSelected: false,
                  wrapped: widget.wrapped ?? enableDoubleColumn(context),
                  extraHorizontalPadding: widget.extraHorizontalPadding,
                  onLongPress: (Objective? item) {
                    pushRoute(
                      context,
                      AddObjectivePage(
                        objective: item,
                        routesToPopAfterDelete:
                            RoutesToPopAfterDelete.PreventDelete,
                        objectiveType: widget.objectiveType,
                      ),
                    );
                  },
                  extraWidgetAfter: SelectChipsAddButtonExtraWidget(
                    openPage: AddObjectivePage(
                      objectiveType: widget.objectiveType,
                      routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                    ),
                  ),
                  items: [null, ...snapshot.data!],
                  getLabel: (Objective? item) {
                    return item?.name ??
                        (widget.objectiveType == ObjectiveType.loan
                            ? "no-loan".tr()
                            : "no-goal".tr());
                  },
                  onSelected: (Objective? item) {
                    widget.setSelectedObjective(
                      item?.objectivePk,
                    );
                    if (item?.type == ObjectiveType.loan &&
                        widget.setSelectedIncome != null) {
                      widget.setSelectedIncome!(item?.income ?? false);
                    }
                    setState(() {
                      selectedObjectivePk = item?.objectivePk;
                    });
                  },
                  getSelected: (Objective? item) {
                    return selectedObjectivePk == item?.objectivePk;
                  },
                  getCustomBorderColor: (Objective? item) {
                    return dynamicPastel(
                      context,
                      lightenPastel(
                        HexColor(
                          item?.colour,
                          defaultColor: Theme.of(context).colorScheme.primary,
                        ),
                        amount: 0.3,
                      ),
                      amount: 0.4,
                    );
                  },
                )),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SelectExcludeBudget extends StatefulWidget {
  const SelectExcludeBudget({
    required this.setSelectedExcludedBudgets,
    this.selectedExcludedBudgetPks,
    this.extraHorizontalPadding,
    this.wrapped,
    super.key,
  });
  final Function(List<String>?) setSelectedExcludedBudgets;
  final List<String>? selectedExcludedBudgetPks;
  final double? extraHorizontalPadding;
  final bool? wrapped;

  @override
  State<SelectExcludeBudget> createState() => _SelectExcludeBudgetState();
}

class _SelectExcludeBudgetState extends State<SelectExcludeBudget> {
  late List<String> selectedExcludedBudgetPks =
      widget.selectedExcludedBudgetPks ?? [];

  @override
  void didUpdateWidget(covariant SelectExcludeBudget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedExcludedBudgetPks != widget.selectedExcludedBudgetPks) {
      setState(() {
        selectedExcludedBudgetPks = widget.selectedExcludedBudgetPks ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: database.watchAllNonAddableBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.length <= 0)
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 17, end: 17, top: 6, bottom: 15),
              child: Row(
                children: [
                  TextFont(
                    text: "no-budgets-found".tr(),
                    fontSize: 15,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            );
          return Padding(
              padding: const EdgeInsetsDirectional.only(top: 5),
              child: SelectChips(
                wrapped: widget.wrapped ?? enableDoubleColumn(context),
                extraHorizontalPadding: widget.extraHorizontalPadding,
                onLongPress: (Budget item) {
                  pushRoute(
                    context,
                    AddBudgetPage(
                      budget: item,
                      routesToPopAfterDelete:
                          RoutesToPopAfterDelete.PreventDelete,
                    ),
                  );
                },
                extraWidgetAfter: SelectChipsAddButtonExtraWidget(
                  openPage: AddBudgetPage(
                    routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                  ),
                ),
                items: snapshot.data!,
                getLabel: (Budget item) {
                  return item.name;
                },
                onSelected: (Budget item) {
                  // widget.setSelectedBudget(
                  //   item,
                  //   isSharedBudget: item?.sharedKey != null,
                  // );
                  // setState(() {
                  //   selectedBudgetPk = item?.budgetPk;
                  // });
                  if (selectedExcludedBudgetPks.contains(item.budgetPk)) {
                    selectedExcludedBudgetPks.remove(item.budgetPk);
                  } else {
                    selectedExcludedBudgetPks.add(item.budgetPk);
                  }
                  widget.setSelectedExcludedBudgets(selectedExcludedBudgetPks);
                },
                getSelected: (Budget item) {
                  return (selectedExcludedBudgetPks).contains(item.budgetPk);
                },
                getCustomBorderColor: (Budget? item) {
                  return dynamicPastel(
                    context,
                    lightenPastel(
                      HexColor(
                        item?.colour,
                        defaultColor: Theme.of(context).colorScheme.primary,
                      ),
                      amount: 0.3,
                    ),
                    amount: 0.4,
                  );
                },
              ));
        } else {
          return Container();
        }
      },
    );
  }
}

class HorizontalBreakAbove extends StatelessWidget {
  const HorizontalBreakAbove({
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsetsDirectional.symmetric(vertical: 10),
    super.key,
  });
  final Widget child;
  final bool enabled;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) {
    if (enabled == false) return child;
    return Column(
      children: [
        // Divider(indent: 10, endIndent: 10),
        HorizontalBreak(padding: padding),
        child,
      ],
    );
  }
}

class HorizontalBreak extends StatelessWidget {
  const HorizontalBreak(
      {this.padding = const EdgeInsetsDirectional.symmetric(vertical: 10),
      this.color,
      super.key});
  final EdgeInsetsDirectional padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding,
      height: 2,
      decoration: BoxDecoration(
        color: color ?? getColor(context, "dividerColor"),
        borderRadius: BorderRadiusDirectional.all(Radius.circular(15)),
      ),
    );
  }
}

void deleteTransactionPopup(
  BuildContext context, {
  required Transaction transaction,
  required TransactionCategory? category,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  String? transactionName =
      await getTransactionLabel(transaction, category: category);
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-transaction-question".tr(),
    subtitle: transactionName,
  );
  if (action == DeletePopupAction.Delete) {
    await checkToDeleteCloselyRelatedBalanceCorrectionTransaction(context,
        transaction: transaction);
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      popAllRoutes(context);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      popRoute(context);
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteTransaction(transaction.transactionPk);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-transaction".tr(),
          icon: Icons.delete,
          description: transactionName,
        ),
      );
    });
  }
}

Future checkToDeleteCloselyRelatedBalanceCorrectionTransaction(
  BuildContext context, {
  required Transaction transaction,
}) async {
  if (transaction.categoryFk == "0") {
    Transaction? closelyRelatedTransferCorrectionTransaction = await database
        .getCloselyRelatedBalanceCorrectionTransaction(transaction);
    if (closelyRelatedTransferCorrectionTransaction != null) {
      await openPopup(
        context,
        title: "delete-both-transfers-question".tr(),
        description: "delete-both-transfers-question-description".tr(),
        descriptionWidget: IgnorePointer(
          child: Column(
            children: [
              HorizontalBreak(
                  padding: EdgeInsetsDirectional.only(top: 15, bottom: 10)),
              TransactionEntry(
                useHorizontalPaddingConstrained: false,
                openPage: Container(),
                transaction: transaction,
                containerColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.4),
                customPadding: EdgeInsetsDirectional.zero,
              ),
              SizedBox(height: 5),
              TransactionEntry(
                useHorizontalPaddingConstrained: false,
                openPage: Container(),
                transaction: closelyRelatedTransferCorrectionTransaction,
                containerColor: Colors.transparent,
                customPadding: EdgeInsetsDirectional.zero,
              ),
            ],
          ),
        ),
        onCancel: () {
          popRoute(context);
        },
        onCancelLabel: "only-current".tr(),
        onSubmit: () async {
          openLoadingPopupTryCatch(() async {
            await database.deleteTransaction(
                closelyRelatedTransferCorrectionTransaction.transactionPk);
          });
          popRoute(context);
        },
        onSubmitLabel: "delete-both".tr(),
      );
    }
  }
}

Future deleteTransactionsPopup(
  BuildContext context, {
  required List<String> transactionPks,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-selected-transactions".tr(),
    subtitle: transactionPks.length.toString() +
        " " +
        (transactionPks.length == 1
            ? "transaction".tr().toLowerCase()
            : "transactions".tr().toLowerCase()),
  );
  if (action == DeletePopupAction.Delete) {
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      popAllRoutes(context);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      popRoute(context);
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteTransactions(transactionPks);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-transactions".tr(),
          icon: Icons.delete,
          description: transactionPks.length.toString() +
              " " +
              (transactionPks.length == 1
                  ? "transaction".tr().toLowerCase()
                  : "transactions".tr().toLowerCase()),
        ),
      );
    });
  }
  return action;
}

class SelectTransactionTypePopup extends StatelessWidget {
  const SelectTransactionTypePopup({
    required this.setTransactionType,
    this.selectedTransactionType,
    this.onlyShowOneTransactionType,
    this.transactionTypesToShow,
    super.key,
  });
  final Function(TransactionSpecialType? transactionType) setTransactionType;
  final TransactionSpecialType? selectedTransactionType;
  final TransactionSpecialType? onlyShowOneTransactionType;
  final List<dynamic>? transactionTypesToShow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onlyShowOneTransactionType == null)
          TransactionTypeInfoEntry(
            selectedTransactionType: selectedTransactionType,
            setTransactionType: setTransactionType,
            transactionTypesToShow: transactionTypesToShow,
            transactionType: null,
            title: "default".tr(),
            onTap: () {
              setTransactionType(null);
              popRoute(context);
            },
            icon: appStateSettings["outlinedIcons"]
                ? Icons.check_circle_outlined
                : Icons.check_circle_rounded,
          ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.upcoming,
          title: "upcoming".tr(),
          childrenDescription: [
            ListItem(
              "upcoming-transaction-type-description-1".tr(),
            ),
            ListItem(
              "upcoming-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.subscription,
          title: "subscription".tr(),
          childrenDescription: [
            ListItem(
              "subscription-transaction-type-description-1".tr(),
            ),
            ListItem(
              "subscription-transaction-type-description-2".tr(),
            ),
            ListItem(
              // Indicating the next one will be auto created when current marked as paid
              "repetitive-transaction-type-description-3".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.repetitive,
          title: "repetitive".tr(),
          childrenDescription: [
            ListItem(
              "repetitive-transaction-type-description-1".tr(),
            ),
            ListItem(
              // Indicating the next one will be auto created when current marked as paid
              "repetitive-transaction-type-description-2".tr(),
            ),
            ListItem(
              "repetitive-transaction-type-description-3".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.credit,
          title: "lent".tr(),
          childrenDescription: [
            ListItem(
              "lent-transaction-type-description-1".tr(),
            ),
            ListItem(
              "lent-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        TransactionTypeInfoEntry(
          selectedTransactionType: selectedTransactionType,
          setTransactionType: setTransactionType,
          transactionTypesToShow: transactionTypesToShow,
          transactionType: TransactionSpecialType.debt,
          title: "borrowed".tr(),
          childrenDescription: [
            ListItem(
              "borrowed-transaction-type-description-1".tr(),
            ),
            ListItem(
              "borrowed-transaction-type-description-2".tr(),
            ),
          ],
          onlyShowOneTransactionType: onlyShowOneTransactionType,
        ),
        SizedBox(height: 13),
        Tappable(
          color: appStateSettings["materialYou"] == true
              ? dynamicPastel(
                  context,
                  Theme.of(context).colorScheme.secondaryContainer,
                  amount: 0.5,
                )
              : getColor(context, "canvasContainer"),
          borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 15),
            child: Column(
              children: [
                SizedBox(height: 8),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 20),
                  child: TextFont(
                    maxLines: 5,
                    fontSize: 16,
                    textAlign: TextAlign.center,
                    text: "mark-transaction-help-description".tr(),
                  ),
                ),
                SizedBox(height: 18),
                IgnorePointer(
                  child: TransactionEntry(
                    highlightActionButton: true,
                    useHorizontalPaddingConstrained: false,
                    openPage: Container(),
                    containerColor: Theme.of(context)
                        .colorScheme
                        .background
                        .withOpacity(0.5),
                    transaction: Transaction(
                      transactionPk: "-1",
                      name: "",
                      amount: 100,
                      note: "",
                      categoryFk: "-1",
                      walletFk: appStateSettings["selectedWalletPk"],
                      dateCreated: DateTime.now(),
                      income: false,
                      paid: false,
                      skipPaid: false,
                      type: TransactionSpecialType.upcoming,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (TransactionSpecialType type
                        in TransactionSpecialType.values)
                      IgnorePointer(
                        child: TransactionEntryActionButton(
                          padding:
                              EdgeInsetsDirectional.symmetric(horizontal: 6),
                          allowOpenIntoObjectiveLoanPage: false,
                          transaction: Transaction(
                            transactionPk: "-1",
                            name: "",
                            amount: 0,
                            note: "",
                            categoryFk: "-1",
                            subCategoryFk: null,
                            walletFk: "",
                            dateCreated: DateTime.now(),
                            income: false,
                            paid: [
                              TransactionSpecialType.credit,
                              TransactionSpecialType.debt
                            ].contains(type)
                                ? true
                                : false,
                            skipPaid: false,
                            type: type,
                          ),
                          iconColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionTypeInfoEntry extends StatelessWidget {
  final Function(TransactionSpecialType? transactionType) setTransactionType;
  final TransactionSpecialType? selectedTransactionType;
  final List<Widget>? childrenDescription;
  final String title;
  final IconData? icon;
  final TransactionSpecialType? transactionType;
  final TransactionSpecialType? onlyShowOneTransactionType;
  final VoidCallback? onTap;
  final List<dynamic>? transactionTypesToShow;

  TransactionTypeInfoEntry({
    Key? key,
    required this.setTransactionType,
    required this.selectedTransactionType,
    this.childrenDescription,
    required this.title,
    this.icon,
    required this.transactionType,
    this.onlyShowOneTransactionType,
    this.onTap,
    this.transactionTypesToShow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactionTypesToShow?.contains(transactionType) == false)
      return SizedBox.shrink();
    if (onlyShowOneTransactionType == null ||
        onlyShowOneTransactionType == transactionType) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 13),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButtonStacked(
                filled: selectedTransactionType == transactionType,
                alignStart: true,
                alignBeside: true,
                padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 20, vertical: 20),
                text: title,
                iconData: icon ?? getTransactionTypeIcon(transactionType),
                onTap: onTap ??
                    () {
                      setTransactionType(transactionType);
                      popRoute(context);
                    },
                afterWidget: childrenDescription == null
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: childrenDescription ?? [],
                      ),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class MainAndSubcategory {
  MainAndSubcategory(
      {this.main, this.sub, this.ignoredSubcategorySelection = false});

  TransactionCategory? main;
  TransactionCategory? sub;
  bool ignoredSubcategorySelection;

  @override
  String toString() {
    return 'main: $main, sub: $sub, ignoredSubcategorySelection: $ignoredSubcategorySelection';
  }
}

// ignoredSubcategorySelection is true if the subcategory is skipped
Future<MainAndSubcategory> selectCategorySequence(
  BuildContext context, {
  Widget? extraWidgetAfter,
  Widget? extraWidgetBefore,
  bool? skipIfSet,
  required TransactionCategory? selectedCategory,
  required Function(TransactionCategory)? setSelectedCategory,
  required TransactionCategory? selectedSubCategory,
  required Function(TransactionCategory?)? setSelectedSubCategory,
  Function(bool?)? setSelectedIncome,
  required bool?
      selectedIncomeInitial, // if this is null, always show all categories
  String? subtitle,
  bool allowReorder = true,
}) async {
  MainAndSubcategory mainAndSubcategory = MainAndSubcategory();
  dynamic result = await openBottomSheet(
    context,
    SelectCategoryWithIncomeExpenseSelector(
      subtitle: subtitle,
      extraWidgetAfter: extraWidgetAfter,
      extraWidgetBefore: extraWidgetBefore,
      skipIfSet: skipIfSet,
      selectedCategory: selectedCategory,
      setSelectedCategory: setSelectedCategory,
      selectedSubCategory: selectedSubCategory,
      setSelectedSubCategory: setSelectedSubCategory,
      setSelectedIncome: setSelectedIncome,
      selectedIncomeInitial: selectedIncomeInitial,
      allowReorder: allowReorder,
    ),
  );
  if (result != null && result is TransactionCategory) {
    mainAndSubcategory.main = result;
    int subCategoriesOfMain = await database
        .getAmountOfSubCategories(mainAndSubcategory.main!.categoryPk);
    if (subCategoriesOfMain > 0) {
      dynamic result2 = await openBottomSheet(
        context,
        PopupFramework(
          title: "select-subcategory".tr(),
          child: SelectCategory(
            skipIfSet: skipIfSet,
            selectedCategory: selectedSubCategory,
            setSelectedCategory: setSelectedSubCategory,
            mainCategoryPks: [mainAndSubcategory.main!.categoryPk],
            allowRearrange: false,
            header: [
              LayoutBuilder(builder: (context, constraints) {
                return Column(
                  children: [
                    Tappable(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      onTap: () {
                        if (setSelectedSubCategory != null)
                          setSelectedSubCategory(null);
                        popRoute(context, false);
                      },
                      borderRadius: 18,
                      child: Container(
                        height: constraints.maxWidth < 70
                            ? constraints.maxWidth
                            : 66,
                        width: constraints.maxWidth < 70
                            ? constraints.maxWidth
                            : 66,
                        child: Center(
                          child: Icon(
                            appStateSettings["outlinedIcons"]
                                ? Icons.block_outlined
                                : Icons.block_rounded,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsetsDirectional.only(top: 2),
                      child: Center(
                        child: TextFont(
                          textAlign: TextAlign.center,
                          text: "none".tr(),
                          fontSize: 10,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
      if (result2 is TransactionCategory) {
        mainAndSubcategory.sub = result2;
      }
      if (result2 == null) {
        mainAndSubcategory.ignoredSubcategorySelection = true;
      }
      if (result2 == false) {
        return mainAndSubcategory;
      }
    }
  }
  return mainAndSubcategory;
}

class SelectCategoryWithIncomeExpenseSelector extends StatefulWidget {
  const SelectCategoryWithIncomeExpenseSelector({
    required this.extraWidgetAfter,
    required this.extraWidgetBefore,
    required this.skipIfSet,
    required this.selectedCategory,
    required this.setSelectedCategory,
    required this.selectedSubCategory,
    required this.setSelectedSubCategory,
    required this.setSelectedIncome,
    required this.selectedIncomeInitial,
    this.allowReorder = true,
    this.subtitle,
    super.key,
  });

  final Widget? extraWidgetAfter;
  final Widget? extraWidgetBefore;
  final bool? skipIfSet;
  final TransactionCategory? selectedCategory;
  final Function(TransactionCategory)? setSelectedCategory;
  final TransactionCategory? selectedSubCategory;
  final Function(TransactionCategory?)? setSelectedSubCategory;
  final Function(bool?)? setSelectedIncome;
  final bool? selectedIncomeInitial;
  final bool allowReorder;
  final String? subtitle;

  @override
  State<SelectCategoryWithIncomeExpenseSelector> createState() =>
      _SelectCategoryWithIncomeExpenseSelectorState();
}

class _SelectCategoryWithIncomeExpenseSelectorState
    extends State<SelectCategoryWithIncomeExpenseSelector> {
  late bool? selectedIncome =
      appStateSettings["showAllCategoriesWhenSelecting"] == true
          ? null
          : widget.selectedIncomeInitial;

  void setSelectedIncome(bool? value) {
    if (widget.setSelectedIncome != null) widget.setSelectedIncome!(value);
    setState(() {
      selectedIncome = value;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      bottomSheetControllerGlobal.snapToExtent(0,
          duration: Duration(milliseconds: 400));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: widget.setSelectedIncome == null ? "select-category".tr() : null,
      subtitle: widget.subtitle,
      hasPadding: false,
      outsideExtraWidget: widget.setSelectedIncome != null
          // Hide option to rearrange because income/expense selector is shown
          ? null
          : CustomPopupMenuButton(
              showButtons: false,
              keepOutFirst: false,
              buttonPadding: getPlatform() == PlatformOS.isIOS ? 15 : 20,
              items: [
                if (widget.selectedIncomeInitial != null)
                  DropdownItemMenu(
                    id: "toggle-selected-income",
                    label: selectedIncome == null
                        ? (widget.selectedIncomeInitial == true
                            ? "only-income-categories".tr()
                            : "only-expense-categories".tr())
                        : "show-all-categories".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.grid_on_outlined
                        : Icons.grid_on_rounded,
                    action: () {
                      if (selectedIncome == null) {
                        setSelectedIncome(widget.selectedIncomeInitial);
                        updateSettings("showAllCategoriesWhenSelecting", false,
                            updateGlobalState: false);
                      } else {
                        setSelectedIncome(null);
                        updateSettings("showAllCategoriesWhenSelecting", true,
                            updateGlobalState: false);
                      }
                    },
                  ),
                if (widget.allowReorder)
                  DropdownItemMenu(
                    id: "reorder-categories",
                    label: "reorder-categories".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.flip_to_front_outlined
                        : Icons.flip_to_front_rounded,
                    action: () async {
                      popRoute(context);
                      openBottomSheet(context, ReorderCategoriesPopup());
                    },
                  ),
              ],
            ),
      child: Column(
        children: [
          if (widget.extraWidgetBefore != null) widget.extraWidgetBefore!,
          if (widget.setSelectedIncome != null)
            IncomeExpenseButtonSelector(setSelectedIncome: (value) {
              setSelectedIncome(value);
            }),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 18, end: 18),
            child: SelectCategory(
              skipIfSet: widget.skipIfSet,
              selectedCategory: widget.selectedCategory,
              setSelectedCategory: widget.setSelectedCategory,
              selectedIncome: selectedIncome,
              allowRearrange: false,
              // selectedIncome == null && widget.selectedIncomeInitial == null,
            ),
          ),
          if (widget.extraWidgetAfter != null) widget.extraWidgetAfter!,
        ],
      ),
    );
  }
}

class ReorderCategoriesPopup extends StatelessWidget {
  const ReorderCategoriesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "reorder-categories".tr(),
      subtitle: "drag-and-drop-categories-to-rearrange".tr(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: SelectCategory(
              skipIfSet: false,
              selectedIncome: null, // needs to be null
              addButton: false,
            ),
          ),
          Button(
            label: "done".tr(),
            onTap: () {
              popRoute(context);
            },
          )
        ],
      ),
    );
  }
}

String? getFileIdFromUrl(String url) {
  RegExp regExp = RegExp(r"/d/([a-zA-Z0-9_-]+)");
  Match? match = regExp.firstMatch(url);
  if (match != null && match.groupCount >= 1) {
    return match.group(1)!;
  } else {
    return null;
  }
}

Future<List<int>?> getGoogleDriveFileImageData(String url) async {
  dynamic result = await openLoadingPopupTryCatch(
    () async {
      String? fileId = getFileIdFromUrl(url);
      if (fileId == null) throw ("No file id found!");

      if (googleUser == null) {
        await signInGoogle(drivePermissionsAttachments: true);
      }

      final authHeaders = await googleUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      drive.DriveApi driveApi = drive.DriveApi(authenticateClient);

      List<int> dataStore = [];

      drive.File fileMetadata =
          await driveApi.files.get(fileId, $fields: 'size') as drive.File;
      int totalBytes = int.parse(fileMetadata.size ?? "0");

      dynamic response = await driveApi.files
          .get(fileId, downloadOptions: drive.DownloadOptions.fullMedia);

      num receivedBytes = 0;

      loadingProgressKey.currentState?.setProgressPercentage(0);

      await for (var data in response.stream) {
        dataStore.insertAll(dataStore.length, data);
        receivedBytes += data.length;
        double progress = receivedBytes / totalBytes;
        loadingProgressKey.currentState?.setProgressPercentage(progress);
      }
      loadingProgressKey.currentState?.setProgressPercentage(0);
      return dataStore;
    },
    onError: (error) {
      loadingProgressKey.currentState?.setProgressPercentage(0);
      print(error);
    },
  );
  if (result is List<int>) return result;
  return null;
}

class RenderImageData extends StatelessWidget {
  const RenderImageData(
      {required this.imageData, required this.openLinkOnError, super.key});
  final List<int>? imageData;
  final VoidCallback openLinkOnError;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        openLinkOnError();
      },
      child: Image.memory(
        Uint8List.fromList(imageData ?? []),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Tappable(
            onTap: openLinkOnError,
            color: Colors.transparent,
            borderRadius: 15,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20, vertical: 25),
              child: Column(
                children: [
                  TextFont(
                    fontSize: 18,
                    text: "failed-to-preview-image".tr(),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                  SizedBox(height: 15),
                  LowKeyButton(onTap: openLinkOnError, text: "open-link".tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LinkInNotes extends StatelessWidget {
  const LinkInNotes({
    required this.link,
    required this.onTap,
    this.onLongPress,
    this.iconData,
    this.iconDataAfter,
    this.color,
    this.extraWidget,
    super.key,
  });
  final String link;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? iconData;
  final IconData? iconDataAfter;
  final Color? color;
  final Widget? extraWidget;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      onLongPress: onLongPress,
      color: color ??
          darkenPastel(
            (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondaryContainer
                : getColor(context, "canvasContainer")),
            amount:
                Theme.of(context).brightness == Brightness.light ? 0.07 : 0.25,
          ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
            start: 15, end: extraWidget == null ? 15 : 0, top: 10, bottom: 10),
        child: Row(
          children: [
            Icon(
              iconData ??
                  (appStateSettings["outlinedIcons"]
                      ? Icons.link_outlined
                      : Icons.link_rounded),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFont(
                text: getDomainNameFromURL(link),
                fontSize: 16,
                maxLines: 1,
              ),
            ),
            if (iconDataAfter != null) Icon(iconDataAfter),
            if (extraWidget != null) extraWidget!,
          ],
        ),
      ),
    );
  }
}

class TransactionNotesTextInput extends StatefulWidget {
  const TransactionNotesTextInput({
    required this.noteInputController,
    required this.setNotesInputFocused,
    required this.setSelectedNoteController,
    super.key,
  });
  final TextEditingController noteInputController;
  final Function(bool) setNotesInputFocused;
  final Function(String note, {bool setInput}) setSelectedNoteController;

  @override
  State<TransactionNotesTextInput> createState() =>
      _TransactionNotesTextInputState();
}

class _TransactionNotesTextInputState extends State<TransactionNotesTextInput> {
  bool notesInputFocused = false;
  late List<String> extractedLinks =
      extractLinks(widget.noteInputController.text);

  void addAttachmentLinkToNote(String? link) {
    if (link == null) return;
    String noteUpdated = widget.noteInputController.text +
        (widget.noteInputController.text == "" ? "" : "\n") +
        (link) +
        " ";

    widget.setSelectedNoteController(noteUpdated);
    updateExtractedLinks(noteUpdated);
  }

  void removeLinkFromNote(String link) {
    String originalText = widget.noteInputController.text;
    String noteUpdated =
        widget.noteInputController.text.replaceAll(link + " ", "");
    if (noteUpdated == originalText) {
      noteUpdated = widget.noteInputController.text.replaceAll(link + "\n", "");
    }
    widget.setSelectedNoteController(noteUpdated);
    updateExtractedLinks(noteUpdated);
  }

  void updateExtractedLinks(String text) {
    List<String> newlyExtractedLinks = extractLinks(text);
    if (newlyExtractedLinks.toString() != extractedLinks.toString()) {
      setState(() {
        extractedLinks = newlyExtractedLinks;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.noteInputController.addListener(_printLatestValue);
  }

  @override
  void dispose() {
    widget.noteInputController.removeListener(_printLatestValue);
    super.dispose();
  }

  void _printLatestValue() {
    updateExtractedLinks(widget.noteInputController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusDirectional.circular(
          getPlatform() == PlatformOS.isIOS ? 8 : 15),
      child: Column(
        children: [
          Focus(
            child: TextInput(
              // Allow the user to edit the notes and scroll freely
              // they have a check button to finish editing
              handleOnTapOutside: false,
              borderRadius: BorderRadius.zero,
              padding: EdgeInsetsDirectional.zero,
              labelText: "notes-placeholder".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.sticky_note_2_outlined
                  : Icons.sticky_note_2_rounded,
              controller: widget.noteInputController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
              onChanged: (text) async {
                widget.setSelectedNoteController(text, setInput: false);
                updateExtractedLinks(text);
              },
            ),
            onFocusChange: (hasFocus) {
              if (hasFocus == false && notesInputFocused == true) {
                notesInputFocused = false;
                widget.setNotesInputFocused(false);
              } else if (hasFocus == true && notesInputFocused == false) {
                notesInputFocused = true;
                widget.setNotesInputFocused(true);
              }
            },
          ),
          HorizontalBreak(
            padding: EdgeInsetsDirectional.zero,
            color: appStateSettings["materialYou"]
                ? dynamicPastel(
                    context,
                    Theme.of(context).colorScheme.secondaryContainer,
                    amount: 0.1,
                    inverse: true,
                  )
                : getColor(context, "lightDarkAccent"),
          ),
          LinkInNotes(
            color: (appStateSettings["materialYou"]
                ? Theme.of(context).colorScheme.secondaryContainer
                : getColor(context, "canvasContainer")),
            link: "add-attachment".tr(),
            iconData: appStateSettings["outlinedIcons"]
                ? Icons.attachment_outlined
                : Icons.attachment_rounded,
            iconDataAfter: appStateSettings["outlinedIcons"]
                ? Icons.add_outlined
                : Icons.add_rounded,
            onTap: () async {
              openBottomSheet(
                context,
                // We need to use the custom controller because the ask for title popup uses the default controller
                // Which we need to control separately
                useCustomController: true,
                reAssignBottomSheetControllerGlobal: false,
                PopupFramework(
                  title: "add-attachment".tr().capitalizeFirstofEach,
                  subtitle: "add-attachment-description".tr(),
                  child: Column(
                    children: [
                      if (kIsWeb == false)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButtonStacked(
                                  filled: false,
                                  alignStart: true,
                                  alignBeside: true,
                                  padding: EdgeInsetsDirectional.symmetric(
                                      horizontal: 20, vertical: 20),
                                  text: "take-photo".tr(),
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.camera_alt_outlined
                                      : Icons.camera_alt_rounded,
                                  onTap: () async {
                                    popRoute(context);
                                    if (await checkLockedFeatureIfInDemoMode(
                                            context) ==
                                        true) {
                                      String? result = await getPhotoAndUpload(
                                          source: ImageSource.camera);
                                      if (result != null)
                                        addAttachmentLinkToNote(result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (kIsWeb == false)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButtonStacked(
                                  filled: false,
                                  alignStart: true,
                                  alignBeside: true,
                                  padding: EdgeInsetsDirectional.symmetric(
                                      horizontal: 20, vertical: 20),
                                  text: "select-photo".tr(),
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.photo_library_outlined
                                      : Icons.photo_library_rounded,
                                  onTap: () async {
                                    popRoute(context);
                                    if (await checkLockedFeatureIfInDemoMode(
                                            context) ==
                                        true) {
                                      String? result = await getPhotoAndUpload(
                                          source: ImageSource.gallery);
                                      addAttachmentLinkToNote(result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButtonStacked(
                                filled: false,
                                alignStart: true,
                                alignBeside: true,
                                padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 20, vertical: 20),
                                text: "select-file".tr(),
                                iconData: appStateSettings["outlinedIcons"]
                                    ? Icons.file_open_outlined
                                    : Icons.file_open_rounded,
                                onTap: () async {
                                  popRoute(context);
                                  if (await checkLockedFeatureIfInDemoMode(
                                          context) ==
                                      true) {
                                    String? result = await getFileAndUpload();
                                    addAttachmentLinkToNote(result);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedSizeSwitcher(
            child: extractedLinks.length <= 0
                ? Container(
                    key: ValueKey(1),
                  )
                : Column(
                    children: [
                      for (String link in extractedLinks)
                        LinkInNotes(
                          link: link,
                          onLongPress: () {
                            copyToClipboard(link);
                          },
                          onTap: () async {
                            openUrl(link);
                          },
                          extraWidget: Row(
                            children: [
                              if (link.contains("drive.google.com"))
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      end: 3, start: 5),
                                  child: IconButtonScaled(
                                    iconData: appStateSettings["outlinedIcons"]
                                        ? Icons.photo_outlined
                                        : Icons.photo_rounded,
                                    iconSize: 16,
                                    scale: 1.6,
                                    onTap: () async {
                                      List<int>? result =
                                          await getGoogleDriveFileImageData(
                                              link);
                                      if (result == null) {
                                        openUrl(link);
                                      } else {
                                        openBottomSheet(
                                          context,
                                          PopupFramework(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadiusDirectional
                                                      .circular(getPlatform() ==
                                                              PlatformOS.isIOS
                                                          ? 10
                                                          : 15),
                                              child: RenderImageData(
                                                imageData: result,
                                                openLinkOnError: () {
                                                  openUrl(link);
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                        // Update the size of the bottom sheet
                                        Future.delayed(
                                            Duration(milliseconds: 300), () {
                                          bottomSheetControllerGlobal
                                              .snapToExtent(0);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    end: 11, start: 5),
                                child: IconButtonScaled(
                                  iconData: appStateSettings["outlinedIcons"]
                                      ? Icons.remove_outlined
                                      : Icons.remove_rounded,
                                  iconSize: 16,
                                  scale: 1.6,
                                  onTap: () {
                                    openPopup(
                                      context,
                                      icon: appStateSettings["outlinedIcons"]
                                          ? Icons.link_off_outlined
                                          : Icons.link_off_rounded,
                                      title: "remove-link-question".tr(),
                                      description:
                                          "remove-link-description".tr(),
                                      onCancel: () {
                                        popRoute(context);
                                      },
                                      onCancelLabel: "cancel".tr(),
                                      onSubmit: () {
                                        removeLinkFromNote(link);
                                        popRoute(context);
                                      },
                                      onSubmitLabel: "remove".tr(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> selectPeriodLength({
  required BuildContext context,
  required int selectedPeriodLength,
  required setSelectedPeriodLength(double period),
}) async {
  openBottomSheet(
    context,
    PopupFramework(
      title: "enter-period-length".tr(),
      child: SelectAmountValue(
        enableDecimal: false,
        amountPassed: selectedPeriodLength.toString(),
        setSelectedAmount: (amount, _) {
          setSelectedPeriodLength(amount);
        },
        next: () async {
          popRoute(context);
        },
        nextLabel: "set-period-length".tr(),
      ),
    ),
  );
}

Future<void> selectRecurrence(
    {required BuildContext context,
    required String selectedRecurrence,
    required int selectedPeriodLength,
    required onChanged(
      String selectedRecurrence,
      BudgetReoccurence selectedRecurrenceEnum,
      String selectedRecurrenceDisplay,
    )}) async {
  openBottomSheet(
    context,
    PopupFramework(
      title: "select-period".tr(),
      child: RadioItems(
        items: ["Daily", "Weekly", "Monthly", "Yearly"],
        initial: selectedRecurrence,
        displayFilter: (item) {
          return item.toString().toLowerCase().tr();
        },
        onChanged: (value) {
          String selectedRecurrence = value;
          BudgetReoccurence selectedRecurrenceEnum = enumRecurrence[value];
          String selectedRecurrenceDisplay;
          if (selectedPeriodLength == 1) {
            selectedRecurrenceDisplay = nameRecurrence[value].toString().tr();
          } else {
            selectedRecurrenceDisplay = namesRecurrence[value].toString().tr();
          }
          onChanged(selectedRecurrence, selectedRecurrenceEnum,
              selectedRecurrenceDisplay);
          popRoute(
            context,
          );
        },
      ),
    ),
  );
}

void setSelectedPeriodLength({
  required double period,
  required String selectedRecurrence,
  required setPeriodLength(
    int selectedPeriodLength,
    String selectedRecurrenceDisplay,
  ),
}) {
  int selectedPeriodLength;
  String selectedRecurrenceDisplay;
  try {
    selectedPeriodLength = period.toInt();

    if (selectedPeriodLength == 1) {
      selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
    } else {
      selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
    }
    setPeriodLength(selectedPeriodLength, selectedRecurrenceDisplay);
  } catch (e) {
    selectedPeriodLength = 0;
    if (selectedPeriodLength == 1) {
      selectedRecurrenceDisplay = nameRecurrence[selectedRecurrence];
    } else {
      selectedRecurrenceDisplay = namesRecurrence[selectedRecurrence];
    }
    setPeriodLength(selectedPeriodLength, selectedRecurrenceDisplay);
  }
  return;
}

class SelectSubcategoryChips extends StatelessWidget {
  const SelectSubcategoryChips(
      {required this.selectedCategoryPk,
      required this.selectedSubCategoryPk,
      required this.setSelectedSubCategory,
      this.padding = EdgeInsetsDirectional.zero,
      super.key});
  final String selectedCategoryPk;
  final String? selectedSubCategoryPk;
  final Function(TransactionCategory category) setSelectedSubCategory;
  final EdgeInsetsDirectional padding;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionCategory>>(
      stream: database.watchAllSubCategoriesOfMainCategory(selectedCategoryPk),
      builder: (context, snapshot) {
        List<TransactionCategory> subCategories = snapshot.data ?? [];
        return AnimatedSizeSwitcher(
          child: (subCategories.length <= 0)
              ? Container()
              : Column(
                  children: [
                    Padding(
                      padding: padding,
                      child: SelectChips(
                        allowMultipleSelected: false,
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.6),
                        onLongPress: (category) {
                          pushRoute(
                            context,
                            AddCategoryPage(
                              category: category,
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.One,
                            ),
                          );
                        },
                        items: subCategories,
                        getSelected: (TransactionCategory category) {
                          return selectedSubCategoryPk == category.categoryPk;
                        },
                        onSelected: (TransactionCategory category) {
                          setSelectedSubCategory(category);
                        },
                        getCustomSelectedColor: (TransactionCategory category) {
                          return dynamicPastel(
                            context,
                            lightenPastel(
                              HexColor(
                                category.colour,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              amount: 0.3,
                            ),
                            amountDark: 0.55,
                            amountLight: 0.3,
                          ).withOpacity(
                            Theme.of(context).brightness == Brightness.light
                                ? 0.8
                                : 1,
                          );
                        },
                        getCustomBorderColor: (TransactionCategory category) {
                          if (selectedSubCategoryPk == category.categoryPk)
                            return lightenPastel(
                              HexColor(
                                category.colour,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              amount: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? 0.8
                                  : 0.4,
                            ).withOpacity(
                              Theme.of(context).brightness == Brightness.light
                                  ? 0.8
                                  : 0.65,
                            );
                          return dynamicPastel(
                            context,
                            lightenPastel(
                              HexColor(
                                category.colour,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              amount: 0.3,
                            ),
                            amount: 0.4,
                          ).withOpacity(
                            Theme.of(context).brightness == Brightness.light
                                ? 0.5
                                : 0.7,
                          );
                        },
                        getLabel: (TransactionCategory category) {
                          return category.name;
                        },
                        extraWidgetAfter: SelectChipsAddButtonExtraWidget(
                          openPage: AddCategoryPage(
                            routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                            mainCategoryPkWhenSubCategory: selectedCategoryPk,
                          ),
                        ),
                        getAvatar: (TransactionCategory category) {
                          return LayoutBuilder(builder: (context, constraints) {
                            return CategoryIcon(
                              categoryPk: "-1",
                              category: category,
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
                    ),
                  ],
                ),
        );
      },
    );
  }
}

List<dynamic>
    getTransactionSpecialTypesToShowGivenInitialTypeWhenAddingTransaction(
        TransactionSpecialType? transactionType, bool isAddedToLoanObjective) {
  List<dynamic> defaultList = [
    null,
    ...TransactionSpecialType.values,
    //"installments"
  ];
  if (isAddedToLoanObjective)
    return [
      null,
      TransactionSpecialType.upcoming,
      TransactionSpecialType.repetitive,
      TransactionSpecialType.subscription,
    ];
  else if (transactionType == null)
    return defaultList;
  else if ([TransactionSpecialType.credit, TransactionSpecialType.debt]
      .contains(transactionType))
    return [TransactionSpecialType.credit, TransactionSpecialType.debt];
  else if ([
    TransactionSpecialType.subscription,
  ].contains(transactionType))
    return [TransactionSpecialType.subscription];
  else if ([
    TransactionSpecialType.upcoming,
    TransactionSpecialType.repetitive,
    TransactionSpecialType.subscription,
  ].contains(transactionType))
    return [
      TransactionSpecialType.upcoming,
      TransactionSpecialType.repetitive,
      TransactionSpecialType.subscription
    ];
  return defaultList;
}

class TitleInput extends StatefulWidget {
  const TitleInput({
    required this.setSelectedTitle,
    this.titleInputController,
    this.titleInputScrollController,
    required this.setSelectedCategory,
    required this.setSelectedSubCategory,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 22),
    this.alsoSearchCategories = true,
    this.onNewRecommendedTitle,
    this.onRecommendedTitleTapped,
    this.handleOnRecommendedTitleTapped = true,
    this.unfocusWhenRecommendedTapped = true,
    this.onSubmitted,
    this.autoFocus,
    this.showCategoryIconForRecommendedTitles = true,
    this.labelText,
    this.textToSearchFilter,
    this.getTextToExclude,
    this.onDeleteButton,
    this.tryToCompleteSearch = false,
    this.resizePopupWhenChanged = false,
    this.focusNode,
    this.clearWhenUnfocused = false,
    this.maxLines,
    super.key,
  });
  final Function(String title) setSelectedTitle;
  final TextEditingController? titleInputController;
  final ScrollController? titleInputScrollController;
  final Function(TransactionCategory category) setSelectedCategory;
  final Function(TransactionCategory category) setSelectedSubCategory;
  final EdgeInsetsDirectional padding;
  final bool alsoSearchCategories;
  final VoidCallback? onNewRecommendedTitle;
  final Function(TransactionAssociatedTitleWithCategory)?
      onRecommendedTitleTapped;
  final bool handleOnRecommendedTitleTapped;
  final bool unfocusWhenRecommendedTapped;
  final Function(String)? onSubmitted;
  final bool? autoFocus;
  final bool showCategoryIconForRecommendedTitles;
  final String? labelText;
  final String Function(String)? textToSearchFilter;
  final List<String> Function(String)? getTextToExclude;
  final VoidCallback? onDeleteButton;
  final bool tryToCompleteSearch;
  final bool resizePopupWhenChanged;
  final FocusNode? focusNode;
  final bool clearWhenUnfocused;
  final int? maxLines;

  @override
  State<TitleInput> createState() => _TitleInputState();
}

class _TitleInputState extends State<TitleInput> {
  late TextEditingController _titleInputController;

  @override
  void initState() {
    super.initState();
    if (widget.titleInputController == null) {
      _titleInputController = new TextEditingController();
    } else {
      _titleInputController = widget.titleInputController!;
    }
  }

  List<TransactionAssociatedTitleWithCategory> foundAssociatedTitles = [];

  void fixResizingPopup() {
    Future.delayed(Duration(milliseconds: 100), () {
      bottomSheetControllerGlobal.snapToExtent(1,
          duration: Duration(milliseconds: 625));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadiusDirectional.circular(
            getPlatform() == PlatformOS.isIOS ? 8 : 15),
        child: Column(
          children: [
            Focus(
              onFocusChange: (value) {
                if (value == false && widget.clearWhenUnfocused == true)
                  setState(() {
                    foundAssociatedTitles = [];
                  });
              },
              child: TextInput(
                // To allow the user to select and scroll to the dropdown options
                handleOnTapOutside: false,
                maxLines: widget.maxLines,
                focusNode: widget.focusNode,
                scrollController: widget.titleInputScrollController,
                borderRadius: BorderRadius.zero,
                padding: EdgeInsetsDirectional.zero,
                labelText: widget.labelText ?? "title-placeholder".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.title_outlined
                    : Icons.title_rounded,
                controller: _titleInputController,
                onChanged: (text) async {
                  widget.setSelectedTitle(text);
                  List<TransactionAssociatedTitleWithCategory>
                      newFoundAssociatedTitles = [];
                  if (text.trim() != "") {
                    newFoundAssociatedTitles =
                        await database.getSimilarAssociatedTitles(
                      title: widget.textToSearchFilter != null
                          ? widget.textToSearchFilter!(text)
                          : text,
                      excludeTitles: widget.getTextToExclude != null
                          ? widget.getTextToExclude!(text)
                          : [],
                      limit: enableDoubleColumn(context) ? 5 : 3,
                      alsoSearchCategories: widget.alsoSearchCategories,
                      tryToCompleteSearch: widget.tryToCompleteSearch,
                    );
                  }

                  if (foundAssociatedTitles.toString() !=
                      newFoundAssociatedTitles.toString()) {
                    if (widget.resizePopupWhenChanged) fixResizingPopup();
                    if (widget.onNewRecommendedTitle != null)
                      widget.onNewRecommendedTitle!();
                  }

                  foundAssociatedTitles = newFoundAssociatedTitles;
                  setState(() {});
                },
                onSubmitted: widget.onSubmitted,
                autoFocus:
                    widget.autoFocus ?? kIsWeb && getIsFullScreen(context),
              ),
            ),
            AnimatedSizeSwitcher(
              child: foundAssociatedTitles.length <= 0
                  ? Container(
                      key: ValueKey(0),
                    )
                  : AnimatedSize(
                      key: ValueKey(1),
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: AlignmentDirectional.topCenter,
                      child: Column(
                        children: [
                          HorizontalBreak(
                            padding: EdgeInsetsDirectional.zero,
                            color: dynamicPastel(
                              context,
                              Theme.of(context).colorScheme.secondaryContainer,
                              amount: 0.1,
                              inverse: true,
                            ),
                          ),
                          for (TransactionAssociatedTitleWithCategory foundAssociatedTitle
                              in foundAssociatedTitles)
                            Container(
                              color: appStateSettings["materialYou"]
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : getColor(context, "canvasContainer"),
                              child: Tappable(
                                borderRadius: 0,
                                color: Colors.transparent,
                                onTap: () async {
                                  if (widget.handleOnRecommendedTitleTapped) {
                                    if (foundAssociatedTitle
                                            .category.mainCategoryPk !=
                                        null) {
                                      widget.setSelectedCategory(
                                          await database.getCategoryInstance(
                                              foundAssociatedTitle
                                                  .category.mainCategoryPk!));
                                      widget.setSelectedSubCategory(
                                          foundAssociatedTitle.category);
                                    } else {
                                      widget.setSelectedCategory(
                                          foundAssociatedTitle.category);
                                    }

                                    if (foundAssociatedTitle.type !=
                                            TitleType.CategoryName &&
                                        foundAssociatedTitle.type !=
                                            TitleType.SubCategoryName) {
                                      widget.setSelectedTitle(
                                          foundAssociatedTitle.title.title);
                                      setTextInput(_titleInputController,
                                          foundAssociatedTitle.title.title);
                                    } else {
                                      widget.setSelectedTitle("");
                                      setTextInput(_titleInputController, "");
                                    }

                                    if (widget.unfocusWhenRecommendedTapped)
                                      FocusScope.of(context).unfocus();
                                  }

                                  setState(() {
                                    foundAssociatedTitles = [];
                                  });

                                  if (widget.onRecommendedTitleTapped != null)
                                    widget.onRecommendedTitleTapped!(
                                        foundAssociatedTitle);
                                  if (widget.resizePopupWhenChanged)
                                    fixResizingPopup();
                                },
                                child: Row(
                                  children: [
                                    if (widget
                                        .showCategoryIconForRecommendedTitles)
                                      IgnorePointer(
                                        child: CategoryIcon(
                                          categoryPk: foundAssociatedTitle
                                              .title.categoryFk,
                                          size: 23,
                                          margin: EdgeInsetsDirectional.zero,
                                          sizePadding: 16,
                                          borderRadius: 0,
                                        ),
                                      ),
                                    SizedBox(width: 13),
                                    Expanded(
                                        child: Padding(
                                      padding: widget
                                              .showCategoryIconForRecommendedTitles
                                          ? EdgeInsetsDirectional.zero
                                          : const EdgeInsetsDirectional.only(
                                              bottom: 12, top: 11, start: 5),
                                      child: TextFont(
                                        text: "",
                                        richTextSpan: generateSpans(
                                          context: context,
                                          fontSize: 16,
                                          mainText:
                                              foundAssociatedTitle.title.title,
                                          boldedText: foundAssociatedTitle
                                              .partialTitleString,
                                        ),
                                      ),
                                    )),
                                    Opacity(
                                      opacity: 0.65,
                                      child: foundAssociatedTitle.type ==
                                                  TitleType.CategoryName ||
                                              foundAssociatedTitle.type ==
                                                  TitleType.SubCategoryName
                                          ? Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .symmetric(
                                                      horizontal: 7.5),
                                              child: Icon(
                                                appStateSettings[
                                                        "outlinedIcons"]
                                                    ? Icons.category_outlined
                                                    : Icons.category_rounded,
                                                size: 20,
                                              ),
                                            )
                                          : IconButtonScaled(
                                              iconData: appStateSettings[
                                                      "outlinedIcons"]
                                                  ? Icons.clear_outlined
                                                  : Icons.clear_rounded,
                                              iconSize: 18,
                                              scale: 1.1,
                                              onTap: () async {
                                                if (widget.onDeleteButton !=
                                                    null)
                                                  widget.onDeleteButton!();
                                                if (widget
                                                    .resizePopupWhenChanged)
                                                  fixResizingPopup();

                                                DeletePopupAction? action =
                                                    await deleteAssociatedTitlePopup(
                                                  context,
                                                  title: foundAssociatedTitle
                                                      .title,
                                                  routesToPopAfterDelete:
                                                      RoutesToPopAfterDelete
                                                          .None,
                                                );
                                                if (action ==
                                                    DeletePopupAction.Delete) {
                                                  foundAssociatedTitles.remove(
                                                      foundAssociatedTitle);
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                    ),
                                    SizedBox(width: 5),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
