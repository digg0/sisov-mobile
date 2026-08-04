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
  final _slaughterhouseCodeController = TextEditingController();
  final _observationsController = TextEditingController();
  final _carcassRendimentoController = TextEditingController();

  // Valores selecionados (usam os mesmos códigos aceitos pelo backend)
  DateTime? _selectedSlaughterDate;
  String _proofOfAge = 'RASTREABILIDADE';
  String _carcassColor = 'VERMELHA_ROSADA';
  String _fatColor = 'BRANCA';
  String _meatTexture = 'FINA';
  bool _hasBoletimEmbarque = false;
  bool _hasGTA = false;
  bool _hasHTA = false;
  bool _animalWelfareConfirmed = false;
  bool _sanitaryConditionConfirmed = false;
  bool _geographicOriginConfirmed = false;
  bool _preSlaughterFastingConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedSlaughterDate = DateTime.now();
  }

  @override
  void dispose() {
    _slaughterLocationController.dispose();
    _carcassWeightController.dispose();
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

    // Características da carcaça: o Caderno exige valores específicos.
    if (_carcassColor != 'VERMELHA_ROSADA') {
      _showError(
        'A carcaça deve ser vermelha rosada para atender à IG (Art. 6º, §2º, I)',
      );
      return;
    }
    if (_fatColor != 'BRANCA') {
      _showError(
        'A gordura deve ser branca para atender à IG (Art. 6º, §2º, I)',
      );
      return;
    }
    if (_meatTexture != 'FINA') {
      _showError(
        'A textura da carne deve ser fina para atender à IG (Art. 6º, §2º, I)',
      );
      return;
    }

    if (!_hasBoletimEmbarque || !_hasGTA || !_hasHTA) {
      _showError(
        'Confirme a posse do Boletim de Embarque, GTA e HTA (documentação obrigatória)',
      );
      return;
    }

    if (!_animalWelfareConfirmed || !_sanitaryConditionConfirmed) {
      _showError(
        'Você deve confirmar as condições de bem-estar animal e sanidade',
      );
      return;
    }

    if (!_geographicOriginConfirmed) {
      _showError(
        'Você deve confirmar a origem geográfica do animal (Tauá ou mín. 3 meses na região)',
      );
      return;
    }

    if (!_preSlaughterFastingConfirmed) {
      _showError(
        'Você deve confirmar o jejum pré-abate (dieta hídrica 12h + sólida 16h)',
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
        proofOfAge: _proofOfAge,
        carcassColor: _carcassColor,
        fatColor: _fatColor,
        meatTexture: _meatTexture,
        hasBoletimEmbarque: _hasBoletimEmbarque,
        hasGTA: _hasGTA,
        hasHTA: _hasHTA,
        confirmWelfare: _animalWelfareConfirmed,
        confirmSanity: _sanitaryConditionConfirmed,
        geographicOriginConfirmed: _geographicOriginConfirmed,
        preSlaughterFastingConfirmed: _preSlaughterFastingConfirmed,
        carcassYield:
            double.tryParse(_carcassRendimentoController.text) ?? 0,
        additionalNotes: _observationsController.text.trim(),
        frigorificoCode: _slaughterhouseCodeController.text.trim(),
      );

      final result = await _animalService.registerSlaughter(registration);

      if (!mounted) return;

      if (result['success']) {
        final queued = result['queued'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(queued
                ? (result['message'] ??
                    'Abate salvo no aparelho. Será enviado quando houver internet.')
                : '✓ Abate registrado com sucesso e IG validada!'),
            backgroundColor: queued ? AppColors.warning : AppColors.success,
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
              // ─── APRESENTAÇÃO DO QUESTIONÁRIO ────────────────────────────
              _buildIntroBanner(),
              const SizedBox(height: 24),

              // ─── INFORMAÇÕES DO ANIMAL ─────────────────────────────────
              _buildSectionHeader('1. Identificação do Animal'),
              const SizedBox(height: 6),
              const Text(
                'Confira os dados do animal que está sendo enviado ao abate.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                label: 'Coleira',
                value: widget.animalTag,
                icon: Icons.tag,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                label: 'Idade do animal',
                value:
                    '$ageInMonths meses ($ageInDays dias) ${isAgeValid ? '✓ Apto' : '✗ Acima de 12 meses'}',
                icon: Icons.calendar_today,
                color: isAgeValid ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 8),
              const Text(
                'O animal possui até 12 meses de idade? (Art. 6º, §2º, I — exige-se idade máxima de 12 meses)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 24),

              // ─── REQUISITOS TÉCNICOS ─────────────────────────────────
              _buildSectionHeader('2. Requisitos Técnicos de Conformidade'),
              const SizedBox(height: 6),
              const Text(
                'Responda com base nas características observadas no animal e na carcaça, conforme o Caderno de Especificações Técnicas da IP "Manta de Carneiro de Tauá - CE".',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Comprovação de Idade
              _buildQuestionLabel(
                'Como foi comprovada a idade do animal?',
                reference:
                    'Art. 11, §1º — A comprovação da idade se dá pela rastreabilidade ou pela análise dos dentes do animal.',
              ),
              _buildDropdown(
                label: 'Selecione o método de comprovação',
                value: _proofOfAge,
                items: const [
                  {'value': 'RASTREABILIDADE', 'label': 'Rastreabilidade'},
                  {'value': 'DENTES', 'label': 'Análise de Dentes'},
                ],
                onChanged: (val) => setState(() => _proofOfAge = val),
              ),
              const SizedBox(height: 20),

              // Cor da Carcaça
              _buildQuestionLabel(
                'Qual é a cor da carcaça do animal?',
                reference:
                    'Art. 6º, §2º, I — A carcaça deve apresentar cor vermelha rosada.',
              ),
              _buildDropdown(
                label: 'Selecione a cor da carcaça',
                value: _carcassColor,
                items: const [
                  {'value': 'VERMELHA_ROSADA', 'label': 'Vermelha Rosada'},
                  {'value': 'OTHER', 'label': 'Outra (não conforme)'},
                ],
                onChanged: (val) => setState(() => _carcassColor = val),
              ),
              const SizedBox(height: 20),

              // Cor da Gordura
              _buildQuestionLabel(
                'Qual é a cor da gordura da carcaça?',
                reference:
                    'Art. 6º, §2º, I — A gordura deve ser branca.',
              ),
              _buildDropdown(
                label: 'Selecione a cor da gordura',
                value: _fatColor,
                items: const [
                  {'value': 'BRANCA', 'label': 'Branca'},
                  {'value': 'OTHER', 'label': 'Outra (não conforme)'},
                ],
                onChanged: (val) => setState(() => _fatColor = val),
              ),
              const SizedBox(height: 20),

              // Textura da Carne
              _buildQuestionLabel(
                'Qual é a textura da carne?',
                reference:
                    'Art. 6º, §2º, I — A carne deve apresentar textura fina.',
              ),
              _buildDropdown(
                label: 'Selecione a textura da carne',
                value: _meatTexture,
                items: const [
                  {'value': 'FINA', 'label': 'Fina'},
                  {'value': 'OTHER', 'label': 'Outra (não conforme)'},
                ],
                onChanged: (val) => setState(() => _meatTexture = val),
              ),
              const SizedBox(height: 20),

              // Peso da Carcaça
              _buildQuestionLabel(
                'Qual é o peso da carcaça (em kg)?',
                reference:
                    'Art. 11, §2º — O peso da carcaça deve ser verificado para atender aos critérios da IP.',
              ),
              TextFormField(
                controller: _carcassWeightController,
                decoration: _inputDecoration(
                  'Peso da carcaça (kg)',
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
              const SizedBox(height: 20),

              // Rendimento da Carcaça
              _buildQuestionLabel(
                'Qual é o rendimento da carcaça (em %)?',
                reference:
                    'Art. 6º, §2º, III — O rendimento mínimo da carcaça deve ser de 42%.',
              ),
              TextFormField(
                controller: _carcassRendimentoController,
                decoration: _inputDecoration(
                  'Rendimento da carcaça (%)',
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
              _buildSectionHeader('3. Documentação Obrigatória'),
              const SizedBox(height: 6),
              const Text(
                'Confirme que o transporte e o abate do animal possuem a documentação exigida.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              _buildCheckboxTile(
                title: 'O transporte do animal possui Boletim de Embarque?',
                subtitle:
                    'Art. 7º — Preenchimento obrigatório no carregamento dos animais.',
                value: _hasBoletimEmbarque,
                onChanged: (val) =>
                    setState(() => _hasBoletimEmbarque = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title:
                    'O transporte possui GTA (Guia de Trânsito Animal)?',
                subtitle:
                    'Art. 7º — O transporte deve ser acompanhado da GTA.',
                value: _hasGTA,
                onChanged: (val) => setState(() => _hasGTA = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title:
                    'O abate possui registro de HTA (Higiene e Tecnologia de Abate)?',
                subtitle:
                    'Art. 10 — O abate deve ocorrer em abatedouro inspecionado.',
                value: _hasHTA,
                onChanged: (val) => setState(() => _hasHTA = val ?? false),
              ),
              const SizedBox(height: 24),

              // ─── ABATE ─────────────────────────────────
              _buildSectionHeader('4. Dados do Abate'),
              const SizedBox(height: 6),
              const Text(
                'Informe onde e quando o animal foi abatido.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Data do Abate
              _buildQuestionLabel(
                'Em que data o animal foi abatido?',
                reference:
                    'Art. 10 — O abate deve ser realizado de forma humanitária em abatedouro inspecionado.',
              ),
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
              const SizedBox(height: 20),

              _buildQuestionLabel(
                'Em qual frigorífico/abatedouro o animal foi abatido?',
                reference:
                    'Art. 6º, §3º — O processamento deve ocorrer em estabelecimento com inspeção SIM, SIE ou SIF.',
              ),
              TextFormField(
                controller: _slaughterLocationController,
                decoration: _inputDecoration(
                  'Nome do frigorífico/abatedouro',
                  Icons.location_on,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Local do abate é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildQuestionLabel(
                'Qual é o código de inspeção do frigorífico (SIF, SIE ou SIM)?',
                reference:
                    'Art. 6º, §3º / Art. 10 — O abatedouro deve possuir sistema de inspeção municipal (SIM), estadual (SIE) ou federal (SIF).',
              ),
              TextFormField(
                controller: _slaughterhouseCodeController,
                decoration: _inputDecoration(
                  'Código SIF / SIE / SIM',
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
              _buildSectionHeader('5. Declarações de Conformidade'),
              const SizedBox(height: 6),
              const Text(
                'Marque cada declaração apenas se ela for verdadeira para este abate. São obrigatórias para a validação da IP.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              _buildCheckboxTile(
                title:
                    'O animal foi transportado e abatido conforme as normas de bem-estar animal?',
                subtitle:
                    'Art. 7º e Art. 10 — Transporte sem estresse ou maus-tratos e abate humanitário.',
                value: _animalWelfareConfirmed,
                onChanged: (val) =>
                    setState(() => _animalWelfareConfirmed = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title:
                    'O animal passou por inspeção sanitária e foi considerado apto ao abate?',
                subtitle:
                    'Art. 8º e Art. 24 — Sanidade animal verificada antes do abate.',
                value: _sanitaryConditionConfirmed,
                onChanged: (val) =>
                    setState(() => _sanitaryConditionConfirmed = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title:
                    'O animal foi criado no município de Tauá ou permaneceu na região por, no mínimo, 3 meses antes do abate?',
                subtitle:
                    'Art. 6º, §1º — Origem geográfica exigida para a Indicação de Procedência.',
                value: _geographicOriginConfirmed,
                onChanged: (val) =>
                    setState(() => _geographicOriginConfirmed = val ?? false),
              ),
              const SizedBox(height: 12),

              _buildCheckboxTile(
                title:
                    'O animal cumpriu o jejum pré-abate (dieta hídrica de no mínimo 12h e dieta sólida de no mínimo 16h)?',
                subtitle:
                    'Art. 8º — Jejum obrigatório na chegada ao abatedouro antes do abate.',
                value: _preSlaughterFastingConfirmed,
                onChanged: (val) => setState(
                    () => _preSlaughterFastingConfirmed = val ?? false),
              ),
              const SizedBox(height: 24),

              // ─── OBSERVAÇÕES ────────────────────────────────────
              _buildSectionHeader('6. Observações Adicionais'),
              const SizedBox(height: 6),
              const Text(
                'Há alguma observação relevante sobre o animal, o transporte ou o abate? (opcional)',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observationsController,
                decoration: _inputDecoration(
                  'Digite aqui suas observações (opcional)',
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

  Widget _buildIntroBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.assignment_turned_in, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questionário de Conformidade da IP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Responda às perguntas abaixo para validar o abate conforme o Caderno de Especificações Técnicas da Indicação de Procedência "Manta de Carneiro de Tauá - CE". Cada pergunta indica o artigo do regulamento correspondente.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildQuestionLabel(String question, {String? reference}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            if (reference != null) ...[
              const SizedBox(height: 3),
              Text(
                reference,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      );

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
