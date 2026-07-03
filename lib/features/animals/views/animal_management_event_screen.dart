import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';

class AnimalManagementEventScreen extends StatefulWidget {
  final String animalId;
  final String animalName;

  const AnimalManagementEventScreen({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  State<AnimalManagementEventScreen> createState() => _AnimalManagementEventScreenState();
}

class _AnimalManagementEventScreenState extends State<AnimalManagementEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _valueController = TextEditingController();
  final _animalService = AnimalService();
  bool _isSaving = false;
  DateTime? _selectedDate;
  String _selectedType = 'VACCINATION';

  static const _eventTypes = [
    {'value': 'VACCINATION', 'label': 'Vacinação'},
    {'value': 'WEIGHT_MEASUREMENT', 'label': 'Medição de Peso'},
    {'value': 'NUTRITIONAL_FEEDING', 'label': 'Alimentação'},
    {'value': 'REPRODUCTION_COVERAGE', 'label': 'Cobertura Reprodutiva'},
    {'value': 'VET_TREATMENT', 'label': 'Tratamento Veterinário'},
    {'value': 'SANITARY_DOCUMENT', 'label': 'Documento Sanitário'},
  ];

  String get _valueFieldLabel {
    switch (_selectedType) {
      case 'VACCINATION':
        return 'Vacina / Dose';
      case 'WEIGHT_MEASUREMENT':
        return 'Peso (kg)';
      case 'NUTRITIONAL_FEEDING':
        return 'Alimento / Quantidade';
      case 'REPRODUCTION_COVERAGE':
        return 'Descrição da Cobertura';
      case 'VET_TREATMENT':
        return 'Tratamento / Medicamento';
      case 'SANITARY_DOCUMENT':
        return 'Número do Documento';
      default:
        return 'Detalhes do Evento';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
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
      HapticFeedback.selectionClick();
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma data para o evento.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final eventData = {
      'eventType': _selectedType,
      'description': _descriptionController.text.trim(),
      'eventLocation': _locationController.text.trim(),
      'occurredAt': _selectedDate!.toIso8601String(),
      if (_valueController.text.trim().isNotEmpty) 'value': _valueController.text.trim(),
    };

    final result = await _animalService.registerManagementEvent(widget.animalId, eventData);
    setState(() => _isSaving = false);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento de manejo registrado com sucesso.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Falha ao registrar o evento.'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar evento'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Animal: ${widget.animalName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _buildDropdown(),
              const SizedBox(height: 14),
              _buildDateField(),
              const SizedBox(height: 14),
              _buildTextField(_descriptionController, 'Observações do Evento', Icons.notes, maxLines: 4),
              const SizedBox(height: 14),
              _buildTextField(_locationController, 'Local do Evento', Icons.location_on),
              const SizedBox(height: 14),
              _buildTextField(
                _valueController,
                _valueFieldLabel,
                Icons.straighten,
                keyboardType: _selectedType == 'WEIGHT_MEASUREMENT' ? TextInputType.number : TextInputType.text,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registre vacinas, pesagens, alimentação ou outros cuidados do animal.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedType,
        items: _eventTypes
            .map(
              (item) => DropdownMenuItem(
                value: item['value'],
                child: Text(item['label'] ?? ''),
              ),
            )
            .toList(),
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedType = value);
        },
      ),
    );
  }

  Widget _buildDateField() {
    final label = _selectedDate == null ? 'Data do Evento' : 'Data: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            const Icon(Icons.calendar_month, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          labelText: label,
          border: InputBorder.none,
        ),
        validator: (value) {
          if (label == 'Data do Evento') return null;
          if (label == _valueFieldLabel && _selectedType == 'WEIGHT_MEASUREMENT') {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o peso em kg.';
            }
          }
          return null;
        },
      ),
    );
  }
}
