import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/string_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../auth/providers/auth_notifier.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _smsAlerts = false;
  bool _emailDigest = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final isLoading = authState.isLoading;
    final displayName = user?.displayName ?? 'Shipper';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHorizontal,
        ),
        children: [
          const SizedBox(height: 20),
          // Profile card — h=70
          _ProfileCard(
            name: displayName,
            initials: displayName.initials,
            company: 'LODBOD Logistics',
            role: 'Admin',
          ),
          const SizedBox(height: 30),

          // ACCOUNT section — h=95
          _SectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                label: 'Personal information',
                onTap: () {},
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.business_outlined,
                label: 'Company details',
                onTap: () {},
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change password',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PREFERENCES section — h=132
          _SectionLabel('PREFERENCES'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              const _TileDivider(),
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Push notifications',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              const _TileDivider(),
              _SwitchTile(
                icon: Icons.sms_outlined,
                label: 'SMS alerts',
                value: _smsAlerts,
                onChanged: (v) => setState(() => _smsAlerts = v),
              ),
              const _TileDivider(),
              _SwitchTile(
                icon: Icons.email_outlined,
                label: 'Email digest',
                value: _emailDigest,
                onChanged: (v) => setState(() => _emailDigest = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SUPPORT & FEEDBACK — h=63
          _SectionLabel('SUPPORT & FEEDBACK'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                label: 'Help centre',
                onTap: () {},
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                label: 'Send feedback',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // LEGAL & SECURITY — h=63
          _SectionLabel('LEGAL & SECURITY'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                label: 'Terms of service',
                onTap: () {},
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sign out + Delete account — side-by-side
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed:
                        isLoading ? null : () => _confirmSignOut(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(AppStrings.logout),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      textStyle: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Delete account'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
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

// ─── Profile Card ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.initials,
    required this.company,
    required this.role,
  });

  final String name;
  final String initials;
  final String company;
  final String role;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$company • $role',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
      ),
    );
  }
}

// ─── Settings Card (grouped) ────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─── Tiles ───────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
            ),
            SizedBox(
              height: 24,
              child: FittedBox(
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 46),
      child: Divider(height: 1),
    );
  }
}
