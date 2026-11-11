import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/validators.dart';
import 'package:lodbod/shared/widgets/app_text_field.dart';
import 'package:lodbod/shared/widgets/state_views.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/widgets/auth_page.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _role = UserProfile.roleShipper;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedForm(UserProfile? profile, String fallbackName) {
    if (_initialized) return;
    _nameController.text =
        profile?.name.trim().isNotEmpty == true ? profile!.name : fallbackName;
    _role = UserProfile.normalizeRole(profile?.role);
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(userProfileProvider.notifier).save(
            fullName: _nameController.text,
            role: _role,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() {
    return ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    if (profileAsync.isLoading && profileAsync.valueOrNull == null) {
      return const AuthPage(
        title: AppStrings.profileSetupTitle,
        subtitle: 'Loading your profile…',
        showLogo: false,
        children: [
          SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (profileAsync.hasError) {
      return AuthPage(
        title: AppStrings.profileSetupTitle,
        subtitle: AppStrings.profileSetupFailed,
        showLogo: false,
        children: [
          ErrorState(
            message: profileAsync.error.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          const SizedBox(height: AppSizes.md),
          TextButton(onPressed: _signOut, child: const Text(AppStrings.logout)),
        ],
      );
    }

    final profile = profileAsync.valueOrNull;
    _seedForm(profile, user?.displayName ?? '');
    final phone = (profile?.phone ?? '').trim().isNotEmpty
        ? profile!.phone
        : user?.phoneNumber ?? '';

    return AuthPage(
      title: AppStrings.profileSetupTitle,
      subtitle: AppStrings.profileSetupSubtitle,
      showLogo: false,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: AppStrings.fullName,
                hint: AppStrings.fullNameHint,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.name],
                validator: Validators.required,
              ),
              const SizedBox(height: 18),
              AppTextField(
                initialValue: phone.isEmpty ? '—' : phone,
                label: AppStrings.verifiedPhone,
                readOnly: true,
                suffixIcon: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.success,
                  size: AppSizes.iconMd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.roleLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                key: const ValueKey<String>('role-shipper'),
                title: AppStrings.roleShipper,
                subtitle: AppStrings.roleShipperHint,
                icon: Icons.inventory_2_outlined,
                selected: _role == UserProfile.roleShipper,
                onTap: () => setState(() => _role = UserProfile.roleShipper),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                key: const ValueKey<String>('role-carrier'),
                title: AppStrings.roleCarrier,
                subtitle: AppStrings.roleCarrierHint,
                icon: Icons.local_shipping_outlined,
                selected: _role == UserProfile.roleCarrier,
                onTap: () => setState(() => _role = UserProfile.roleCarrier),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Text(AppStrings.continueLabel),
        ),
        const SizedBox(height: AppSizes.sm),
        TextButton(onPressed: _signOut, child: const Text(AppStrings.logout)),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.border;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: AppSizes.iconMd,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
