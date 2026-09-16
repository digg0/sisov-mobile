import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';

class AnimalDeathReportScreen extends StatefulWidget {
  const AnimalDeathReportScreen({
    super.key,
    required this.animalId,
    required this.tagId,
  });

  final String animalId;
  final String tagId;

  @override
  State<AnimalDeathReportScreen> createState() =>
      _AnimalDeathReportScreenState();
}

class _AnimalDeathReportScreenState extends State<AnimalDeathReportScreen> {
  static const _causes = <String, String>{
    'DISEASE': 'Doença',
    'PREDATOR_ATTACK': 'Ataque de predador',
    'ACCIDENT': 'Acidente',
    'POISONING': 'Intoxicação',
    'UNKNOWN': 'Causa desconhecida',
    'OTHER': 'Outra causa',
  };

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _animalService = AnimalService();
  DateTime _deathDate = DateTime.now();
  String _cause = 'DISEASE';
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deathDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data da morte',
    );
    if (selected != null) setState(() => _deathDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final result = await _animalService.reportDeath(
      animalId: widget.animalId,
      deathDate: _deathDate,
      cause: _cause,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      final queued = result['queued'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            queued
                ? 'Morte salva no aparelho e aguardando sincronização.'
                : 'Morte comunicada com sucesso.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              'Não foi possível comunicar a morte.',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_deathDate.day.toString().padLeft(2, '0')}/'
        '${_deathDate.month.toString().padLeft(2, '0')}/${_deathDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicar morte'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Animal: ${widget.tagId}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Data da morte'),
                subtitle: Text(formattedDate),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _submitting ? null : _selectDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _cause,
                decoration: const InputDecoration(
                  labelText: 'Causa da morte',
                  border: OutlineInputBorder(),
                ),
                items: _causes.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _cause = value ?? _cause),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                enabled: !_submitting,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: _cause == 'OTHER'
                      ? 'Descrição da causa *'
                      : 'Observações (opcional)',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_cause == 'OTHER' && (value?.trim().isEmpty ?? true)) {
                    return 'Descreva a causa da morte.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.report_outlined),
                label: const Text('Confirmar comunicação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
