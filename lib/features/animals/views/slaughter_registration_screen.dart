import 'package:flutter/material.dart';

import '../../../core/location/location_capture_field.dart';
import '../../../core/location/location_service.dart';
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
  final _slaughterhouseCodeController = TextEditingController();
  final _notesController = TextEditingController();

  SlaughterMode _mode = SlaughterMode.standard;
  DateTime _slaughterDate = DateTime.now();
  LocationSnapshot? _slaughterLocation;
  bool _submitting = false;

  @override
  void dispose() {
    _slaughterhouseCodeController.dispose();
    _notesController.dispose();
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
        slaughterLocation: _slaughterLocation?.label ?? '',
        location: _slaughterLocation?.toJson(),
        frigorificoCode: _mode == SlaughterMode.igSlaughterhouse
            ? _slaughterhouseCodeController.text.trim()
            : null,
        additionalNotes: _notesController.text.trim(),
      ),
      items: widget.animals
          .map((animal) => SlaughterBatchItem(animalId: animal.id))
          .toList(),
    );
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    final request = _buildRequest();
    final error = request.validate();
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
              _reviewLine('Modalidade', _mode.label),
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
              _reviewLine(
                'Local',
                _slaughterLocation?.label ?? 'Não capturado',
              ),
              if (_mode == SlaughterMode.igSlaughterhouse)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'O registro ficará pendente de validação pelo abatedouro.',
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
        ? 'Abate enviado e aguardando validação do abatedouro.'
        : 'Abate padrão registrado com sucesso.';
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
            LocationCaptureField(
              title: 'Localização do abate',
              onChanged: (value) => _slaughterLocation = value,
            ),
            if (_mode == SlaughterMode.igSlaughterhouse) ...[
              const SizedBox(height: 12),
              _textField(
                _slaughterhouseCodeController,
                'Código SIF / SIE / SIM do abatedouro',
                Icons.business_outlined,
                required: true,
              ),
              const SizedBox(height: 12),
              _notice(
                'A análise da IG será feita pelo abatedouro. Até a validação, '
                'os animais ficarão com abate pendente.',
              ),
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
    final description = mode == SlaughterMode.standard
        ? 'Abate por conta própria, sem IG e com finalização imediata.'
        : 'A IG será analisada e validada exclusivamente pelo abatedouro.';
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
        subtitle: Text(description),
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
