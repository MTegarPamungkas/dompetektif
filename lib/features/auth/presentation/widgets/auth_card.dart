import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.state,
    required this.formKey,
    required this.signUp,
    required this.obscure,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final AuthState state;
  final GlobalKey<FormState> formKey;
  final bool signUp;
  final bool obscure;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = state.submitting;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: context.dompet.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.dompet.line),
        boxShadow: [
          BoxShadow(
            color: context.dompet.shadow.withValues(alpha: 0.3),
            blurRadius: 44,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.dompet.accentSoft,
                      borderRadius: AppRadius.allMd,
                    ),
                    child: Icon(
                      signUp
                          ? Icons.person_add_alt_1_rounded
                          : Icons.badge_outlined,
                      color: context.dompet.accent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signUp ? l10n.signUp : l10n.signIn,
                          style: context.texts.headlineSmall?.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          signUp ? l10n.createAccountNow : l10n.welcomeBack,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.dompet.inkMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: state.isDemo ? l10n.demoMode : l10n.cloudMode,
                    tone: state.isDemo ? PillTone.accent : PillTone.success,
                    icon: state.isDemo
                        ? Icons.science_outlined
                        : Icons.cloud_done_outlined,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (signUp) ...[
                AppTextField(
                  controller: nameController,
                  label: l10n.displayName,
                  hint: l10n.demoUser,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    size: 19,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return l10n.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 13),
              ],
              AppTextField(
                controller: emailController,
                label: l10n.email,
                hint: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                autofillHints: const [AutofillHints.email],
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              AppTextField(
                controller: passwordController,
                label: l10n.password,
                hint: l10n.passwordHint,
                obscure: obscure,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                autofillHints: signUp
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                prefixIcon: const Icon(Icons.key_rounded, size: 19),
                suffix: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) return l10n.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: busy ? null : onSubmit,
                  child: busy
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(signUp ? l10n.createAccountNow : l10n.signInNow),
                ),
              ),
              if (state.isDemo) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.read<AuthBloc>().continueAsDemo(),
                  icon: const Icon(Icons.science_outlined, size: 17),
                  label: Text(l10n.continueAsDemo),
                ),
              ] else if (state.isConfigured) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(l10n.or, style: context.texts.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.read<AuthBloc>().signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                  label: Text(l10n.continueWithGoogle),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    signUp ? l10n.haveAccount : l10n.noAccount,
                    style: context.texts.bodySmall,
                  ),
                  TextButton(
                    onPressed: busy ? null : onToggleMode,
                    child: Text(signUp ? l10n.signIn : l10n.signUp),
                  ),
                ],
              ),
              if (state.isDemo) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: context.dompet.accentSoft.withValues(alpha: 0.55),
                    borderRadius: AppRadius.allMd,
                    border: Border.all(
                      color: context.dompet.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: context.dompet.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.demoWarning,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 10,
                            color: context.dompet.inkMuted,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
