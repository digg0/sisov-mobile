import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
// Substitua pelos caminhos corretos das pastas que criamos
import '../services/auth_service.dart';
import '../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Chave do Formulário para validação
  final _formKey = GlobalKey<FormState>();

  // 2. Controladores (Ajustado de usuario para email)
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // 3. Variáveis de Estado
  bool _obscureText = true;
  bool _isLoading = false;

  // 4. Instância da nossa API
  final _authService = AuthService();

  // Função que faz o meio de campo entre a UI e a API
  void _fazerLogin() async {
    // Só chama a API se o email for válido e a senha não estiver vazia
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final resultado = await _authService.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success']) {
        // Sucesso! Mostra snackbar verde e vai pra Home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Erro (ex: senha errada)! Mostra snackbar vermelha com erro da API
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // CABEÇALHO (Seu design mantido intacto!)
          Container(
            padding: const EdgeInsets.only(top: 100, bottom: 60),
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                      letterSpacing: -0.5
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse sua conta para continuar',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // FORMULÁRIO (Agora envolto em um Form e usando TextFormField)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 45, 32, 20),
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
                  children: [
                    const Text(
                      'E-mail', // Alterado de Usuário para E-mail (como pede a API)
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField( // Alterado para TextFormField para suportar validator
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputStyle('Seu e-mail cadastrado', Icons.email_outlined),
                      validator: AppValidators.email, // Validação conectada!
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Senha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _obscureText,
                      decoration: _inputStyle(
                        'Sua senha',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: AppValidators.passwordLogin, // Validação conectada!
                    ),

                    const SizedBox(height: 40),

                    // BOTÃO (Agora com estado de Loading)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LINK PARA CADASTRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem conta? ',
                          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            'Cadastre-se',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Estilo mantido intacto!
  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
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
      // Adicionado para a borda de erro ficar bonita também
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