import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
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

  final _authService = AuthService();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      // resizeToAvoidBottomInset padrão (true): scaffold encolhe com o teclado
      body: GestureDetector(
        // Toque fora dos campos fecha o teclado
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // reverse: true mantém o formulário visível quando o teclado abre —
              // a âncora de scroll fica na parte inferior (formulário), e o cabeçalho
              // verde sobe silenciosamente para fora da tela.
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── CABEÇALHO VERDE ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.only(top: 80, bottom: 48),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Bem-vindo ao SISOV',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acesse sua conta para continuar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── FORMULÁRIO BRANCO ────────────────────────────────────────
                  // minHeight garante que o cartão branco preenche o espaço restante
                  // da tela mesmo em dispositivos maiores.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.55,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── E-MAIL ────────────────────────────────────────
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
                              // Passa foco para a senha ao pressionar "Próximo"
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_senhaFocus),
                              style: const TextStyle(fontSize: 16),
                              decoration: _inputStyle(
                                'Digite seu e-mail',
                                Icons.email_outlined,
                              ),
                              validator: AppValidators.email,
                            ),

                            const SizedBox(height: 24),

                            // ── SENHA ─────────────────────────────────────────
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
                              // "Concluir" no teclado aciona o login diretamente
                              onFieldSubmitted: (_) => _fazerLogin(),
                              style: const TextStyle(fontSize: 16),
                              decoration: _inputStyle(
                                'Digite sua senha',
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 22,
                                  ),
                                  tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                                  onPressed: () =>
                                      setState(() => _obscureText = !_obscureText),
                                ),
                              ),
                              validator: AppValidators.passwordLogin,
                            ),

                            const SizedBox(height: 36),

                            // ── BOTÃO ENTRAR ──────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _fazerLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.6),
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

                            // ── LINK CADASTRO ─────────────────────────────────
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/register'),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black.withValues(alpha: 0.6),
                                    ),
                                    children: const [
                                      TextSpan(text: 'Não tem conta?  '),
                                      TextSpan(
                                        text: 'Cadastre-se aqui',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Espaço extra para o botão não colar no fundo em
                            // telas com barra de navegação por gestos
                            SizedBox(
                              height: MediaQuery.of(context).padding.bottom + 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7), fontSize: 15),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
