import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscureText = true;


  final Color primaryTeal = const Color(0xFF0F8F82);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,

      resizeToAvoidBottomInset: false,
      body: Column(
        children: [

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usuário',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userController,
                    decoration: _inputStyle('Seu nome de usuário', Icons.person_outline),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Senha',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _senhaController,
                    obscureText: _obscureText,
                    decoration: _inputStyle(
                      'Sua senha',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),


                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      // O 'async' é obrigatório para usar o 'await' do banco de dados
                      onPressed: () async {
                        String usuario = _userController.text;
                        String senha = _senhaController.text;

                        // 1. Chame o DatabaseHelper (certifique-se de ter importado o arquivo no topo)
                        final user = await DatabaseHelper.instance.login(usuario, senha);

                        if (user != null) {
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuário ou senha incorretos!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        // ... resto do seu estilo
                      ),
                      child: const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryTeal, width: 2),
      ),
    );
  }
}