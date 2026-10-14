import '../../widgets/character_avatar.dart';
import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/auth_session.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/welcome_game_elements.dart';

class AuthFlowView extends StatefulWidget {
  const AuthFlowView({super.key, required this.controller});
  final AuthController controller;
  @override
  State<AuthFlowView> createState() => _AuthFlowViewState();
}

class _AuthFlowViewState extends State<AuthFlowView>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  String? _avatarId;
  bool _obscure = true;
  bool _submitted = false;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale != locale && _submitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _form.currentState?.validate();
      });
    }
    _lastLocale = locale;
  }

  late AuthPage _lastPage;
  AuthController get auth => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastPage = auth.page;
    if (auth.page == AuthPage.profile) {
      _name.text = auth.name ?? auth.user?.displayName ?? '';
      _avatarId = auth.avatarId;
    }
  }

  @override
  void didUpdateWidget(covariant AuthFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastPage != auth.page) {
      _submitted = false;
      _form.currentState?.reset();
      _password.clear();
      _obscure = true;
      if (auth.page == AuthPage.profile) {
        _name.text = auth.name ?? auth.user?.displayName ?? '';
        _avatarId = auth.avatarId;
      } else if (auth.page == AuthPage.register) {
        _avatarId = null;
      }
      _lastPage = auth.page;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        auth.page == AuthPage.verifyEmail &&
        !auth.busy) {
      auth.checkVerification();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (auth.busy) return;
    _submitted = true;
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    switch (auth.page) {
      case AuthPage.login:
        auth.login(_email.text, _password.text);
      case AuthPage.register:
        auth.register(_name.text, _email.text, _password.text, _avatarId);
      case AuthPage.resetPassword:
        auth.sendReset(_email.text);
      case AuthPage.profile:
        auth.saveProfile(_name.text, _avatarId);
      default:
        break;
    }
  }

  Widget _nameField() => TextFormField(
    controller: _name,
    enabled: !auth.busy,
    maxLength: 50,
    textCapitalization: TextCapitalization.words,
    autofillHints: [AutofillHints.name],
    textInputAction: auth.page == AuthPage.profile
        ? TextInputAction.done
        : TextInputAction.next,
    decoration: InputDecoration(
      labelText: context.l10n.nameLabel,
      hintText: context.l10n.nameHint,
      counterText: '',
    ),
    validator: (value) => context.l10n.validation(AuthValidation.name(value)),
    onFieldSubmitted: (_) {
      if (auth.page == AuthPage.profile) _submit();
    },
  );
  Widget _emailField() => TextFormField(
    controller: _email,
    enabled: !auth.busy,
    keyboardType: TextInputType.emailAddress,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [AutofillHints.email],
    textInputAction: auth.page == AuthPage.resetPassword
        ? TextInputAction.done
        : TextInputAction.next,
    decoration: InputDecoration(
      labelText: context.l10n.emailLabel,
      hintText: context.l10n.emailHint,
    ),
    validator: (value) => context.l10n.validation(AuthValidation.email(value)),
    onFieldSubmitted: (_) {
      if (auth.page == AuthPage.resetPassword) _submit();
    },
  );
  Widget _passwordField() => TextFormField(
    controller: _password,
    enabled: !auth.busy,
    obscureText: _obscure,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      auth.page == AuthPage.register
          ? AutofillHints.newPassword
          : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      labelText: context.l10n.passwordLabel,
      helperText: auth.page == AuthPage.register
          ? context.l10n.passwordHint
          : null,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        tooltip: _obscure
            ? context.l10n.showPassword
            : context.l10n.hidePassword,
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) => context.l10n.validation(
      AuthValidation.password(value, creating: auth.page == AuthPage.register),
    ),
    onFieldSubmitted: (_) => _submit(),
  );

  @override
  Widget build(BuildContext context) {
    final page = auth.page;
    final entry = page == AuthPage.login || page == AuthPage.register;
    final title = switch (page) {
      AuthPage.login => context.l10n.loginTitle,
      AuthPage.register => context.l10n.registerTitle,
      AuthPage.resetPassword => context.l10n.resetTitle,
      AuthPage.verifyEmail => context.l10n.verifyTitle,
      AuthPage.profile => context.l10n.profileTitle,
      AuthPage.loadingProfile => context.l10n.loadingProfile,
      AuthPage.profileError => context.l10n.retryTitle,
      AuthPage.complete => context.l10n.completeTitle(
        auth.name ?? context.l10n.foodie,
      ),
      _ => context.l10n.welcomeTitle,
    };
    final subtitle = switch (page) {
      AuthPage.login => context.l10n.loginSubtitle,
      AuthPage.register => context.l10n.registerSubtitle,
      AuthPage.resetPassword => context.l10n.resetSubtitle,
      AuthPage.verifyEmail => context.l10n.verifySubtitle(
        auth.user?.email ?? context.l10n.yourEmail,
      ),
      AuthPage.profile => context.l10n.profileSubtitle,
      AuthPage.loadingProfile => context.l10n.loadingProfileSubtitle,
      AuthPage.profileError => context.l10n.profileErrorSubtitle,
      AuthPage.complete => context.l10n.completeSubtitle,
      _ => '',
    };
    final canBack =
        !auth.busy &&
        [
          AuthPage.login,
          AuthPage.register,
          AuthPage.resetPassword,
        ].contains(page);
    void back() => auth.show(
      page == AuthPage.resetPassword ? AuthPage.login : AuthPage.welcome,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canBack) back();
      },
      child: AuthScaffold(
        title: title,
        subtitle: subtitle,
        onBack: canBack ? back : null,
        badge: page == AuthPage.complete
            ? context.l10n.readyBadge
            : context.l10n.companyBadge,
        children: [
          if (auth.error != null)
            AuthMessage(text: context.l10n.message(auth.error!), isError: true),
          if (auth.notice != null)
            AuthMessage(text: context.l10n.message(auth.notice!)),
          if (entry) ...[
            OutlinedButton(
              onPressed: auth.busy ? null : auth.google,
              style: OutlinedButton.styleFrom(
                foregroundColor: WelcomePalette.navy,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                side: BorderSide(color: Color(0xFFB8C4CC)),
              ),
              child: Text(
                context.l10n.google,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      context.l10n.emailDivider,
                      style: TextStyle(color: Color(0xFF64707B)),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
          ],
          if (entry ||
              page == AuthPage.resetPassword ||
              page == AuthPage.profile)
            AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (page == AuthPage.register ||
                        page == AuthPage.profile) ...[
                      _nameField(),
                      SizedBox(height: 16),
                      AvatarPicker(
                        key: ValueKey(page),
                        initialValue: _avatarId,
                        enabled: !auth.busy,
                        onChanged: (value) => _avatarId = value,
                      ),
                      SizedBox(height: 20),
                    ],
                    if (page != AuthPage.profile) ...[
                      _emailField(),
                      SizedBox(height: 16),
                    ],
                    if (entry) ...[_passwordField(), SizedBox(height: 12)],
                    if (page == AuthPage.login)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: auth.busy
                              ? null
                              : () => auth.show(AuthPage.resetPassword),
                          child: Text(context.l10n.forgotPassword),
                        ),
                      ),
                    SizedBox(height: 8),
                    AuthAction(
                      label: switch (page) {
                        AuthPage.register => context.l10n.createAccount,
                        AuthPage.profile => context.l10n.continueLabel,
                        AuthPage.resetPassword =>
                          auth.resetWait > 0
                              ? context.l10n.resendCountdown(auth.resetWait)
                              : context.l10n.sendReset,
                        _ => context.l10n.login,
                      },
                      busy: auth.busy,
                      onPressed:
                          page == AuthPage.resetPassword && auth.resetWait > 0
                          ? null
                          : _submit,
                    ),
                  ],
                ),
              ),
            ),
          if (entry) ...[
            SizedBox(height: 18),
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () => auth.show(
                      page == AuthPage.login
                          ? AuthPage.register
                          : AuthPage.login,
                    ),
              child: Text(
                page == AuthPage.login
                    ? context.l10n.newAccount
                    : context.l10n.existingAccount,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (page == AuthPage.verifyEmail) ...[
            Icon(
              Icons.mark_email_unread_rounded,
              size: 54,
              color: WelcomePalette.navy,
            ),
            SizedBox(height: 24),
            AuthAction(
              label: context.l10n.verifiedAction,
              busy: auth.busy,
              onPressed: auth.checkVerification,
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: auth.busy || auth.verificationWait > 0
                  ? null
                  : auth.resendVerification,
              child: Text(
                auth.verificationWait > 0
                    ? context.l10n.resendCountdown(auth.verificationWait)
                    : context.l10n.resendVerification,
              ),
            ),
          ],
          if (page == AuthPage.loadingProfile)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
          if (page == AuthPage.profileError)
            AuthAction(
              label: context.l10n.retry,
              busy: auth.busy,
              onPressed: auth.retryProfile,
            ),
          if (page == AuthPage.complete) ...[
            Icon(Icons.celebration_rounded, size: 72, color: Color(0xFFC47800)),
            SizedBox(height: 16),
            AuthMessage(text: context.l10n.profileSaved),
          ],
          if (auth.user != null) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: auth.busy ? null : auth.signOut,
              child: Text(context.l10n.signOut),
            ),
          ],
        ],
      ),
    );
  }
}
