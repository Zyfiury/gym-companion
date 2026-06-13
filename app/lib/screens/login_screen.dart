import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/backend_config.dart';
import '../core/theme/brand_colors.dart';
import '../theme/app_theme.dart';
import '../utils/auth_validator.dart';
import '../widgets/auth/password_strength_meter.dart';
import '../widgets/auth_onboarding_ui.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_ui.dart';
import '../widgets/staggered_entry.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  String? _error;
  String? _info;
  bool _loading = false;
  bool _termsAccepted = false;
  bool _attemptedSubmit = false;

  bool get _isLogin => _tab == 0;

  bool get _canSubmit {
    if (_loading) return false;
    if (_isLogin) {
      return AuthValidator.canLogin(email: _email.text, password: _password.text);
    }
    return AuthValidator.canSignUp(
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      displayName: _name.text,
      termsAccepted: _termsAccepted,
    );
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirmPassword, _name]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_email, _password, _confirmPassword, _name]) {
      c.removeListener(_onFieldChanged);
    }
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _emailError() => _attemptedSubmit || _email.text.isNotEmpty ? AuthValidator.emailError(_email.text) : null;

  String? _passwordError() {
    if (!_attemptedSubmit && _password.text.isEmpty) return null;
    return _isLogin ? AuthValidator.loginPasswordError(_password.text) : AuthValidator.passwordSignUpError(_password.text);
  }

  String? _confirmError() {
    if (_isLogin) return null;
    if (!_attemptedSubmit && _confirmPassword.text.isEmpty) return null;
    return AuthValidator.confirmPasswordError(_password.text, _confirmPassword.text);
  }

  String? _nameError() {
    if (_isLogin) return null;
    if (!_attemptedSubmit && _name.text.isEmpty) return null;
    return AuthValidator.displayNameError(_name.text);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _error = null;
      _info = null;
      _loading = true;
    });
    try {
      await action();
    } catch (e) {
      final msg = AuthValidator.friendlyAuthError(e);
      if (msg.isEmpty) return;
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(bool isLogin) async {
    setState(() => _attemptedSubmit = true);
    if (!_canSubmit) return;
    await _run(() async {
      final state = context.read<AppState>();
      final email = AuthValidator.normalizeEmail(_email.text);
      if (isLogin) {
        await state.login(email, _password.text);
      } else {
        await state.signUp(email, _password.text, _name.text.trim());
      }
    });
  }

  Future<void> _googleSignIn() => _run(() => context.read<AppState>().signInWithGoogle());

  Future<void> _appleSignIn() => _run(() => context.read<AppState>().signInWithApple());

  Future<void> _forgotPassword() async {
    setState(() => _attemptedSubmit = true);
    final emailErr = AuthValidator.emailError(_email.text);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    final email = AuthValidator.normalizeEmail(_email.text);
    await _run(() async {
      await context.read<AppState>().resetPassword(email);
      setState(() => _info = 'Password reset email sent - check your inbox');
    });
  }

  void _fillTestAccount() {
    _email.text = TestAccounts.testEmail;
    _password.text = TestAccounts.testPassword;
    setState(() {
      _tab = 0;
      _attemptedSubmit = false;
      _error = null;
    });
  }

  void _onTabChanged(int i) {
    setState(() {
      _tab = i;
      _attemptedSubmit = false;
      _error = null;
      _info = null;
      if (i == 0) {
        _confirmPassword.clear();
        _termsAccepted = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSocial = BackendConfig.hasFirebase && AppConfig.showSocialLogin;
    final t = context.appTheme;
    final isLogin = _isLogin;

    return Scaffold(
      backgroundColor: t.scaffold,
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.screenPadding, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      StaggeredEntry(
                        index: 0,
                        child: const Center(child: BrandMark(size: 76)),
                      ),
                      const SizedBox(height: 22),
                      StaggeredEntry(
                        index: 1,
                        child: Text(
                          AppConfig.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: t.textPrimary,
                            letterSpacing: -1.2,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StaggeredEntry(
                        index: 2,
                        child: Text(
                          'Training, nutrition, and progress -\nin one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.45, color: t.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (showSocial) ...[
                        StaggeredEntry(
                          index: 3,
                          child: Semantics(
                            identifier: 'login-google',
                            button: true,
                            child: _SocialButton(
                              label: 'Continue with Google',
                              leading: _GoogleGlyph(),
                              onPressed: _loading ? null : _googleSignIn,
                            ),
                          ),
                        ),
                        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                          const SizedBox(height: 10),
                          StaggeredEntry(
                            index: 3,
                            child: Semantics(
                              identifier: 'login-apple',
                              button: true,
                              child: _SocialButton(
                                label: 'Continue with Apple',
                                leading: Icon(Icons.apple, size: 22, color: t.textPrimary),
                                onPressed: _loading ? null : _appleSignIn,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _OrDivider(),
                        const SizedBox(height: 22),
                      ],
                      StaggeredEntry(
                        index: 4,
                        child: AppCard(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthPillTabs(
                                index: _tab,
                                labels: const ['Log in', 'Sign up'],
                                onChanged: _onTabChanged,
                              ),
                              const SizedBox(height: 20),
                              AutofillGroup(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: Column(
                                    key: ValueKey(_tab),
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (!isLogin) ...[
                                        AuthField(
                                          controller: _name,
                                          label: 'Display name',
                                          icon: Icons.person_outline_rounded,
                                          semanticsId: 'signup-name',
                                          errorText: _nameError(),
                                          textInputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      AuthField(
                                        controller: _email,
                                        label: 'Email',
                                        hint: 'you@email.com',
                                        icon: Icons.mail_outline_rounded,
                                        keyboard: TextInputType.emailAddress,
                                        autofillHints: const [AutofillHints.email],
                                        semanticsId: 'login-email',
                                        errorText: _emailError(),
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(height: 12),
                                      AuthField(
                                        controller: _password,
                                        label: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: true,
                                        showPasswordToggle: true,
                                        autofillHints: isLogin
                                            ? const [AutofillHints.password]
                                            : const [AutofillHints.newPassword],
                                        semanticsId: 'login-password',
                                        errorText: _passwordError(),
                                        textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                                      ),
                                      if (!isLogin) ...[
                                        const SizedBox(height: 10),
                                        PasswordStrengthMeter(password: _password.text),
                                        const SizedBox(height: 12),
                                        AuthField(
                                          controller: _confirmPassword,
                                          label: 'Confirm password',
                                          icon: Icons.lock_outline_rounded,
                                          obscure: true,
                                          showPasswordToggle: true,
                                          autofillHints: const [AutofillHints.newPassword],
                                          semanticsId: 'signup-confirm-password',
                                          errorText: _confirmError(),
                                          textInputAction: TextInputAction.done,
                                        ),
                                        const SizedBox(height: 12),
                                        Semantics(
                                          identifier: 'signup-terms',
                                          checked: _termsAccepted,
                                          child: InkWell(
                                            onTap: _loading
                                                ? null
                                                : () => setState(() => _termsAccepted = !_termsAccepted),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: Checkbox(
                                                      value: _termsAccepted,
                                                      onChanged: _loading
                                                          ? null
                                                          : (v) => setState(() => _termsAccepted = v ?? false),
                                                      activeColor: context.appColors.primary,
                                                      side: BorderSide(color: t.textMuted),
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Wrap(
                                                      children: [
                                                        Text('I agree to the ', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                                                        GestureDetector(
                                                          onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                                                          child: Text(
                                                            'Terms',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: context.appColors.primary,
                                                              decoration: TextDecoration.underline,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(' and ', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                                                        GestureDetector(
                                                          onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                                                          child: Text(
                                                            'Privacy Policy',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: context.appColors.primary,
                                                              decoration: TextDecoration.underline,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_attemptedSubmit && !_termsAccepted) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Accept the Terms and Privacy Policy to continue',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.appColors.error),
                                          ),
                                        ],
                                      ],
                                      if (isLogin)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _loading ? null : _forgotPassword,
                                            child: Text('Forgot password?', style: TextStyle(fontSize: 12, color: t.textMuted)),
                                          ),
                                        ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 4),
                                        _MessageBanner(text: _error!, color: context.appColors.error),
                                      ],
                                      if (_info != null) ...[
                                        const SizedBox(height: 4),
                                        _MessageBanner(text: _info!, color: context.appColors.mint),
                                      ],
                                      const SizedBox(height: 16),
                                      Semantics(
                                        identifier: 'login-submit',
                                        button: true,
                                        child: GradientButton(
                                          expanded: true,
                                          label: _loading ? 'Please wait…' : (isLogin ? 'Log in' : 'Create account'),
                                          onPressed: _canSubmit ? () => _submit(isLogin) : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (AppConfig.showTestAccounts) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          identifier: 'fill-test-account',
                          button: true,
                          child: TextButton(
                            onPressed: _fillTestAccount,
                            child: Text(
                              'Use test account (test@gym.app)',
                              style: TextStyle(fontSize: 13, color: t.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _openUrl(AppConfig.termsOfServiceUrl),
                            child: Text('Terms', style: TextStyle(fontSize: 11, color: t.textMuted)),
                          ),
                          Text('·', style: TextStyle(color: t.textMuted)),
                          TextButton(
                            onPressed: () => _openUrl(AppConfig.privacyPolicyUrl),
                            child: Text('Privacy', style: TextStyle(fontSize: 11, color: t.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Row(
      children: [
        Expanded(child: Divider(color: t.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or use email', style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: t.borderSubtle)),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _MessageBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  const _SocialButton({required this.label, required this.leading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return PressableScale(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? t.card : context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.borderSubtle),
          boxShadow: context.isDarkTheme ? null : [BoxShadow(color: t.shadow, blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: t.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = size.width * 0.18;
    final colors = BrandColors.googleGlyph;
    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - stroke / 2),
        i * 1.57 - 1.2,
        1.1,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
