import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Chave do Formulário para validação
  final _formKey = GlobalKey<FormState>();

  // 2. Controladores
  final _nomeController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // 3. Variáveis de Estado
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;

  // 4. Instância da nossa API
  final _authService = AuthService();

  // Validador customizado para confirmar senha
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirme a senha';
    if (value != _senhaController.text) return 'As senhas não conferem';
    return null;
  }

  // Função que faz o meio de campo entre a UI e a API
  void _fazerCadastro() async {
    // Só chama a API se todos os campos forem válidos
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Remove caracteres não numéricos do CPF
      final documentLimpo = _documentController.text.replaceAll(RegExp(r'\D'), '');

      final resultado = await _authService.register(
        _nomeController.text.trim(),
        documentLimpo,
        _emailController.text.trim(),
        _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success']) {
        // Sucesso! Mostra snackbar verde e volta para login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a tela de login
      } else {
        // Erro! Mostra snackbar vermelha com erro da API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Formata o CPF enquanto o usuário digita
  void _formatCPF(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'\D'), '');
    String formatted = '';

    for (int i = 0; i < cleanedValue.length && i < 11; i++) {
      if (i == 3 || i == 6) {
        formatted += '.';
      } else if (i == 9) {
        formatted += '-';
      }
      formatted += cleanedValue[i];
    }

    _documentController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Criar Conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // CABEÇALHO
            Container(
              padding: const EdgeInsets.fromLTRB(32, 30, 32, 40),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Complete os dados abaixo para usar o SISOV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // FORMULÁRIO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 30),
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
                    // NOME
                    const Text(
                      'Nome Completo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      keyboardType: TextInputType.name,
                      decoration: _inputStyle('João da Silva', Icons.person_outlined),
                      validator: AppValidators.name,
                    ),

                    const SizedBox(height: 20),

                    // CPF
                    const Text(
                      'CPF',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle('000.000.000-00', Icons.badge_outlined),
                      onChanged: _formatCPF,
                      validator: AppValidators.document,
                    ),

                    const SizedBox(height: 20),

                    // E-MAIL
                    const Text(
                      'E-mail',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputStyle('seu.email@exemplo.com', Icons.email_outlined),
                      validator: AppValidators.email,
                    ),

                    const SizedBox(height: 20),

                    // SENHA
                    const Text(
                      'Senha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _obscureText,
                      decoration: _inputStyle(
                        'Mínimo 6 caracteres',
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
                      validator: AppValidators.passwordRegister,
                    ),

                    const SizedBox(height: 20),

                    // CONFIRMAR SENHA
                    const Text(
                      'Confirmar Senha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: _obscureConfirmText,
                      decoration: _inputStyle(
                        'Confirme sua senha',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),

                    const SizedBox(height: 30),

                    // BOTÃO DE CADASTRO
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerCadastro,
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
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // LINK PARA LOGIN
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Já tem conta?',
                            style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 200,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.login, color: AppColors.primary),
                              label: const Text('Fazer login'),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Estilo dos inputs
  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
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
