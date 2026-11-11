import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/core/widgets/data_fallback_banner.dart';
import 'package:lodbod/core/widgets/lodbod_bottom_nav.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dataSourceStatusProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: status.usingFallback,
            builder: (context, usingFallback, child) {
              if (!usingFallback) return const SizedBox.shrink();
              return const DataFallbackBanner();
            },
          ),
          LodbodBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onDestinationSelected,
          ),
        ],
      ),
    );
  }
}
