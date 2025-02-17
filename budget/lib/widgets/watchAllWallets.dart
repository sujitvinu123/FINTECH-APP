import 'dart:async';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Provider.of<AllWallets>(context).list
// Provider.of<AllWallets>(context).indexedByPk

// Examples: Get the current selected wallets decimals
// Provider.of<AllWallets>(context).indexedByPk[appStateSettings["selectedWalletPk"]]?.decimals

class WatchAllWallets extends StatelessWidget {
  const WatchAllWallets({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamProvider<AllWallets>.value(
      initialData: AllWallets(list: [], indexedByPk: {}),
      value: database.watchAllWalletsIndexed(),
      child: child,
    );
  }
}

final selectedWalletPkController = StreamController<SelectedWalletPk>();

class WatchSelectedWalletPk extends StatelessWidget {
  const WatchSelectedWalletPk({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamProvider<SelectedWalletPk>.value(
      initialData: SelectedWalletPk(
          selectedWalletPk: appStateSettings["selectedWalletPk"] ?? "0"),
      value: selectedWalletPkController.stream,
      child: child,
    );
  }
}
