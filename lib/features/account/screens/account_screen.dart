import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/string_ext.dart';
import '../../auth/providers/auth_notifier.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final isLoading = authState.isLoading;
    final displayName = user?.displayName ?? 'Shipper';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenHorizontal),
        children: [
          const SizedBox(height: AppSizes.md),
          Center(
            child: CircleAvatar(
              radius: AppSizes.avatarLg / 2 + AppSizes.sm,
              backgroundColor: AppColors.primary,
              child: Text(
                displayName.initials,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (user != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          const Divider(),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Account type',
            value: 'Shipper',
          ),
          _InfoTile(
            icon: Icons.info_outline,
            label: 'App version',
            value: '1.0.0',
          ),
          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to manage shipments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.logout),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
