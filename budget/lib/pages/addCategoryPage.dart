import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/modified/reorderable_list.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/editAssociatedTitlesPage.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/iconButtonScaled.dart';
import 'package:budget/widgets/incomeExpenseTabSelector.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/saveBottomButton.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/selectCategoryImage.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/extraInfoBoxes.dart';
import 'addButton.dart';

class AddCategoryPage extends StatefulWidget {
  AddCategoryPage({
    Key? key,
    this.category,
    required this.routesToPopAfterDelete,
    this.mainCategoryPkWhenSubCategory,
    this.initiallyIsExpense = true,
  }) : super(key: key);

  //When a category is passed in, we are editing that category
  final TransactionCategory? category;
  final RoutesToPopAfterDelete routesToPopAfterDelete;
  final String?
      mainCategoryPkWhenSubCategory; //When this is null, it is a main category not a sub category
  final bool initiallyIsExpense;
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage>
    with SingleTickerProviderStateMixin {
  bool isMainCategoryWhenCreating = true;
  String? mainCategoryPkForSubcategoryWhenCreating;
  String? selectedTitle;
  late String? selectedImage = widget.category == null ? "image.png" : null;
  String? selectedEmoji;
  late Color? selectedColor = widget.category?.colour == null
      ? null
      : HexColor(widget.category?.colour);
  late bool selectedIncome = widget.initiallyIsExpense == false;
  bool? canAddCategory;
  TransactionCategory? widgetCategory;
  List<String>? selectedMembers;
  TextEditingController _titleController = TextEditingController();
  bool userAttemptedToChangeTitle = false;
  FocusNode _titleFocusNode = FocusNode();
  late TabController _incomeTabController =
      TabController(length: 2, vsync: this);
  late bool isSubCategory = widget.mainCategoryPkWhenSubCategory != null ||
      widget.category?.mainCategoryPk != null;

  void setSelectedColor(Color? color) {
    setState(() {
      selectedColor = color;
    });
    determineBottomButton();
    return;
  }

  void setSelectedImage(String? image) {
    setState(() {
      selectedImage = (image ?? "").replaceFirst("assets/categories/", "");
      selectedEmoji = null;
    });
    determineBottomButton();
    return;
  }

  void setSelectedEmoji(String? emoji) {
    setState(() {
      selectedEmoji = emoji;
      selectedImage = null;
    });
    determineBottomButton();
    return;
  }

  void setSelectedTitle(String title,
      {bool userAttemptedToChangeTitlePassed = false,
      bool modifyControllerValue = false}) {
    setState(() {
      selectedTitle = title;
      userAttemptedToChangeTitle =
          title == "" ? false : userAttemptedToChangeTitlePassed;
    });
    if (modifyControllerValue) _titleController.text = title;
    determineBottomButton();
    return;
  }

  void setSelectedIncome(bool income) {
    setState(() {
      selectedIncome = income;
    });
    determineBottomButton();
    return;
  }

  void setSelectedMembers(List<String>? members) {
    if (selectedMembers != null) {
      determineBottomButton();
    }
    setState(() {
      selectedMembers = members;
    });
    return;
  }

  determineBottomButton() {
    if (selectedTitle != null) {
      if (canAddCategory != true)
        this.setState(() {
          canAddCategory = true;
        });
    } else {
      if (canAddCategory != false)
        this.setState(() {
          canAddCategory = false;
        });
    }
  }

  Future addCategory() async {
    TransactionCategory createdCategory = await createTransactionCategory();
    await database.createOrUpdateCategory(
      insert: widget.category == null,
      createdCategory,
    );
    if (canSelectIfSubCategoryOrMainCategory() &&
        mainCategoryPkForSubcategoryWhenCreating != null) {
      TransactionCategory categoryMain = await database
          .getCategoryInstance(mainCategoryPkForSubcategoryWhenCreating!);
      openSnackbar(
        SnackbarMessage(
          title: "subcategory-created".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.move_to_inbox_outlined
              : Icons.move_to_inbox_rounded,
          description: (selectedTitle ?? "") + " → " + categoryMain.name,
        ),
      );
    }
    savingHapticFeedback();
    popRoute(context);
  }

  Future<TransactionCategory> createTransactionCategory() async {
    TransactionCategory? currentInstance;
    if (widget.category != null) {
      currentInstance =
          await database.getCategoryInstance(widget.category!.categoryPk);
    }
    return TransactionCategory(
      categoryPk: widget.category != null ? widget.category!.categoryPk : "-1",
      name: (selectedTitle ?? "").trim(),
      dateCreated: widget.category != null
          ? widget.category!.dateCreated
          : DateTime.now(),
      dateTimeModified: null,
      income: selectedIncome,
      order: widget.category != null
          ? widget.category!.order
          : canSelectIfSubCategoryOrMainCategory() &&
                  mainCategoryPkForSubcategoryWhenCreating != null
              ? await database.getAmountOfSubCategories(
                  mainCategoryPkForSubcategoryWhenCreating!)
              : widget.mainCategoryPkWhenSubCategory != null
                  ? await database.getAmountOfSubCategories(
                      widget.mainCategoryPkWhenSubCategory!)
                  : await database.getAmountOfCategories(),
      colour: toHexString(selectedColor),
      iconName: selectedImage,
      emojiIconName: selectedEmoji,
      methodAdded:
          widget.category != null ? widget.category!.methodAdded : null,
      mainCategoryPk: canSelectIfSubCategoryOrMainCategory() &&
              mainCategoryPkForSubcategoryWhenCreating != null
          ? mainCategoryPkForSubcategoryWhenCreating
          : widget.mainCategoryPkWhenSubCategory != null
              ? widget.mainCategoryPkWhenSubCategory
              : widget.category?.mainCategoryPk,
    );
  }

  TransactionCategory? categoryInitial;

  void showDiscardChangesPopupIfNotEditing() async {
    TransactionCategory categoryCreated = await createTransactionCategory();
    categoryCreated = categoryCreated.copyWith(
      dateCreated: categoryInitial?.dateCreated,
      mainCategoryPk: Value(categoryInitial?.mainCategoryPk),
    );
    if (categoryCreated != categoryInitial && widget.category == null) {
      discardChangesPopup(context, forceShow: true);
    } else {
      popRoute(context);
    }
  }

  bool canSelectIfSubCategoryOrMainCategory() {
    return widget.category == null &&
        widget.mainCategoryPkWhenSubCategory == null &&
        isSubCategory == false;
  }

  @override
  void initState() {
    super.initState();
    widgetCategory = widget.category;
    selectedColor = widget.category != null
        ? (widget.category!.colour == null
            ? null
            : HexColor(widget.category!.colour))
        : null;
    if (widget.category != null) {
      setState(() {
        selectedTitle = widget.category?.name;
        selectedImage = widget.category?.iconName;
        selectedEmoji = widget.category?.emojiIconName;
        selectedIncome = widget.category!.income;
        userAttemptedToChangeTitle = true;
      });
      Future.delayed(Duration.zero, () async {
        _titleController.text = selectedTitle ?? "";
        _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length));
        await database.fixOrderCategories(
            mainCategoryPkIfSubCategoryOrderFixing:
                widget.category!.categoryPk);
      });
    }

    if (selectedIncome == true) {
      _incomeTabController.animateTo(1);
    } else {
      _incomeTabController.animateTo(0);
    }

    //Set to false because we can't save until we made some changes
    setState(() {
      canAddCategory = false;
    });
    if (widget.category == null) {
      Future.delayed(Duration.zero, () async {
        categoryInitial = await createTransactionCategory();
      });
    }
  }

  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget balanceCorrectionCategorySettings = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
      child: Column(
        children: [
          SizedBox(height: 20),
          TipBox(
            onTap: () {},
            text: "balance-correction-category-info".tr(),
            settingsString: null,
          ),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withOpacity(0.7),
              borderRadius: BorderRadiusDirectional.all(
                  Radius.circular(getPlatform() == PlatformOS.isIOS ? 10 : 15)),
            ),
            child: Column(
              children: [
                SettingsContainerDropdown(
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.swap_vert_outlined
                      : Icons.swap_vert_rounded,
                  enableBorderRadius: true,
                  title: "amount-color".tr(),
                  initial: appStateSettings["balanceTransferAmountColor"],
                  items: ["green-or-red", "no-color"],
                  getLabel: (item) {
                    return item.tr();
                  },
                  onChanged: (item) {
                    updateSettings("balanceTransferAmountColor", item,
                        updateGlobalState: true);
                  },
                ),
                IgnorePointer(
                  child: TransactionEntry(
                    useHorizontalPaddingConstrained: false,
                    customPadding:
                        EdgeInsetsDirectional.symmetric(horizontal: 8),
                    containerColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.7),
                    openPage: Container(),
                    transaction: Transaction(
                      transactionPk: "-1",
                      name: "",
                      amount: 100,
                      note: "",
                      categoryFk: "0",
                      walletFk: appStateSettings["selectedWalletPk"],
                      dateCreated: DateTime.now(),
                      income: false,
                      paid: true,
                      skipPaid: false,
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        if (widget.category != null) {
          discardChangesPopup(context,
              previousObject: widget.category!,
              currentObject: await createTransactionCategory());
        } else {
          showDiscardChangesPopupIfNotEditing();
        }
        return false;
      },
      child: PageFramework(
        dragDownToDismissEnabled: dragDownToDismissEnabled,
        horizontalPaddingConstrained: true,
        resizeToAvoidBottomInset: true,
        dragDownToDismiss: true,
        subtitle: widget.mainCategoryPkWhenSubCategory == null
            ? null
            : StreamBuilder<TransactionCategory>(
                stream: database
                    .watchCategory(widget.mainCategoryPkWhenSubCategory!),
                builder: (context, snapshot) {
                  return TextFont(
                    text: "for".tr().capitalizeFirst +
                        " " +
                        (snapshot.data?.name ?? ""),
                    fontSize: getCenteredTitle(
                                    context: context,
                                    backButtonEnabled: true) ==
                                true &&
                            getCenteredTitleSmall(
                                    context: context,
                                    backButtonEnabled: true) ==
                                false
                        ? 30
                        : 22,
                    maxLines: 5,
                    fontWeight: FontWeight.bold,
                  );
                }),
        subtitleSize: widget.mainCategoryPkWhenSubCategory == null ? null : 10,
        subtitleAlignment: AlignmentDirectional.bottomStart,
        title: widget.category == null
            ? "add-category".tr()
            : "edit-category".tr(),
        onBackButton: () async {
          if (widget.category != null) {
            discardChangesPopup(context,
                previousObject: widget.category!,
                currentObject: await createTransactionCategory());
          } else {
            showDiscardChangesPopupIfNotEditing();
          }
        },
        onDragDownToDismiss: () async {
          if (widget.category != null) {
            discardChangesPopup(context,
                previousObject: widget.category!,
                currentObject: await createTransactionCategory());
          } else {
            showDiscardChangesPopupIfNotEditing();
          }
        },
        actions: [
          widget.category != null &&
                  widget.routesToPopAfterDelete !=
                      RoutesToPopAfterDelete.PreventDelete
              ? IconButton(
                  padding: EdgeInsetsDirectional.all(15),
                  tooltip: "delete-category".tr(),
                  onPressed: () {
                    deleteCategoryPopup(
                      context,
                      category: widgetCategory!,
                      routesToPopAfterDelete: widget.routesToPopAfterDelete,
                    );
                  },
                  icon: Icon(appStateSettings["outlinedIcons"]
                      ? Icons.delete_outlined
                      : Icons.delete_rounded),
                )
              : SizedBox.shrink()
        ],
        staticOverlay: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: selectedTitle == "" || selectedTitle == null
              ? SaveBottomButton(
                  label: "set-name".tr(),
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    Future.delayed(Duration(milliseconds: 100), () {
                      _titleFocusNode.requestFocus();
                    });
                  },
                  disabled: false,
                )
              : canSelectIfSubCategoryOrMainCategory() &&
                      mainCategoryPkForSubcategoryWhenCreating == null &&
                      isMainCategoryWhenCreating == false
                  ? SaveBottomButton(
                      label: "select-main-category".tr(),
                      onTap: () async {
                        openBottomSheet(
                          context,
                          PopupFramework(
                            title: "select-category".tr(),
                            subtitle:
                                "select-the-main-category-for-this-subcategory"
                                    .tr(),
                            child: SelectCategory(
                              setSelectedCategory:
                                  (TransactionCategory category) {
                                mainCategoryPkForSubcategoryWhenCreating =
                                    category.categoryPk;
                              },
                              next: () async {
                                await addCategory();
                              },
                              addButton: false,
                            ),
                          ),
                        );
                      },
                      disabled: !(canAddCategory ?? false),
                    )
                  : SaveBottomButton(
                      label: widget.category == null
                          ? "add-category".tr()
                          : "save-changes".tr(),
                      onTap: () async {
                        await addCategory();
                      },
                      disabled: !(canAddCategory ?? false),
                    ),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isSubCategory == false &&
                    widget.category?.categoryPk != "0")
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 13),
                    child: IncomeExpenseTabSelector(
                      onTabChanged: setSelectedIncome,
                      initialTabIsIncome: selectedIncome,
                      hasBorderRadius: true,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Tappable(
                      onTap: () {
                        openBottomSheet(
                          context,
                          PopupFramework(
                            title: "select-icon".tr(),
                            child: SelectCategoryImage(
                              setSelectedImage: setSelectedImage,
                              setSelectedEmoji: setSelectedEmoji,
                              selectedImage: "assets/categories/" +
                                  selectedImage.toString(),
                              setSelectedTitle: (String? titleRecommendation) {
                                if (titleRecommendation != null &&
                                    (userAttemptedToChangeTitle == false ||
                                        selectedTitle == "" ||
                                        selectedTitle == null))
                                  setSelectedTitle(
                                      titleRecommendation.capitalizeFirstofEach,
                                      modifyControllerValue: true);
                              },
                            ),
                          ),
                          showScrollbar: true,
                        );
                      },
                      color: Colors.transparent,
                      child: IconPreview(
                        selectedImage: selectedImage,
                        selectedEmoji: selectedEmoji,
                        selectedColor: selectedColor,
                      ),
                    ),
                    Expanded(
                      child: IntrinsicWidth(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          child: Builder(builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextInput(
                                  autoFocus: kIsWeb && getIsFullScreen(context),
                                  focusNode: _titleFocusNode,
                                  labelText: "name-placeholder".tr(),
                                  bubbly: false,
                                  controller: _titleController,
                                  onChanged: (text) {
                                    setSelectedTitle(text,
                                        userAttemptedToChangeTitlePassed: true);
                                  },
                                  padding: EdgeInsetsDirectional.zero,
                                  fontSize: getIsFullScreen(context) ? 34 : 27,
                                  fontWeight: FontWeight.bold,
                                ),
                                if (widget.category?.categoryPk != "0")
                                  SizedBox(height: 17),
                                if (widget.category?.categoryPk == "0")
                                  AnimatedOpacity(
                                    opacity: selectedTitle !=
                                                "balance-correction".tr() &&
                                            selectedTitle !=
                                                "balance-correction"
                                                    .tr()
                                                    .capitalizeFirstofEach
                                        ? 1
                                        : 0,
                                    duration: Duration(milliseconds: 500),
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 5),
                                      child: TextFont(
                                        text: "balance-correction".tr(),
                                        fontSize: 15,
                                        textColor:
                                            getColor(context, "textLight"),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 65,
                  child: SelectColor(
                    horizontalList: true,
                    selectedColor: selectedColor,
                    setSelectedColor: setSelectedColor,
                    previewBuilder: (color) => IconPreview(
                      selectedImage: selectedImage,
                      selectedEmoji: selectedEmoji,
                      selectedColor: color,
                      switcherDuration: Duration.zero,
                      smallPreview: true,
                    ),
                  ),
                ),
                if (widget.category?.categoryPk == "0")
                  balanceCorrectionCategorySettings,
                widget.category?.categoryPk == "0" ||
                        widgetCategory == null ||
                        widget.routesToPopAfterDelete ==
                            RoutesToPopAfterDelete.PreventDelete
                    ? SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          top: 20,
                        ),
                        child: SettingsContainer(
                          isOutlined: true,
                          onTap: () async {
                            if (widget.category != null) {
                              if (isSubCategory) {
                                mergeSubcategoryPopup(context,
                                    subcategoryOriginal: widget.category!,
                                    routesToPopAfterDelete:
                                        widget.routesToPopAfterDelete);
                              } else {
                                mergeCategoryPopup(
                                  context,
                                  categoryOriginal: widget.category!,
                                  routesToPopAfterDelete:
                                      widget.routesToPopAfterDelete,
                                );
                              }
                            }
                          },
                          title: isSubCategory
                              ? "merge-subcategory".tr()
                              : "merge-category".tr(),
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.merge_outlined
                              : Icons.merge_rounded,
                          iconScale: 1,
                          isWideOutlined: true,
                        ),
                      ),
                widgetCategory == null ||
                        widget.routesToPopAfterDelete ==
                            RoutesToPopAfterDelete.PreventDelete ||
                        isSubCategory == false
                    ? SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          top: 10,
                        ),
                        child: SettingsContainer(
                          isOutlined: true,
                          onTap: () async {
                            makeMainCategoryPopup(context,
                                subcategoryOriginal: widget.category!,
                                routesToPopAfterDelete:
                                    widget.routesToPopAfterDelete);
                          },
                          title: "make-main-category".tr(),
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.inbox_outlined
                              : Icons.inbox_rounded,
                          iconScale: 1,
                          isWideOutlined: true,
                        ),
                      ),
                widget.category?.categoryPk == "0" || widgetCategory == null
                    ? SizedBox.shrink()
                    : SizedBox(height: 20),
                widget.category?.categoryPk == "0" ||
                        widgetCategory == null ||
                        isSubCategory
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 20),
                        child: TextFont(
                          text: "subcategories".tr(),
                          textColor: getColor(context, "textLight"),
                          fontSize: 16,
                        ),
                      ),
                widget.category?.categoryPk == "0" || widgetCategory == null
                    ? SizedBox.shrink()
                    : SizedBox(height: 5),
              ],
            ),
          ),
          if (canSelectIfSubCategoryOrMainCategory())
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 20),
              child: SelectIsSubcategory(
                isMainCategoryWhenCreating: isMainCategoryWhenCreating,
                onTap: (value) {
                  setState(() {
                    isMainCategoryWhenCreating = value;
                  });
                },
                setMainCategoryPkForSubcategoryWhenCreating: (value) {
                  mainCategoryPkForSubcategoryWhenCreating = value;
                },
              ),
            )),
          if ((widget.category?.categoryPk == "0" ||
                  widgetCategory == null ||
                  isSubCategory) ==
              false)
            StreamBuilder<List<TransactionCategory>>(
              stream: database.watchAllSubCategoriesOfMainCategory(
                  widget.category!.categoryPk),
              builder: (context, snapshot) {
                List<TransactionCategory> subCategories = snapshot.data ?? [];
                if (subCategories.length <= 0 &&
                    widget.routesToPopAfterDelete !=
                        RoutesToPopAfterDelete.PreventDelete)
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                        top: 10,
                        bottom: 8,
                      ),
                      child: SettingsContainer(
                        isOutlined: true,
                        onTap: () async {
                          if (widget.category != null)
                            makeSubCategoryPopup(
                              context,
                              categoryOriginal: widget.category!,
                              routesToPopAfterDelete:
                                  widget.routesToPopAfterDelete,
                            );
                        },
                        title: "make-subcategory".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.move_to_inbox_outlined
                            : Icons.move_to_inbox_rounded,
                        iconScale: 1,
                        isWideOutlined: true,
                      ),
                    ),
                  );
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
                    TransactionCategory category = subCategories[index];
                    return Padding(
                      key: ValueKey(category.categoryPk),
                      padding:
                          const EdgeInsetsDirectional.symmetric(horizontal: 4),
                      child: EditRowEntry(
                        index: index,
                        canReorder: subCategories.length != 1,
                        currentReorder:
                            currentReorder != -1 && currentReorder != index,
                        padding: EdgeInsetsDirectional.symmetric(
                          vertical: 7,
                          horizontal:
                              getPlatform() == PlatformOS.isIOS ? 17 : 7,
                        ),
                        canDelete: widget.routesToPopAfterDelete !=
                            RoutesToPopAfterDelete.PreventDelete,
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 3),
                            CategoryIcon(
                              categoryPk: category.categoryPk,
                              size: 25,
                              margin: EdgeInsetsDirectional.zero,
                              sizePadding: 20,
                              borderRadius: 1000,
                              category: category,
                              onLongPress: null,
                              onTap: null,
                              canEditByLongPress: false,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFont(
                                    text: category.name
                                    // +
                                    //     " - " +
                                    //     category.order.toString()
                                    ,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  StreamBuilder<List<int?>>(
                                    stream: database
                                        .watchTotalCountOfTransactionsInSubCategory(
                                            category.categoryPk),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return TextFont(
                                          textAlign: TextAlign.start,
                                          text: snapshot.data![0].toString() +
                                              " " +
                                              (snapshot.data![0] == 1
                                                  ? "transaction"
                                                      .tr()
                                                      .toLowerCase()
                                                  : "transactions"
                                                      .tr()
                                                      .toLowerCase()),
                                          fontSize: 14,
                                          textColor: getColor(context, "black")
                                              .withOpacity(0.65),
                                        );
                                      } else {
                                        return TextFont(
                                          textAlign: TextAlign.start,
                                          text: "/ transactions",
                                          fontSize: 14,
                                          textColor: getColor(context, "black")
                                              .withOpacity(0.65),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onDelete: () async {
                          return (await deleteCategoryPopup(
                                context,
                                category: category,
                                routesToPopAfterDelete:
                                    RoutesToPopAfterDelete.None,
                              )) ==
                              DeletePopupAction.Delete;
                        },
                        openPage: AddCategoryPage(
                          category: category,
                          routesToPopAfterDelete: widget.routesToPopAfterDelete,
                          mainCategoryPkWhenSubCategory:
                              widget.category!.categoryPk,
                        ),
                      ),
                    );
                  },
                  itemCount: subCategories.length,
                  onReorder: (_intPrevious, _intNew) async {
                    TransactionCategory oldCategory =
                        subCategories[_intPrevious];

                    if (_intNew > _intPrevious) {
                      await database.moveCategory(
                        oldCategory.categoryPk,
                        _intNew - 1,
                        oldCategory.order,
                        mainCategoryPk: oldCategory.mainCategoryPk,
                      );
                    } else {
                      await database.moveCategory(
                        oldCategory.categoryPk,
                        _intNew,
                        oldCategory.order,
                        mainCategoryPk: oldCategory.mainCategoryPk,
                      );
                    }
                    return true;
                  },
                );
              },
            ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.category?.categoryPk == "0" ||
                        widgetCategory == null ||
                        isSubCategory
                    ? SizedBox.shrink()
                    : Row(
                        children: [
                          Expanded(
                            child: AddButton(
                              openPage: AddCategoryPage(
                                routesToPopAfterDelete:
                                    RoutesToPopAfterDelete.None,
                                mainCategoryPkWhenSubCategory:
                                    widget.category!.categoryPk,
                              ),
                              margin: EdgeInsetsDirectional.only(
                                start: 13,
                                end: 13,
                                bottom: 6,
                                top: 5,
                              ),
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                widgetCategory == null || isSubCategory
                    ? SizedBox.shrink()
                    : SizedBox(height: 20),
                if (widget.category != null)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    child: TextFont(
                      text: "associated-titles".tr(),
                      textColor: getColor(context, "textLight"),
                      fontSize: 16,
                    ),
                  ),
                if (widget.category != null) SizedBox(height: 5),
                if (widget.category != null)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    child: TextFont(
                      text: "associated-titles-description".tr(),
                      textColor: getColor(context, "textLight"),
                      fontSize: 13,
                      maxLines: 10,
                    ),
                  ),
                if (widget.category != null) SizedBox(height: 10),
                if (widget.category != null)
                  Row(
                    children: [
                      Expanded(
                        child: AddButton(
                            margin: EdgeInsetsDirectional.only(
                              start: 15,
                              end: 15,
                              bottom: 9,
                              top: 4,
                            ),
                            onTap: () {
                              if (canAddCategory != true)
                                setState(() {
                                  canAddCategory = true;
                                });
                              openBottomSheet(
                                context,
                                popupWithKeyboard: true,
                                AddTitle(category: widget.category),
                              );
                            }),
                      ),
                    ],
                  ),
                if (widget.category != null)
                  StreamBuilder<List<TransactionAssociatedTitle>>(
                      stream: database.watchAllAssociatedTitlesInCategory(
                        widget.category == null
                            ? "-1"
                            : widget.category!.categoryPk,
                        limit: 30,
                      ),
                      builder: (context, snapshot) {
                        // print(snapshot.data);
                        if (snapshot.hasData &&
                            (snapshot.data ?? []).length > 0) {
                          return Column(
                            children: [
                              for (int i = 0; i < snapshot.data!.length; i++)
                                Builder(builder: (context) {
                                  TransactionAssociatedTitle associatedTitle =
                                      snapshot.data![i];
                                  return Padding(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                            horizontal: 15),
                                    child: AssociatedTitleContainer(
                                      title: associatedTitle,
                                      setTitle: (text) async {
                                        await database
                                            .createOrUpdateAssociatedTitle(
                                          TransactionAssociatedTitle(
                                            associatedTitlePk: associatedTitle
                                                .associatedTitlePk,
                                            categoryFk: widget.category == null
                                                ? "-1"
                                                : widget.category!.categoryPk,
                                            isExactMatch:
                                                associatedTitle.isExactMatch,
                                            title: text.trim(),
                                            dateCreated: DateTime.now(),
                                            dateTimeModified: null,
                                            order: associatedTitle.order,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                            ],
                          );
                        }
                        return SizedBox();
                      }),
                SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddTitle extends StatefulWidget {
  const AddTitle({required this.category, super.key});
  final TransactionCategory? category;
  @override
  State<AddTitle> createState() => _AddTitleState();
}

class _AddTitleState extends State<AddTitle> {
  String selectedText = "";
  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "set-title".tr(),
      child: SelectText(
        enableButton: selectedText.trim().length > 0,
        buttonLabel: "set-title".tr(),
        setSelectedText: (value) {
          setState(() {
            selectedText = value;
          });
        },
        labelText: "set-title".tr(),
        placeholder: "title-placeholder".tr(),
        nextWithInput: (text) async {
          int length = await database.getAmountOfAssociatedTitles();
          await database.createOrUpdateAssociatedTitle(
            insert: true,
            TransactionAssociatedTitle(
              associatedTitlePk: "-1",
              categoryFk:
                  widget.category == null ? "-1" : widget.category!.categoryPk,
              isExactMatch: false,
              title: text.trim(),
              dateCreated: DateTime.now(),
              dateTimeModified: null,
              order: length,
            ),
          );
        },
      ),
    );
  }
}

class AssociatedTitleContainer extends StatelessWidget {
  const AssociatedTitleContainer({
    Key? key,
    required this.title,
    required this.setTitle,
  }) : super(key: key);

  final TransactionAssociatedTitle title;
  final Function(String) setTitle;

  @override
  Widget build(BuildContext context) {
    String titleName = title.title;
    Color backgroundColor = appStateSettings["materialYou"]
        ? dynamicPastel(
            context, Theme.of(context).colorScheme.secondaryContainer,
            amountLight: 0, amountDark: 0.6)
        : getColor(context, "lightDarkAccent");

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8.0),
      child: Tappable(
        onTap: () {
          openBottomSheet(
            context,
            popupWithKeyboard: true,
            PopupFramework(
              title: "set-title".tr(),
              child: SelectText(
                buttonLabel: "set-title".tr(),
                setSelectedText: (text) {
                  titleName = text;
                  setTitle(text);
                },
                labelText: "set-title".tr(),
                selectedText: titleName,
                placeholder: "title-placeholder".tr(),
              ),
            ),
          );
        },
        borderRadius: 15,
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 25, vertical: 15),
                child: TextFont(
                  text: title.title,
                  fontSize: 16.5,
                ),
              ),
            ),
            Tappable(
              onTap: () async {
                deleteAssociatedTitlePopup(
                  context,
                  title: title,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                );
              },
              borderRadius: 15,
              color: backgroundColor,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.close_outlined
                      : Icons.close_rounded,
                  size: 25,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class IncomeTypeButton extends StatelessWidget {
//   const IncomeTypeButton(
//       {Key? key, required this.onTap, required this.selectedIncome})
//       : super(key: key);
//   final VoidCallback onTap;
//   final bool selectedIncome;
//   @override
//   Widget build(BuildContext context) {
//     return Tappable(
//       onTap: onTap,
//       borderRadius: 10,
//       child: Padding(
//         padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 6),
//         child: Row(
//           children: [
//             ButtonIcon(
//               onTap: onTap,
//               icon: selectedIncome
//                   ? appStateSettings["outlinedIcons"] ? Icons.exit_to_app_outlined : Icons.exit_to_app_rounded
//                   : appStateSettings["outlinedIcons"] ? Icons.logout_outlined : Icons.logout_rounded,
//               size: 41,
//             ),
//             SizedBox(width: 15),
//             Expanded(
//               child: TextFont(
//                 text: selectedIncome == false ? "expense".tr() : "income".tr(),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 26,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SelectIsSubcategory extends StatelessWidget {
  const SelectIsSubcategory(
      {required this.isMainCategoryWhenCreating,
      required this.onTap,
      required this.setMainCategoryPkForSubcategoryWhenCreating,
      super.key});
  final bool isMainCategoryWhenCreating;
  final Function(bool isMainCategoryWhenCreating) onTap;
  final Function(String mainCategoryPkForSubcategoryWhenCreating)
      setMainCategoryPkForSubcategoryWhenCreating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  filled: isMainCategoryWhenCreating,
                  alignStart: true,
                  alignBeside: true,
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 20, vertical: 20),
                  text: "main-category".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.category_outlined
                      : Icons.category_rounded,
                  onTap: () {
                    onTap(true);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  filled: !isMainCategoryWhenCreating,
                  transitionWhenFilled: false,
                  alignStart: true,
                  alignBeside: true,
                  padding:
                      EdgeInsetsDirectional.only(start: 20, end: 12, top: 15),
                  text: "subcategory".tr(),
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.move_to_inbox_outlined
                      : Icons.move_to_inbox_rounded,
                  infoButton: IconButtonScaled(
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.info_outlined
                        : Icons.info_outline_rounded,
                    iconSize: 16,
                    scale: 1.6,
                    onTap: () {
                      openBottomSheet(
                        context,
                        SampleSubcategoriesPopup(),
                      );
                    },
                  ),
                  onTap: () {
                    onTap(false);
                  },
                  afterWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 1),
                        child: ClipRRect(
                          child: SelectCategory(
                            horizontalList: true,
                            listPadding:
                                EdgeInsetsDirectional.symmetric(horizontal: 10),
                            addButton: false,
                            setSelectedCategory: (category) {
                              setMainCategoryPkForSubcategoryWhenCreating(
                                  category.categoryPk);
                              onTap(false);
                            },
                            popRoute: false,
                          ),
                        ),
                      )
                    ],
                  ),
                  afterWidgetPadding: EdgeInsetsDirectional.only(bottom: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SampleSubcategoriesPopup extends StatelessWidget {
  const SampleSubcategoriesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "subcategories".tr(),
      subtitle: "subcategories-description".tr(),
      child: Column(
        children: [
          TextFont(
            text: "examples".tr(),
            fontSize: 16,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "coffee.png",
                    categoryName: "drinks".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "coffee-cup.png",
                        categoryName: "coffee".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bubble-tea.png",
                        categoryName: "bubble-tea".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "orange-juice.png",
                        categoryName: "soda".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "theatre.png",
                    categoryName: "entertainment".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "popcorn.png",
                        categoryName: "movies".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "music.png",
                        categoryName: "music".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bowling.png",
                        categoryName: "activities".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "car.png",
                    categoryName: "car".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "gas-station.png",
                        categoryName: "gas".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "gears.png",
                        categoryName: "maintenance".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "bill.png",
                        categoryName: "insurance".tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          OutlinedContainer(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10, vertical: 3),
              child: Column(
                children: [
                  FakeCategoryEntryPlaceholder(
                    iconName: "flower.png",
                    categoryName: "beauty".tr(),
                    showAsSubcategory: false,
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FakeCategoryEntryPlaceholder(
                        iconName: "barber.png",
                        categoryName: "haircut".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "makeup(1).png",
                        categoryName: "touchups".tr(),
                      ),
                      FakeCategoryEntryPlaceholder(
                        iconName: "tshirt.png",
                        categoryName: "clothing".tr(),
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
  }
}

class FakeCategoryEntryPlaceholder extends StatelessWidget {
  const FakeCategoryEntryPlaceholder({
    required this.iconName,
    required this.categoryName,
    this.showAsSubcategory = true,
    super.key,
  });

  final String iconName;
  final String categoryName;
  final bool showAsSubcategory;

  @override
  Widget build(BuildContext context) {
    Widget categoryIcon = CategoryIcon(
      categoryPk: "-1",
      noBackground: true,
      category: TransactionCategory(
        categoryPk: "-1",
        name: "",
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        order: 0,
        income: false,
        iconName: iconName,
        colour: toHexString(Colors.red),
        emojiIconName: null,
      ),
      size: 40,
      sizePadding: showAsSubcategory ? 0 : 20,
      canEditByLongPress: false,
    );
    if (showAsSubcategory) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: 10,
          start: 5,
          end: 5,
        ),
        child: Tappable(
          color:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
          borderRadius: 10,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: Column(
              children: [
                categoryIcon,
                TextFont(
                  text: categoryName,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        categoryIcon,
        TextFont(
          text: categoryName,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ],
    );
  }
}

class IconPreview extends StatelessWidget {
  const IconPreview({
    required this.selectedImage,
    required this.selectedEmoji,
    required this.selectedColor,
    this.smallPreview = false,
    this.switcherDuration = const Duration(milliseconds: 300),
    super.key,
  });
  final String? selectedImage;
  final String? selectedEmoji;
  final Color? selectedColor;
  final bool smallPreview;
  final Duration switcherDuration;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: smallPreview ? 80 : 126,
      padding: smallPreview
          ? null
          : const EdgeInsetsDirectional.only(start: 13, end: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: switcherDuration,
            child: CategoryIcon(
              key: ValueKey((selectedImage ?? "") +
                  (selectedEmoji ?? "") +
                  selectedColor.toString()),
              categoryPk: "-1",
              category: TransactionCategory(
                categoryPk: "-1",
                name: "",
                dateCreated: DateTime.now(),
                dateTimeModified: null,
                order: 0,
                income: false,
                iconName: selectedImage,
                colour: toHexString(selectedColor),
                emojiIconName: selectedEmoji,
              ),
              size: smallPreview ? 35 : 50,
              sizePadding: smallPreview ? 25 : 30,
              canEditByLongPress: false,
            ),
          ),
        ],
      ),
    );
  }
}
