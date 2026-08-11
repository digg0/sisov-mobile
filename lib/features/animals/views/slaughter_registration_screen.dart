import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/slaughter_registration_model.dart';
import '../services/animal_service.dart';

class SlaughterRegistrationScreen extends StatefulWidget {
  const SlaughterRegistrationScreen({super.key, required this.animals});

  final List<SlaughterAnimal> animals;

  @override
  State<SlaughterRegistrationScreen> createState() =>
      _SlaughterRegistrationScreenState();
}

class _SlaughterRegistrationScreenState
    extends State<SlaughterRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalService = AnimalService();
  final _locationController = TextEditingController();
  final _slaughterhouseCodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightControllers = <String, TextEditingController>{};
  final _yieldControllers = <String, TextEditingController>{};

  SlaughterMode _mode = SlaughterMode.standard;
  DateTime _slaughterDate = DateTime.now();
  String _proofOfAge = 'RASTREABILIDADE';
  String _carcassColor = 'VERMELHA_ROSADA';
  String _fatColor = 'BRANCA';
  String _meatTexture = 'FINA';
  bool _hasBoletimEmbarque = false;
  bool _hasGTA = false;
  bool _hasHTA = false;
  bool _confirmWelfare = false;
  bool _confirmSanity = false;
  bool _confirmOrigin = false;
  bool _confirmFasting = false;
  bool _submitting = false;

  bool get _isOwnIg => _mode == SlaughterMode.igOwn;
  bool get _needsSlaughterhouse => _mode != SlaughterMode.standard;

  @override
  void initState() {
    super.initState();
    for (final animal in widget.animals) {
      _weightControllers[animal.id] = TextEditingController();
      _yieldControllers[animal.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _slaughterhouseCodeController.dispose();
    _notesController.dispose();
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _yieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _slaughterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _slaughterDate = value);
  }

  SlaughterBatchRequest _buildRequest() {
    return SlaughterBatchRequest(
      mode: _mode,
      commonData: SlaughterCommonData(
        slaughterDate: _slaughterDate,
        slaughterLocation: _locationController.text.trim(),
        frigorificoCode: _needsSlaughterhouse
            ? _slaughterhouseCodeController.text.trim()
            : null,
        additionalNotes: _notesController.text.trim(),
        proofOfAge: _isOwnIg ? _proofOfAge : null,
        carcassColor: _isOwnIg ? _carcassColor : null,
        fatColor: _isOwnIg ? _fatColor : null,
        meatTexture: _isOwnIg ? _meatTexture : null,
        hasBoletimEmbarque: _isOwnIg ? _hasBoletimEmbarque : null,
        hasGTA: _isOwnIg ? _hasGTA : null,
        hasHTA: _isOwnIg ? _hasHTA : null,
        confirmWelfare: _confirmWelfare,
        confirmSanity: _confirmSanity,
        geographicOriginConfirmed: _isOwnIg ? _confirmOrigin : null,
        preSlaughterFastingConfirmed: _isOwnIg ? _confirmFasting : null,
      ),
      items: widget.animals
          .map(
            (animal) => SlaughterBatchItem(
              animalId: animal.id,
              carcassWeight: _isOwnIg
                  ? _parseNumber(_weightControllers[animal.id]!.text)
                  : null,
              carcassYield: _isOwnIg
                  ? _parseNumber(_yieldControllers[animal.id]!.text)
                  : null,
            ),
          )
          .toList(),
    );
  }

  double? _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateTechnicalRequirements() {
    if (!_isOwnIg) return null;
    if (_carcassColor != 'VERMELHA_ROSADA' ||
        _fatColor != 'BRANCA' ||
        _meatTexture != 'FINA') {
      return 'As características da carcaça não atendem aos requisitos da IG.';
    }
    if (!_hasBoletimEmbarque || !_hasGTA || !_hasHTA) {
      return 'Confirme toda a documentação obrigatória.';
    }
    if (!_confirmWelfare ||
        !_confirmSanity ||
        !_confirmOrigin ||
        !_confirmFasting) {
      return 'Confirme todas as declarações de conformidade.';
    }
    return null;
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    final request = _buildRequest();
    final error = request.validate() ?? _validateTechnicalRequirements();
    if (error != null) {
      _showError(error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar registro de abate'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _reviewLine('Modo', _mode.label),
              _reviewLine('Animais', '${widget.animals.length}'),
              _reviewLine(
                'Coleiras',
                widget.animals.map((animal) => animal.tagId).join(', '),
              ),
              _reviewLine(
                'Data',
                '${_slaughterDate.day.toString().padLeft(2, '0')}/'
                    '${_slaughterDate.month.toString().padLeft(2, '0')}/'
                    '${_slaughterDate.year}',
              ),
              _reviewLine('Local', _locationController.text.trim()),
              if (_mode == SlaughterMode.igSlaughterhouse)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Os animais ficarão pendentes de validação pelo abatedouro.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submit(request);
  }

  Widget _reviewLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  Future<void> _submit(SlaughterBatchRequest request) async {
    setState(() => _submitting = true);
    final result = await _animalService.registerSlaughterBatch(request);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] != true) {
      _showError(result['message'] ?? 'Não foi possível registrar o abate.');
      return;
    }

    final queued = result['queued'] == true;
    final statusMessage = _mode == SlaughterMode.igSlaughterhouse
        ? 'Abate registrado e aguardando validação do abatedouro.'
        : 'Abate registrado com sucesso.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          queued
              ? result['message'] ??
                    'Lote salvo no aparelho e aguardando envio.'
              : statusMessage,
        ),
        backgroundColor: queued ? AppColors.warning : AppColors.success,
      ),
    );
    Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.animals.length == 1
              ? 'Registrar abate'
              : 'Registrar abate em lote',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Animais selecionados'),
            const SizedBox(height: 10),
            _selectedAnimalsCard(),
            const SizedBox(height: 24),
            _sectionTitle('Modalidade do abate'),
            const SizedBox(height: 10),
            ...SlaughterMode.values.map(_modeTile),
            const SizedBox(height: 24),
            _sectionTitle('Dados comuns'),
            const SizedBox(height: 12),
            _dateField(),
            const SizedBox(height: 12),
            _textField(
              _locationController,
              'Local do abate',
              Icons.location_on_outlined,
              required: true,
            ),
            if (_needsSlaughterhouse) ...[
              const SizedBox(height: 12),
              _textField(
                _slaughterhouseCodeController,
                'Código SIF / SIE / SIM',
                Icons.business_outlined,
                required: true,
              ),
            ],
            if (_mode == SlaughterMode.igSlaughterhouse) ...[
              const SizedBox(height: 12),
              _notice(
                'O questionário técnico será preenchido e validado futuramente '
                'pelo abatedouro. O status inicial será “Abate pendente”.',
              ),
            ],
            if (_isOwnIg) ...[
              const SizedBox(height: 24),
              _technicalQuestionnaire(),
              const SizedBox(height: 24),
              _sectionTitle('Peso e rendimento por animal'),
              const SizedBox(height: 12),
              ...widget.animals.map(_animalMeasurements),
            ],
            const SizedBox(height: 16),
            _textField(
              _notesController,
              'Observações (opcional)',
              Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submitting ? null : _review,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(
                _submitting ? 'Registrando...' : 'Revisar e registrar',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _selectedAnimalsCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.animals
            .map(
              (animal) => Chip(
                avatar: const Icon(Icons.pets, size: 17),
                label: Text('Coleira ${animal.tagId}'),
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _modeTile(SlaughterMode mode) {
    final descriptions = {
      SlaughterMode.standard:
          'Sem IG. Formulário simples e finalização imediata.',
      SlaughterMode.igOwn:
          'Questionário técnico completo, peso e rendimento por animal.',
      SlaughterMode.igSlaughterhouse:
          'Sem questionário agora; fica pendente para validação futura.',
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => setState(() => _mode = mode),
        leading: Icon(
          _mode == mode ? Icons.radio_button_checked : Icons.radio_button_off,
          color: _mode == mode ? AppColors.primary : AppColors.textMuted,
        ),
        title: Text(mode.label),
        subtitle: Text(descriptions[mode]!),
      ),
    );
  }

  Widget _dateField() => InkWell(
    onTap: _pickDate,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: _decoration('Data do abate', Icons.calendar_today),
      child: Text(
        '${_slaughterDate.day.toString().padLeft(2, '0')}/'
        '${_slaughterDate.month.toString().padLeft(2, '0')}/'
        '${_slaughterDate.year}',
      ),
    ),
  );

  Widget _technicalQuestionnaire() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Questionário técnico da IG'),
      const SizedBox(height: 8),
      _notice(
        'As respostas abaixo são compartilhadas por todos os animais do lote.',
      ),
      const SizedBox(height: 12),
      _dropdown(
        'Comprovação da idade',
        _proofOfAge,
        const {
          'RASTREABILIDADE': 'Rastreabilidade',
          'DENTES': 'Análise dos dentes',
        },
        (value) => setState(() => _proofOfAge = value),
      ),
      const SizedBox(height: 12),
      _dropdown(
        'Cor da carcaça',
        _carcassColor,
        const {
          'VERMELHA_ROSADA': 'Vermelha rosada',
          'OTHER': 'Outra (não conforme)',
        },
        (value) => setState(() => _carcassColor = value),
      ),
      const SizedBox(height: 12),
      _dropdown('Cor da gordura', _fatColor, const {
        'BRANCA': 'Branca',
        'OTHER': 'Outra (não conforme)',
      }, (value) => setState(() => _fatColor = value)),
      const SizedBox(height: 12),
      _dropdown(
        'Textura da carne',
        _meatTexture,
        const {'FINA': 'Fina', 'OTHER': 'Outra (não conforme)'},
        (value) => setState(() => _meatTexture = value),
      ),
      const SizedBox(height: 12),
      _check(
        'Possui Boletim de Embarque',
        _hasBoletimEmbarque,
        (value) => _hasBoletimEmbarque = value,
      ),
      _check('Possui GTA', _hasGTA, (value) => _hasGTA = value),
      _check('Possui HTA', _hasHTA, (value) => _hasHTA = value),
      _check(
        'Bem-estar animal confirmado',
        _confirmWelfare,
        (value) => _confirmWelfare = value,
      ),
      _check(
        'Sanidade confirmada',
        _confirmSanity,
        (value) => _confirmSanity = value,
      ),
      _check(
        'Origem geográfica confirmada',
        _confirmOrigin,
        (value) => _confirmOrigin = value,
      ),
      _check(
        'Jejum pré-abate confirmado',
        _confirmFasting,
        (value) => _confirmFasting = value,
      ),
    ],
  );

  Widget _animalMeasurements(SlaughterAnimal animal) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coleira ${animal.tagId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  _weightControllers[animal.id]!,
                  'Peso (kg)',
                  minimum: 0.01,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  _yieldControllers[animal.id]!,
                  'Rendimento (%)',
                  minimum: 42,
                  maximum: 100,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required double minimum,
    double? maximum,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    decoration: _decoration(label, Icons.scale_outlined),
    validator: (value) {
      final parsed = _parseNumber(value ?? '');
      if (parsed == null || parsed < minimum) {
        return minimum == 42 ? 'Mín. 42%' : 'Peso inválido';
      }
      if (maximum != null && parsed > maximum) return 'Máx. 100%';
      return null;
    },
  );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: _decoration(label, Icons.checklist),
    items: items.entries
        .map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        )
        .toList(),
    onChanged: (value) => onChanged(value!),
  );

  Widget _check(String title, bool value, ValueChanged<bool> update) =>
      CheckboxListTile(
        value: value,
        onChanged: (checked) => setState(() => update(checked ?? false)),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.success,
      );

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    decoration: _decoration(label, icon),
    validator: required
        ? (value) =>
              value == null || value.trim().isEmpty ? 'Campo obrigatório' : null
        : null,
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );

  Widget _notice(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
    ),
  );
}
