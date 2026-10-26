import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/core/widgets/case_mark.dart';
import 'package:dompetektif/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        final l10n = context.l10n;
        final message = switch (failure) {
          AuthFailure.invalidCredentials => l10n.errorInvalidCredentials,
          AuthFailure.emailInUse => l10n.errorEmailInUse,
          AuthFailure.emailNotConfirmed => l10n.errorEmailNotConfirmed,
          AuthFailure.network => l10n.errorNetwork,
          AuthFailure.demoDisabled => l10n.errorDemoDisabled,
          AuthFailure.cloudNotConfigured => l10n.errorCloudNotConfigured,
          AuthFailure.oauthRedirect => l10n.oauthRedirectHint,
          AuthFailure.generic => l10n.errorAuthGeneric,
        };
        showAppSnackBar(
          context,
          message,
          error: failure != AuthFailure.oauthRedirect,
        );
        context.read<AuthCubit>().clearFailure();
      },
      builder: (context, state) {
        final wide =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;
        return Scaffold(
          body: CaseBackground(
            child: SafeArea(
              child: wide
                  ? Row(
                      children: [
                        Expanded(flex: 11, child: _BrandPanel(state: state)),
                        Expanded(
                          flex: 9,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(36),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: _AuthCard(
                                  state: state,
                                  formKey: _formKey,
                                  signUp: _signUp,
                                  obscure: _obscure,
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  onToggleMode: () => setState(() {
                                    _signUp = !_signUp;
                                    _formKey.currentState?.reset();
                                  }),
                                  onToggleObscure: () =>
                                      setState(() => _obscure = !_obscure),
                                  onSubmit: _submit,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _CompactBrand(),
                              const SizedBox(height: 26),
                              _AuthCard(
                                state: state,
                                formKey: _formKey,
                                signUp: _signUp,
                                obscure: _obscure,
                                nameController: _nameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                onToggleMode: () => setState(() {
                                  _signUp = !_signUp;
                                  _formKey.currentState?.reset();
                                }),
                                onToggleObscure: () =>
                                    setState(() => _obscure = !_obscure),
                                onSubmit: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AuthCubit>();
    if (_signUp) {
      cubit.signUpWithEmail(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      cubit.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 38, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CaseMark(size: 46),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOMPETEKTIF',
                    style: context.texts.labelMedium?.copyWith(
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l10n.caseFile,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.dompet.accent,
                      letterSpacing: 3.4,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (state.isDemo)
                StatusPill(
                  label: l10n.demoMode,
                  tone: PillTone.accent,
                  icon: Icons.science_outlined,
                ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.authTitle,
                      style: context.texts.displayLarge?.copyWith(
                        fontSize: 64,
                        height: 0.96,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.tagline,
                      style: context.texts.titleMedium?.copyWith(
                        color: context.dompet.accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        l10n.authSubtitle,
                        style: context.texts.bodyLarge?.copyWith(
                          color: context.dompet.inkMuted,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const _FeatureStrip(),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: context.dompet.inkMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  state.isDemo ? l10n.demoNotice : l10n.reportSourceNote,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: context.dompet.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CaseMark(size: 40),
            const SizedBox(width: 11),
            Text(
              'DOMPETEKTIF',
              style: context.texts.labelMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.authTitle,
          style: context.texts.displaySmall?.copyWith(
            fontSize: 40,
            height: 1,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.tagline,
          style: context.texts.titleSmall?.copyWith(
            color: context.dompet.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authSubtitle,
          style: context.texts.bodyMedium?.copyWith(
            color: context.dompet.inkMuted,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.sync_alt_rounded, l10n.realtime),
      (Icons.cloud_off_outlined, l10n.offlineFirst),
      (Icons.auto_awesome_outlined, l10n.reportAiSource),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.dompet.surface.withValues(alpha: 0.6),
              borderRadius: AppRadius.allPill,
              border: Border.all(color: context.dompet.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 14, color: context.dompet.accent),
                const SizedBox(width: 7),
                Text(
                  item.$2,
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 0.4,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
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
                      : () => context.read<AuthCubit>().continueAsDemo(),
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
                      : () => context.read<AuthCubit>().signInWithGoogle(),
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
