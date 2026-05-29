import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';

class AnimalCreateScreen extends StatefulWidget {
  final String propertyId;
  const AnimalCreateScreen({super.key, required this.propertyId});

  @override
  State<AnimalCreateScreen> createState() => _AnimalCreateScreenState();
}

class _AnimalCreateScreenState extends State<AnimalCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalService = AnimalService();
  bool _isLoading = false;

  final _tagController = TextEditingController();
  final _breedController = TextEditingController();
  final _cityController = TextEditingController();
  final _dateController = TextEditingController(); // Novo controller para mostrar a data na tela

  String _selectedSex = 'FEMALE';
  DateTime? _selectedDate; // Variável para guardar a data real pro banco

  // --- Função para abrir o Calendário ---
  Future<void> _selectDate() async {
    // Tira o foco de qualquer campo de texto antes de abrir o calendário
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010), // Até quão velho o animal pode ser?
      lastDate: DateTime.now(),  // Impede selecionar datas no futuro
      builder: (context, child) {
        // Deixa o calendário com as cores do aplicativo
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Formata para aparecer bonitinho pro usuário (DD/MM/AAAA)
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'tagId': _tagController.text.trim(),
        'propertyId': widget.propertyId,
        'breed': _breedController.text.trim(),
        'sex': _selectedSex,
        'birthDate': _selectedDate!.toIso8601String(), // Agora envia a data exata escolhida
        'birthCity': _cityController.text.trim(),
      };

      final result = await _animalService.createAnimal(data);
      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ovino cadastrado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dados do Ovino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Identificação"),
              const SizedBox(height: 12),
              _buildCardContainer(
                child: TextFormField(
                  controller: _tagController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputStyle('Número do Brinco', Icons.tag).copyWith(
                    prefixText: 'Nº ',
                    prefixStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'O número do brinco é obrigatório' : null,
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Características"),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildGenderCard("Fêmea", Icons.female, 'FEMALE', Colors.pink)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGenderCard("Macho", Icons.male, 'MALE', Colors.blue)),
                ],
              ),

              const SizedBox(height: 16),
              _buildCardContainer(
                child: TextFormField(
                  controller: _breedController,
                  decoration: _inputStyle('Raça (ex: Santa Inês, Dorper)', Icons.pets),
                  validator: (v) => v == null || v.isEmpty ? 'A raça é obrigatória' : null,
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Nascimento & Origem"),
              const SizedBox(height: 12),

              // --- NOVO CAMPO: DATA DE NASCIMENTO ---
              _buildCardContainer(
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true, // Impede digitar texto
                  onTap: _selectDate, // Abre o calendário ao clicar
                  decoration: _inputStyle('Data de Nascimento', Icons.calendar_month),
                  validator: (v) => v == null || v.isEmpty ? 'A data é obrigatória' : null,
                ),
              ),

              const SizedBox(height: 16),
              _buildCardContainer(
                child: TextFormField(
                  controller: _cityController,
                  decoration: _inputStyle('Cidade de Nascimento', Icons.location_city),
                  validator: (v) => v == null || v.isEmpty ? 'A cidade é obrigatória' : null,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Finalizar Cadastro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, String value, Color color) {
    bool isSelected = _selectedSex == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedSex = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppColors.border, width: 2),
          boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(
                label,
                style: TextStyle(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                )
            ),
          ],
        ),
      ),
    );
  }
}