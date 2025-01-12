import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onNavigationChanged;

  const BottomNavBar(
      {Key? key,
      required this.selectedIndex,
      required this.onNavigationChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      elevation: 4.0,
      onDestinationSelected: onNavigationChanged,
      selectedIndex: selectedIndex,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.description_outlined),
          selectedIcon: Icon(
            Icons.description,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context).bottomNavDocumentsPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(
            Icons.document_scanner,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context).bottomNavScannerPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.sell_outlined),
          selectedIcon: Icon(
            Icons.sell,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context).bottomNavLabelsPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inbox_outlined),
          selectedIcon: Icon(
            Icons.inbox,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context).bottomNavInboxPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context).appDrawerSettingsLabel,
        ),
      ],
    );
  }
}
