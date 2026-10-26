import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/case_mark.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/auth_brand.dart';
import '../widgets/auth_card.dart';

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
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        final l10n = context.l10n;
        final message = switch (failure) {
          AuthFailure.invalidCredentials => l10n.errorInvalidCredentials,
          AuthFailure.emailInUse => l10n.errorEmailInUse,
          AuthFailure.emailNotConfirmed => l10n.errorEmailNotConfirmed,
          AuthFailure.emailRateLimit => l10n.errorEmailRateLimit,
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
        context.read<AuthBloc>().clearFailure();
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
                        Expanded(flex: 11, child: BrandPanel(state: state)),
                        Expanded(
                          flex: 9,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(36),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: AuthCard(
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
                              const CompactBrand(),
                              const SizedBox(height: 26),
                              AuthCard(
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
    final bloc = context.read<AuthBloc>();
    if (_signUp) {
      bloc.signUpWithEmail(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      bloc.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
}
