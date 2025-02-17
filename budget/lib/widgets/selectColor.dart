import 'dart:math';

import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/colorPicker.dart';
import 'package:budget/widgets/linearGradientFadedEdges.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/util/checkWidgetLaunch.dart';
import 'package:budget/widgets/util/keepAliveClientMixin.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:flutter/services.dart';
import 'package:gradient_borders/gradient_borders.dart';

class SelectColor extends StatefulWidget {
  SelectColor({
    Key? key,
    this.setSelectedColor,
    this.selectedColor,
    this.next,
    this.horizontalList = false,
    this.supportCustomColors = true,
    this.includeThemeColor = true, // Will return null if theme color is chosen
    this.useSystemColorPrompt =
        false, // Will show the option to use the system color (horizontalList must be disabled)
    this.selectableColorsList,
    this.previewBuilder,
  }) : super(key: key);
  final Function(Color?)? setSelectedColor;
  final Color? selectedColor;
  final VoidCallback? next;
  final bool horizontalList;
  final bool supportCustomColors;
  final bool includeThemeColor;
  final bool? useSystemColorPrompt;
  final List<Color>? selectableColorsList;
  final Widget Function(Color color)? previewBuilder;

  @override
  _SelectColorState createState() => _SelectColorState();
}

class _SelectColorState extends State<SelectColor> {
  Color? selectedColor;
  int? selectedIndex;
  bool useSystemColor = appStateSettings["accentSystemColor"];
  List<Color> selectableColorsList = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      selectableColorsList =
          widget.selectableColorsList ?? selectableColors(context);
      if (widget.supportCustomColors) {
        selectableColorsList.add(Colors.transparent);
      }
      if (widget.includeThemeColor) {
        selectableColorsList.insert(0, Colors.transparent);
      }

      if (widget.selectedColor != null) {
        int index = 0;
        for (Color color in selectableColorsList) {
          if (color.toString() == widget.selectedColor.toString()) {
            setState(() {
              selectedIndex = index;
              selectedColor = widget.selectedColor;
            });
            return;
          }
          index++;
        }
        print("color not found - must be custom color");
        selectedIndex = -1;
        selectedColor = widget.selectedColor;
      } else {
        selectedIndex = 0;
        selectedColor = null;
      }
      setState(() {});
    });
  }

  //find the selected category using selectedCategory
  @override
  Widget build(BuildContext context) {
    if (widget.horizontalList) {
      return LinearGradientFadedEdges(
        enableTop: false,
        enableBottom: false,
        enableStart: getHorizontalPaddingConstrained(context) > 0,
        enableEnd: getHorizontalPaddingConstrained(context) > 0,
        child: ClipRRect(
          child: ListView.builder(
            addAutomaticKeepAlives: true,
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: selectableColorsList.length,
            itemBuilder: (context, index) {
              Color color;
              // Custom color as the last color
              color = selectableColorsList[index];
              return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: index == 0 ? 12 : 0,
                    end: index + 1 == selectableColorsList.length ? 12 : 0),
                child: widget.includeThemeColor && index == 0
                    ? ThemeColorIcon(
                        outline: selectedIndex == 0 && selectedColor == null,
                        margin: EdgeInsetsDirectional.all(5),
                        size: 55,
                        onTap: () {
                          widget.setSelectedColor!(null);
                          setState(() {
                            selectedColor = null;
                            selectedIndex = index;
                          });
                        },
                      )
                    : widget.supportCustomColors &&
                            index + 1 == selectableColorsList.length
                        ? KeepAliveClientMixin(
                            child: ColorIconCustom(
                              previewBuilder: widget.previewBuilder,
                              initialSelectedColor: selectedColor ??
                                  Theme.of(context).colorScheme.primary,
                              outline: selectedIndex == -1 ||
                                  selectedIndex ==
                                      selectableColorsList.length - 1,
                              margin: EdgeInsetsDirectional.all(5),
                              size: 55,
                              onTap: (colorPassed) {
                                widget.setSelectedColor!(colorPassed);
                                setState(() {
                                  selectedColor = color;
                                  selectedIndex = index;
                                });
                              },
                            ),
                          )
                        : ColorIcon(
                            margin: EdgeInsetsDirectional.all(5),
                            color: (widget.supportCustomColors &&
                                    index + 1 == selectableColorsList.length)
                                ? (selectedColor ?? Colors.transparent)
                                : color,
                            size: 55,
                            onTap: () {
                              if (widget.setSelectedColor != null) {
                                widget.setSelectedColor!(color);
                                setState(() {
                                  selectedColor = color;
                                  selectedIndex = index;
                                });
                                Future.delayed(Duration(milliseconds: 70), () {
                                  if (widget.next != null) {
                                    widget.next!();
                                  }
                                });
                              }
                            },
                            outline: (selectedIndex != null &&
                                    selectedIndex ==
                                        selectableColorsList.length - 1 &&
                                    index == selectedIndex) ||
                                selectedColor.toString() == color.toString(),
                          ),
              );
            },
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8.0),
      child: Column(
        children: [
          widget.useSystemColorPrompt == true && supportsSystemColor()
              ? SettingsContainerSwitch(
                  enableBorderRadius: true,
                  title: "use-system-color".tr(),
                  onSwitched: (value) async {
                    await updateSettings("accentSystemColor", value,
                        updateGlobalState: true);
                    if (value == true) {
                      // Need to set "accentSystemColor" to true before getAccentColorSystemString
                      await updateSettings(
                          "accentColor", await getAccentColorSystemString(),
                          updateGlobalState: true);
                      updateWidgetColorsAndText(context);
                    } else {
                      widget.setSelectedColor!(selectedColor);
                    }
                    setState(() {
                      useSystemColor = value;
                    });
                  },
                  initialValue: useSystemColor,
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.devices_outlined
                      : Icons.devices_rounded,
                )
              : SizedBox.shrink(),
          AnimatedOpacity(
            duration: Duration(milliseconds: 400),
            opacity:
                widget.useSystemColorPrompt == true && useSystemColor == false
                    ? 1
                    : 0.5,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: selectableColorsList
                    .asMap()
                    .map(
                      (index, color) => MapEntry(
                        index,
                        widget.supportCustomColors &&
                                index + 1 == selectableColorsList.length
                            ? KeepAliveClientMixin(
                                child: ColorIconCustom(
                                  previewBuilder: widget.previewBuilder,
                                  initialSelectedColor: selectedColor ??
                                      Theme.of(context).colorScheme.primary,
                                  margin: EdgeInsetsDirectional.all(5),
                                  size: 55,
                                  onTap: (colorPassed) {
                                    widget.setSelectedColor!(colorPassed);
                                    setState(() {
                                      selectedColor = color;
                                      selectedIndex = index;
                                    });
                                    Future.delayed(Duration(milliseconds: 70),
                                        () {
                                      popRoute(context);
                                      if (widget.next != null) {
                                        widget.next!();
                                      }
                                    });
                                  },
                                  outline: selectedIndex == -1 ||
                                      selectedIndex ==
                                          selectableColorsList.length - 1,
                                ),
                              )
                            : ColorIcon(
                                margin: EdgeInsetsDirectional.all(5),
                                color: color,
                                size: 55,
                                onTap: () {
                                  if (widget.setSelectedColor != null) {
                                    widget.setSelectedColor!(color);
                                    setState(() {
                                      selectedColor = color;
                                    });
                                    Future.delayed(Duration(milliseconds: 70),
                                        () {
                                      popRoute(context);
                                      if (widget.next != null) {
                                        widget.next!();
                                      }
                                    });
                                  }
                                },
                                outline: selectedColor.toString() ==
                                    color.toString(),
                              ),
                      ),
                    )
                    .values
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorIcon extends StatelessWidget {
  ColorIcon({
    Key? key,
    required this.color,
    required this.size,
    this.onTap,
    this.margin,
    this.outline = false,
  }) : super(key: key);

  final Color color;
  final double size;
  final VoidCallback? onTap;
  final EdgeInsetsDirectional? margin;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      margin: margin ??
          EdgeInsetsDirectional.only(start: 8, end: 8, top: 8, bottom: 8),
      height: size,
      width: size,
      decoration: outline
          ? BoxDecoration(
              border: Border.all(
                color: dynamicPastel(context, color,
                    amountLight: 0.5, amountDark: 0.4, inverse: true),
                width: 3,
              ),
              borderRadius: BorderRadiusDirectional.all(Radius.circular(500)),
            )
          : BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
              borderRadius: BorderRadiusDirectional.all(Radius.circular(500)),
            ),
      child: Tappable(
        color: color,
        onTap: onTap,
        borderRadius: 500,
        child: Container(),
      ),
    );
  }
}

class ThemeColorIcon extends StatelessWidget {
  const ThemeColorIcon({
    Key? key,
    required this.size,
    required this.onTap,
    this.margin,
    required this.outline,
  }) : super(key: key);

  final double size;
  final Function()? onTap;
  final EdgeInsetsDirectional? margin;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "theme-color".tr(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        margin: margin ??
            EdgeInsetsDirectional.only(start: 8, end: 8, top: 8, bottom: 8),
        height: size,
        width: size,
        decoration: outline
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: dynamicPastel(
                      context, Theme.of(context).colorScheme.primary,
                      amountLight: 0.5, amountDark: 0.4, inverse: true),
                  width: 3,
                ),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
        child: Tappable(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
          onTap: onTap,
          borderRadius: 500,
          child: Icon(
            appStateSettings["outlinedIcons"]
                ? Icons.color_lens_outlined
                : Icons.color_lens_rounded,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class ColorIconCustom extends StatefulWidget {
  ColorIconCustom({
    Key? key,
    required this.size,
    required this.onTap,
    this.margin,
    required this.outline,
    required this.initialSelectedColor,
    this.previewBuilder,
  }) : super(key: key);

  final double size;
  final Function(Color) onTap;
  final EdgeInsetsDirectional? margin;
  final bool outline;
  final Color initialSelectedColor;
  final Widget Function(Color color)? previewBuilder;

  @override
  State<ColorIconCustom> createState() => _ColorIconCustomState();
}

class _ColorIconCustomState extends State<ColorIconCustom> {
  late Color selectedColor = widget.initialSelectedColor;
  double? colorSliderPosition;
  double? shadeSliderPosition;

  @override
  Widget build(BuildContext context) {
    Widget colorPickerPopup = PopupFramework(
      title: "custom-color".tr(),
      outsideExtraWidget: OutsideExtraWidgetIconButton(
          iconData: appStateSettings["outlinedIcons"]
              ? Icons.numbers_outlined
              : Icons.numbers_rounded,
          onPressed: () async {
            enterColorCodeBottomSheet(
              context,
              initialSelectedColor: selectedColor,
              setSelectedColor: (Color color) {
                widget.onTap(color);
                selectedColor = color;
              },
            );
          }),
      child: Column(
        children: [
          // Center(
          //   child: ColorPicker(
          //     initialColor: widget.initialSelectedColor,
          //     colorSliderPosition: colorSliderPosition,
          //     shadeSliderPosition: shadeSliderPosition,
          //     ringColor: getColor(context, "black"),
          //     ringSize: 10,
          //     width: getWidthBottomSheet(context) - 100,
          //     onChange: (color, colorSliderPositionPassed,
          //         shadeSliderPositionPassed) {
          //       setState(() {
          //         // only set selected color after a slider change, we want to keep the
          //         // value of widget.initialSelectedColor for the hex picker
          //         selectedColor = color;
          //         colorSliderPosition = colorSliderPositionPassed;
          //         shadeSliderPosition = shadeSliderPositionPassed;
          //       });
          //     },
          //   ),
          // ),
          RingColorPicker(
            onColorChanged: (value) => selectedColor = value,
            pickerColor: selectedColor,
            hueRingStrokeWidth: 15,
            colorPickerHeight: min(225, getWidthBottomSheet(context) - 100),
            onSelect: () {
              popRoute(context);
              widget.onTap(selectedColor);
            },
            previewBuilder: widget.previewBuilder,
          ),
          SizedBox(
            height: 8,
          ),
          Button(
            label: "select".tr(),
            onTap: () {
              popRoute(context);
              widget.onTap(selectedColor);
            },
          )
        ],
      ),
    );
    return Tooltip(
      message: "custom-color".tr(),
      child: LockedFeature(
        actionAfter: () async {
          await openBottomSheet(context, colorPickerPopup);
        },
        child: Container(
          margin: widget.margin ??
              EdgeInsetsDirectional.only(start: 8, end: 8, top: 8, bottom: 8),
          height: widget.size,
          width: widget.size,
          decoration: widget.outline
              ? BoxDecoration(
                  border: Border.all(
                    color: dynamicPastel(context, selectedColor,
                        amountLight: 0.5, amountDark: 0.4, inverse: true),
                    width: 3,
                  ),
                  borderRadius:
                      BorderRadiusDirectional.all(Radius.circular(500)),
                )
              : BoxDecoration(
                  border: GradientBoxBorder(
                    gradient: LinearGradient(colors: [
                      Colors.red.withOpacity(0.8),
                      Colors.yellow.withOpacity(0.8),
                      Colors.green.withOpacity(0.8),
                      Colors.blue.withOpacity(0.8),
                      Colors.purple.withOpacity(0.8),
                    ]),
                    width: 3,
                  ),
                  borderRadius: BorderRadiusDirectional.circular(500),
                ),
          child: Tappable(
            color: Colors.transparent,
            onTap: () async {
              await openBottomSheet(context, colorPickerPopup);
            },
            borderRadius: 500,
            child: Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.colorize_outlined
                  : Icons.colorize_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

Future enterColorCodeBottomSheet(
  context, {
  required Color initialSelectedColor,
  required Function(Color) setSelectedColor,
}) async {
  popRoute(context);
  return await openBottomSheet(
    context,
    popupWithKeyboard: true,
    PopupFramework(
      title: "enter-color-code".tr(),
      child: HexColorPicker(
        initialSelectedColor: initialSelectedColor,
        setSelectedColor: setSelectedColor,
      ),
    ),
  );
}

class HexColorPicker extends StatefulWidget {
  const HexColorPicker({
    super.key,
    required this.initialSelectedColor,
    required this.setSelectedColor,
  });
  final Color initialSelectedColor;
  final Function(Color) setSelectedColor;

  @override
  State<HexColorPicker> createState() => _HexColorPickerState();
}

class _HexColorPickerState extends State<HexColorPicker> {
  late Color selectedColor = widget.initialSelectedColor;

  setColor(String input) {
    if (input.length == 8) {
      Color color = HexColor("0xFF" + input.replaceAll("0x", ""),
          defaultColor: widget.initialSelectedColor);

      setState(() {
        selectedColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectText(
      buttonLabel: "set-color".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.color_lens_outlined
          : Icons.color_lens_rounded,
      setSelectedText: setColor,
      nextWithInput: (String input) {
        setColor(input);
        widget.setSelectedColor(selectedColor);
      },
      selectedText: toHexString(widget.initialSelectedColor)
          .toString()
          .allCaps
          .replaceAll("0XFF", "0x"),
      placeholder: toHexString(widget.initialSelectedColor)
          .toString()
          .allCaps
          .replaceAll("0XFF", "0x"),
      autoFocus: true,
      inputFormatters: [ColorCodeFormatter()],
      widgetBeside: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selectedColor,
          ),
        ),
      ),
    );
  }
}

class ColorCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Validate and format the input value
    String formattedText = _formatColorCode(newValue.text);
    if (oldValue.text == "0x" && newValue.text == "0") {
      formattedText = "";
    }
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText == _formatColorCode(oldValue.text)
            ? oldValue.selection.baseOffset
            : newValue.selection.baseOffset,
      ),
    );
  }

  String _formatColorCode(String input) {
    String cleanedInput = input;
    if (cleanedInput == "0") return "0x";
    // Remove any non-hexadecimal characters
    cleanedInput = cleanedInput
        .replaceAll("0x", "")
        .allCaps
        .replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
    cleanedInput = "0x" + cleanedInput;

    if (cleanedInput.length > 8) {
      cleanedInput = cleanedInput.substring(0, 8);
    }

    return cleanedInput;
  }
}
