import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';
import '../widgets/google_sign_in_button.dart';
import 'complete_google_profile_screen.dart';
import '../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool _obscureText = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final _authService = AuthService();
  final _googleSignIn = GoogleSignInService.instance;
  StreamSubscription<GoogleIdentityResult>? _googleResultsSubscription;

  @override
  void initState() {
    super.initState();
    _googleResultsSubscription = _googleSignIn.webResults.listen(
      _processGoogleIdentity,
    );
  }

  void _fazerLogin() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final resultado = await _authService.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success']) {
        // Persiste o snapshot do produtor (propriedades/animais) para uso offline.
        await SessionService.instance.warmCache();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Login realizado com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ??
                  'Não foi possível entrar. Tente novamente.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _fazerLoginGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    final identity = await _googleSignIn.authenticate();
    await _processGoogleIdentity(identity);
  }

  Future<void> _processGoogleIdentity(GoogleIdentityResult identity) async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);

    if (!identity.isSuccess) {
      setState(() => _isGoogleLoading = false);
      _showError(
        identity.errorMessage ??
            'Não foi possível entrar com o Google. Tente novamente.',
      );
      return;
    }

    final result = await _authService.loginWithGoogle(identity.idToken!);
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      await SessionService.instance.warmCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Login com Google realizado com sucesso.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (result['requiresProfileCompletion'] == true &&
        result['onboardingToken'] is String) {
      final rawProfile = result['profile'];
      final profile = rawProfile is Map
          ? Map<String, dynamic>.from(rawProfile)
          : null;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CompleteGoogleProfileScreen(
            onboardingToken: result['onboardingToken'] as String,
            googleProfile: profile,
          ),
        ),
      );
      if (!mounted) return;
      if (completed == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
      return;
    }

    _showError(
      result['message'] ??
          'Não foi possível entrar com o Google. Tente novamente.',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _googleResultsSubscription?.cancel();
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textMuted70 = AppColors.textMuted.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                width: double.infinity,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo_sisov.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'E-mail e senha cadastrados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'E-mail',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_senhaFocus),
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputStyle(
                              'Digite seu e-mail',
                              Icons.email_outlined,
                              textMuted70,
                            ),
                            validator: AppValidators.email,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Senha',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senhaController,
                            focusNode: _senhaFocus,
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _fazerLogin(),
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputStyle(
                              'Digite sua senha',
                              Icons.lock_outline,
                              textMuted70,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 22,
                                ),
                                tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                            validator: AppValidators.passwordLogin,
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _fazerLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 26,
                                      width: 26,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'ou',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_isGoogleLoading)
                            const SizedBox(
                              height: 54,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          else
                            buildGoogleSignInButton(
                              onPressed: _fazerLoginGoogle,
                              enabled: _googleSignIn.isConfigured,
                            ),
                          if (!_googleSignIn.isConfigured) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Login Google aguardando configuração. Use e-mail e senha.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Ainda não tem conta?',
                                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 190,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/register'),
                                    icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                                    label: const Text('Criar conta'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary, width: 2),
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _BottomSafeGap(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon, Color hintColor, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 15),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

class _BottomSafeGap extends StatelessWidget {
  const _BottomSafeGap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.paddingOf(context).bottom + 12);
  }
}