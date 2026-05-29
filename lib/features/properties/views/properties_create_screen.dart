import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/property_service.dart';
import '../../../core/utils/validators.dart';

class PropertyCreateScreen extends StatefulWidget {
  const PropertyCreateScreen({super.key});

  @override
  State<PropertyCreateScreen> createState() => _PropertyCreateScreenState();
}

class _PropertyCreateScreenState extends State<PropertyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final resultado = await _propertyService.createProperty(
        farmName: _nameController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriedade cadastrada!'), backgroundColor: Colors.green),
        );
        // Volta para a listagem avisando que houve sucesso para recarregar a lista
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nova Propriedade', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identificação da Fazenda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildLabel('Nome da Fazenda'),
              TextFormField(
                controller: _nameController,
                decoration: _inputStyle('Ex: Fazenda Boa Esperança', Icons.agriculture),
                validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Cidade'),
                        TextFormField(
                          controller: _cityController,
                          decoration: _inputStyle('Cidade', Icons.location_city),
                          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('UF'),
                        TextFormField(
                          controller: _stateController,
                          maxLength: 2,
                          decoration: _inputStyle('CE', Icons.map),
                          validator: AppValidators.state, // Usando o validador que criamos
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cadastrar Fazenda', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      counterText: "", // Esconde o contador de caracteres do UF
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}