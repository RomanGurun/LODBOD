import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/shared/extensions/string_ext.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = false;
  bool _emailDigest = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final isLoading = authState.isLoading;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHorizontal,
        ),
        children: [
          const SizedBox(height: 20),
          // Profile card — real Firestore/auth identity.
          profileAsync.when(
            loading: () => const _ProfileSkeleton(),
            error: (_, __) => _ProfileCard(
              name: user?.displayName ?? 'Shipper',
              subtitle: user?.email ?? '—',
            ),
            data: (profile) => _ProfileCard(
              name: profile?.name ?? user?.displayName ?? 'Shipper',
              subtitle: profile?.email ?? user?.email ?? '—',
            ),
          ),
          const SizedBox(height: 30),

          // ACCOUNT section
          const _SectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                label: 'Personal information',
                onTap: () =>
                    _showPersonalInfo(context, profileAsync.valueOrNull),
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change password',
                onTap: _changePassword,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PREFERENCES section — local, session-scoped demo preferences.
          const _SectionLabel('PREFERENCES'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Push notifications',
                value: _pushNotifications,
                onChanged: (v) {
                  setState(() => _pushNotifications = v);
                  _prefSavedSnack();
                },
              ),
              const _TileDivider(),
              _SwitchTile(
                icon: Icons.sms_outlined,
                label: 'SMS alerts',
                value: _smsAlerts,
                onChanged: (v) {
                  setState(() => _smsAlerts = v);
                  _prefSavedSnack();
                },
              ),
              const _TileDivider(),
              _SwitchTile(
                icon: Icons.email_outlined,
                label: 'Email digest',
                value: _emailDigest,
                onChanged: (v) {
                  setState(() => _emailDigest = v);
                  _prefSavedSnack();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SUPPORT & FEEDBACK
          const _SectionLabel('SUPPORT & FEEDBACK'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                label: 'Help centre',
                onTap: () => _showPrototypeNote(
                  context,
                  'The help centre is not part of this prototype.',
                ),
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                label: 'Send feedback',
                onTap: () => _showPrototypeNote(
                  context,
                  'Feedback submission is not part of this prototype.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // LEGAL & SECURITY
          const _SectionLabel('LEGAL & SECURITY'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                label: 'Terms of service',
                onTap: () => _showPrototypeNote(
                  context,
                  'Legal documents are not part of this prototype.',
                ),
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                onTap: () => _showPrototypeNote(
                  context,
                  'Legal documents are not part of this prototype.',
                ),
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
                    onPressed: () => _showPrototypeNote(
                      context,
                      'Account deletion is not part of this prototype. '
                      'Contact LODBOD support to remove an account.',
                    ),
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

  void _prefSavedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preference saved for this demo session'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPersonalInfo(BuildContext context, UserProfile? profile) {
    final user = ref.read(authNotifierProvider).valueOrNull;
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : user?.displayName ?? '—';
    final email =
        profile?.email.isNotEmpty == true ? profile!.email : user?.email ?? '—';
    final phone = (profile?.phone ?? '').trim().isNotEmpty
        ? profile!.phone
        : 'Not provided';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal information',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _ProfileInfoRow(label: 'Name', value: name),
              _ProfileInfoRow(label: 'Email', value: email),
              _ProfileInfoRow(label: 'Phone', value: phone),
              const _ProfileInfoRow(label: 'Role', value: 'Shipper'),
              _ProfileInfoRow(
                label: 'Member since',
                value: profile?.createdAt.formatDisplay() ?? '—',
              ),
              _ProfileInfoRow(label: 'Account ID', value: user?.id ?? '—'),
            ],
          ),
        ),
      ),
    );
  }

  /// Real password reset through Firebase Auth's email flow. Demo accounts
  /// are local-only and are rejected honestly.
  Future<void> _changePassword() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    final email = user?.email ?? '';
    final controller = TextEditingController(text: email);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We will send a password reset link to your email address.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: AppStrings.emailOrPhone,
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.genericError)),
      );
    } finally {
      controller.dispose();
    }
  }

  void _showPrototypeNote(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Not available yet'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.gotIt),
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

// ─── Profile Card ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

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
              name.initials,
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
                  '$subtitle • Shipper',
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 180,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
            ),
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
