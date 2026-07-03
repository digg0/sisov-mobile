import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/slaughter_registration_model.dart';
import '../services/animal_service.dart';

class SlaughterRegistrationScreen extends StatefulWidget {
  final String animalId;
  final String animalTag;
  final DateTime birthDate;

  const SlaughterRegistrationScreen({
    super.key,
    required this.animalId,
    required this.animalTag,
    required this.birthDate,
  });

  @override
  State<SlaughterRegistrationScreen> createState() =>
      _SlaughterRegistrationScreenState();
}

class _SlaughterRegistrationScreenState
    extends State<SlaughterRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalService = AnimalService();
  bool _isSubmitting = false;

  // Controllers para campos de texto
  final _slaughterLocationController = TextEditingController();
  final _carcassWeightController = TextEditingController();
  final _bulletinNumberController = TextEditingController();
  final _gtaNumberController = TextEditingController();
  final _htaNumberController = TextEditingController();
  final _slaughterhouseCodeController = TextEditingController();
  final _observationsController = TextEditingController();
  final _carcassRendimentoController = TextEditingController();

  // Valores selecionados
  DateTime? _selectedSlaughterDate;
  String _animalAgeProof = 'TRACEABILITY';
  String _carcassColor = 'PINK_RED';
  String _fatColor = 'WHITE';
  String _meatTexture = 'FINE';
  bool _animalWelfareConfirmed = false;
  bool _sanitaryConditionConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedSlaughterDate = DateTime.now();
  }

  @override
  void dispose() {
    _slaughterLocationController.dispose();
    _carcassWeightController.dispose();
    _bulletinNumberController.dispose();
    _gtaNumberController.dispose();
    _htaNumberController.dispose();
    _slaughterhouseCodeController.dispose();
    _observationsController.dispose();
    _carcassRendimentoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedSlaughterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedSlaughterDate = pickedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSlaughterDate == null) {
      _showError('Selecione a data do abate');
      return;
    }

    if (!_animalWelfareConfirmed || !_sanitaryConditionConfirmed) {
      _showError(
        'Você deve confirmar as condições de bem-estar animal e sanidade',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final registration = SlaughterRegistration(
        animalId: widget.animalId,
        slaughterDate: _selectedSlaughterDate!,
        slaughterLocation: _slaughterLocationController.text.trim(),
        carcassWeight: double.tryParse(_carcassWeightController.text) ?? 0,
        animalAgeProof: _animalAgeProof,
        carcassColor: _carcassColor,
        fatColor: _fatColor,
        meatTexture: _meatTexture,
        bulletinNumber: _bulletinNumberController.text.trim(),
        gtaNumber: _gtaNumberController.text.trim(),
        htaNumber: _htaNumberController.text.trim(),
        animalWelfareConfirmed: _animalWelfareConfirmed,
        sanitaryConditionConfirmed: _sanitaryConditionConfirmed,
        carcassRendimento:
            double.tryParse(_carcassRendimentoController.text) ?? 0,
        observations: _observationsController.text.trim(),
        slaughterhouseCode: _slaughterhouseCodeController.text.trim(),
      );

      final result = await _animalService.registerSlaughter(registration);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Abate registrado com sucesso e IG validada!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Erro ao registrar abate');
      }
    } catch (e) {
      _showError('Erro ao processar: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ageInDays = DateTime.now().difference(widget.birthDate).inDays;
    final ageInMonths = (ageInDays / 30).toStringAsFixed(1);
    final isAgeValid = ageInDays <= 365;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Registrar Abate - IG Tauá',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
              // ─── INFORMAÇÕES DO ANIMAL ─────────────────────────────────
              _buildSectionHeader('Informações do Animal'),
              const SizedBox(height: 12),
              _buildInfoCard(
                label: 'Brinco',
                value: widget.animalTag,
                icon: Icons.tag,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                label: 'Idade',
                value:
                    '$ageInMonths meses (${ageInDays} dias) ${isAgeValid ? '✓' : '✗'}',
                icon: Icons.calendar_today,
                color: isAgeValid ? Colors.green : Colors.red,
              ),

              const SizedBox(height: 24),

              // ─── REQUISITOS TÉCNICOS ─────────────────────────────────
              _buildSectionHeader('Requisitos Técnicos de Conformidade'),
              const SizedBox(height: 12),
              const Text(
                'Conforme Caderno de Especificações Técnicas - Indicação de Procedência "Manta de Carneiro de Tauá - CE"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Comprovação de Idade
              _buildDropdown(
                label: 'Comprovação de Idade',
                value: _animalAgeProof,
                items: const [
                  {'value': 'TRACEABILITY', 'label': 'Rastreabilidade'},
                  {'value': 'TEETH', 'label': 'Análise de Dentes'},
                ],
                onChanged: (val) => setState(() => _animalAgeProof = val),
              ),
              const SizedBox(height: 16),

              // Cor da Carcaça
              _buildDropdown(
                label: 'Cor da Carcaça',
                value: _carcassColor,
                items: const [
                  {'value': 'PINK_RED', 'label': 'Vermelha Rosada'},
                  {'value': 'OTHER', 'label': 'Outra'},
                ],
                onChanged: (val) => setState(() => _carcassColor = val),
                description: 'Deve ser vermelha rosada conforme especificação',
              ),
              const SizedBox(height: 16),

              // Cor da Gordura
              _buildDropdown(
                label: 'Cor da Gordura',
                value: _fatColor,
                items: const [
                  {'value': 'WHITE', 'label': 'Branca'},
                  {'value': 'OTHER', 'label': 'Outra'},
                ],
                onChanged: (val) => setState(() => _fatColor = val),
                description: 'Deve ser branca conforme especificação',
              ),
              const SizedBox(height: 16),

              // Textura da Carne
              _buildDropdown(
                label: 'Textura da Carne',
                value: _meatTexture,
                items: const [
                  {'value': 'FINE', 'label': 'Fina'},
                  {'value': 'OTHER', 'label': 'Outra'},
                ],
                onChanged: (val) => setState(() => _meatTexture = val),
                description: 'Deve ser fina conforme especificação',
              ),
              const SizedBox(height: 16),

              // Peso da Carcaça
              TextFormField(
                controller: _carcassWeightController,
                decoration: _inputDecoration(
                  'Peso da Carcaça (kg)',
                  Icons.scale,
                  'Ex: 18.5',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo obrigatório';
                  final weight = double.tryParse(val);
                  if (weight == null || weight <= 0) {
                    return 'Peso deve ser um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rendimento da Carcaça
              TextFormField(
                controller: _carcassRendimentoController,
                decoration: _inputDecoration(
                  'Rendimento da Carcaça (%)',
                  Icons.percent,
                  'Mínimo 42% - Ex: 45.5',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo obrigatório';
                  final rendimento = double.tryParse(val);
                  if (rendimento == null || rendimento < 42) {
                    return 'Rendimento deve ser no mínimo 42%';
                  }
                  if (rendimento > 100) return 'Rendimento não pode ultrapassar 100%';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ─── DOCUMENTAÇÃO ────────────────────────────────────
              _buildSectionHeader('Documentação Obrigatória'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bulletinNumberController,
                decoration: _inputDecoration(
                  'Boletim de Embarque',
                  Icons.receipt,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Boletim de Embarque é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _gtaNumberController,
                decoration: _inputDecoration(
                  'GTA - Guia de Trânsito Animal',
                  Icons.assignment,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'GTA é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _htaNumberController,
                decoration: _inputDecoration(
                  'HTA - Higiene e Tecnologia de Abate',
                  Icons.verified,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'HTA é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ─── ABATE ─────────────────────────────────
              _buildSectionHeader('Dados do Abate'),
              const SizedBox(height: 12),

              // Data do Abate
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedSlaughterDate == null
                            ? 'Selecione a data'
                            : '${_selectedSlaughterDate!.day}/${_selectedSlaughterDate!.month}/${_selectedSlaughterDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _slaughterLocationController,
                decoration: _inputDecoration(
                  'Local do Abate (Frigorífico)',
                  Icons.location_on,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Local do abate é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _slaughterhouseCodeController,
                decoration: _inputDecoration(
                  'Código do Frigorífico (SIF/SIE/SIM)',
                  Icons.business,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Código do frigorífico é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ─── BEM-ESTAR E SANIDADE ────────────────────────────────
              _buildSectionHeader('Certificações Obrigatórias'),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title: 'Bem-Estar Animal Confirmado',
                subtitle:
                    'Confirmo que o animal foi transportado e abatido conforme normas de bem-estar',
                value: _animalWelfareConfirmed,
                onChanged: (val) =>
                    setState(() => _animalWelfareConfirmed = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title: 'Sanidade Confirmada',
                subtitle:
                    'Confirmo que o animal passou em inspeção sanitária e está apto',
                value: _sanitaryConditionConfirmed,
                onChanged: (val) =>
                    setState(() => _sanitaryConditionConfirmed = val ?? false),
              ),
              const SizedBox(height: 24),

              // ─── OBSERVAÇÕES ────────────────────────────────────
              _buildSectionHeader('Observações Adicionais'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observationsController,
                decoration: _inputDecoration(
                  'Observações',
                  Icons.notes,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // ─── BOTÕES ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Enviando...' : 'REGISTRAR ABATE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    Color color = AppColors.primary,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
    String? description,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) ...[
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              underline: const SizedBox(),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item['value']!,
                        child: Text(item['label']!),
                      ))
                  .toList(),
              onChanged: (val) => val != null ? onChanged(val) : null,
            ),
          ),
        ],
      );

  InputDecoration _inputDecoration(String label, IconData icon,
      [String? hint]) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? AppColors.success : Colors.grey.shade300,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: value ? AppColors.success.withValues(alpha: 0.05) : Colors.white,
        ),
        child: CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.success,
        ),
      );
}
