import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addAssociatedTitlePage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/modified/reorderable_list.dart';

class EditAssociatedTitlesPage extends StatefulWidget {
  EditAssociatedTitlesPage({
    Key? key,
  }) : super(key: key);

  @override
  _EditAssociatedTitlesPageState createState() =>
      _EditAssociatedTitlesPageState();
}

class _EditAssociatedTitlesPageState extends State<EditAssociatedTitlesPage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;
  String searchValue = "";
  bool isFocused = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      await database.fixDuplicateAssociatedTitles();
      await database.fixOrderAssociatedTitles();
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
        title: "edit-titles".tr(),
        scrollToTopButton: true,
        floatingActionButton: AnimateFABDelayed(
          fab: AddFAB(
            tooltip: "add-title".tr(),
            onTap: () {
              openBottomSheet(
                context,
                popupWithKeyboard: true,
                AddAssociatedTitlePage(),
              );
            },
          ),
        ),
        actions: [
          CustomPopupMenuButton(
            showButtons: true,
            keepOutFirst: true,
            items: [
              DropdownItemMenu(
                id: "add-title",
                label: "add-title".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.add_outlined
                    : Icons.add_rounded,
                action: () {
                  openBottomSheet(
                    context,
                    popupWithKeyboard: true,
                    AddAssociatedTitlePage(),
                  );
                },
              ),
              DropdownItemMenu(
                id: "settings",
                label: "settings".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.more_vert_outlined
                    : Icons.more_vert_rounded,
                action: () => openBottomSheet(
                  context,
                  PopupFramework(
                    hasPadding: false,
                    child: TitlesSettings(),
                  ),
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
                  labelText: "search-titles-placeholder".tr(),
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
          //     child: TitlesSettings(),
          //   ),
          // ),
          StreamBuilder<List<TransactionAssociatedTitleWithCategory>>(
            stream: database.watchAllAssociatedTitles(
                searchFor: searchValue == "" ? null : searchValue),
            builder: (context, snapshot) {
              List<TransactionAssociatedTitleWithCategory> titles =
                  snapshot.data ?? [];
              // print(snapshot.data);
              if (snapshot.hasData && titles.length <= 0) {
                return SliverToBoxAdapter(
                  child: NoResults(
                    message: "no-titles-found".tr(),
                  ),
                );
              }
              if (snapshot.hasData && titles.length > 0) {
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
                    TransactionAssociatedTitle associatedTitle =
                        titles[index].title;
                    VoidCallback onTap = () {
                      openBottomSheet(
                        context,
                        popupWithKeyboard: true,
                        AddAssociatedTitlePage(
                          associatedTitle: associatedTitle,
                        ),
                      );
                    };
                    return EditRowEntry(
                      canReorder: searchValue == "" &&
                          (snapshot.data ?? []).length != 1,
                      onTap: onTap,
                      padding: EdgeInsetsDirectional.symmetric(
                          vertical: 7,
                          horizontal:
                              getPlatform() == PlatformOS.isIOS ? 17 : 7),
                      currentReorder:
                          currentReorder != -1 && currentReorder != index,
                      index: index,
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 3),
                          CategoryIcon(
                            categoryPk: associatedTitle.categoryFk,
                            size: 25,
                            margin: EdgeInsetsDirectional.zero,
                            sizePadding: 20,
                            borderRadius: 1000,
                            category: titles[index].category,
                            onTap: onTap,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: TextFont(
                              text: associatedTitle.title
                              // +
                              //     " - " +
                              //     associatedTitle.order.toString()
                              ,
                              fontSize: 16,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      onDelete: () async {
                        return (await deleteAssociatedTitlePopup(
                              context,
                              title: associatedTitle,
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.None,
                            )) ==
                            DeletePopupAction.Delete;
                      },
                      openPage: Container(),
                      key: ValueKey(associatedTitle.associatedTitlePk),
                    );
                  },
                  itemCount: snapshot.data!.length,
                  onReorder: (_intPrevious, _intNew) async {
                    TransactionAssociatedTitle oldTitle =
                        titles[_intPrevious].title;
                    _intNew = snapshot.data!.length - _intNew;
                    _intPrevious = snapshot.data!.length - _intPrevious;
                    if (_intNew > _intPrevious) {
                      await database.moveAssociatedTitle(
                          oldTitle.associatedTitlePk,
                          _intNew - 1,
                          oldTitle.order);
                    } else {
                      await database.moveAssociatedTitle(
                          oldTitle.associatedTitlePk, _intNew, oldTitle.order);
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
            child: SizedBox(height: 85),
          ),
        ],
      ),
    );
  }
}

Future<DeletePopupAction?> deleteAssociatedTitlePopup(
  BuildContext context, {
  required TransactionAssociatedTitle title,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-title-question".tr(),
    subtitle: title.title,
  );
  if (action == DeletePopupAction.Delete) {
    if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
      popAllRoutes(context);
    } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
      popRoute(context);
    }
    openLoadingPopupTryCatch(() async {
      await database.deleteAssociatedTitle(
          title.associatedTitlePk, title.order);
      openSnackbar(
        SnackbarMessage(
          title: "deleted-title".tr(),
          icon: Icons.delete,
          description: title.title,
        ),
      );
    });
  }
  return action;
}

class AutoTitlesToggle extends StatelessWidget {
  const AutoTitlesToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "auto-add-titles".tr(),
      description: "auto-add-titles-description".tr(),
      onSwitched: (value) {
        updateSettings("autoAddAssociatedTitles", value,
            pagesNeedingRefresh: [], updateGlobalState: false);
      },
      initialValue: appStateSettings["autoAddAssociatedTitles"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.add_box_outlined
          : Icons.add_box_rounded,
    );
  }
}

class AskForTitlesToggle extends StatefulWidget {
  const AskForTitlesToggle({super.key});

  @override
  State<AskForTitlesToggle> createState() => _AskForTitlesToggleState();
}

class _AskForTitlesToggleState extends State<AskForTitlesToggle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainerSwitch(
          title: "ask-for-transaction-title".tr(),
          description: "ask-for-transaction-title-description".tr(),
          onSwitched: (value) {
            updateSettings(
              "askForTransactionTitle",
              value,
              updateGlobalState: false,
            );
            setState(() {});
          },
          initialValue: appStateSettings["askForTransactionTitle"],
          icon: appStateSettings["outlinedIcons"]
              ? Icons.text_fields_outlined
              : Icons.text_fields_rounded,
        ),
        AnimatedExpanded(
          expand: getIsFullScreen(context) == false &&
              appStateSettings["askForTransactionTitle"] == true,
          child: AskForNotesToggle(),
        ),
      ],
    );
  }
}

class AskForNotesToggle extends StatelessWidget {
  const AskForNotesToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "ask-for-notes-with-title".tr(),
      description: "ask-for-notes-with-title-description".tr(),
      onSwitched: (value) {
        updateSettings(
          "askForTransactionNoteWithTitle",
          value,
          updateGlobalState: false,
        );
      },
      initialValue: appStateSettings["askForTransactionNoteWithTitle"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.sticky_note_2_outlined
          : Icons.sticky_note_2_rounded,
    );
  }
}

class TitlesSettings extends StatelessWidget {
  const TitlesSettings({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AskForTitlesToggle(),
        AutoTitlesToggle(),
      ],
    );
  }
}
