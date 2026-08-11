import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';

class AnimalCreateScreen extends StatefulWidget {
  const AnimalCreateScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<AnimalCreateScreen> createState() => _AnimalCreateScreenState();
}

class _AnimalCreateScreenState extends State<AnimalCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalService = AnimalService();
  final _tagController = TextEditingController();
  final _breedController = TextEditingController();
  final _cityController = TextEditingController();
  final _coatColorController = TextEditingController();
  final _birthWeightController = TextEditingController();
  final _weaningWeightController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSex = 'FEMALE';
  DateTime? _birthDate;
  DateTime? _coverageDate;
  DateTime? _lambingDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _offspringOptions = [];
  final Set<String> _offspringIds = {};

  @override
  void initState() {
    super.initState();
    _loadOffspringOptions();
  }

  Future<void> _loadOffspringOptions() async {
    final animals = await _animalService.getAnimals();
    if (!mounted) return;
    setState(() {
      _offspringOptions = animals
          .whereType<Map>()
          .map((animal) => Map<String, dynamic>.from(animal))
          .where((animal) {
            final propertyId =
                animal['propertyId']?.toString() ??
                (animal['property'] is Map
                    ? animal['property']['id']?.toString()
                    : null);
            return propertyId == widget.propertyId &&
                animal['status']?.toString() == 'ACTIVE';
          })
          .toList();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _breedController.dispose();
    _cityController.dispose();
    _coatColorController.dispose();
    _birthWeightController.dispose();
    _weaningWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(2010),
    lastDate: DateTime.now(),
  );

  Future<void> _selectBirthDate() async {
    final value = await _pickDate(_birthDate);
    if (value != null) setState(() => _birthDate = value);
  }

  Future<void> _selectFemaleDate(bool coverage) async {
    final value = await _pickDate(coverage ? _coverageDate : _lambingDate);
    if (value == null) return;
    setState(() {
      if (coverage) {
        _coverageDate = value;
      } else {
        _lambingDate = value;
      }
    });
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      _showMessage('Informe a data de nascimento.', isError: true);
      return;
    }
    if (_selectedSex == 'FEMALE' &&
        _coverageDate != null &&
        _lambingDate != null &&
        _lambingDate!.isBefore(_coverageDate!)) {
      _showMessage(
        'A data do parto não pode ser anterior à cobertura.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final data = <String, dynamic>{
      'tagId': _tagController.text.trim(),
      'propertyId': widget.propertyId,
      'breed': _breedController.text.trim(),
      'sex': _selectedSex,
      'birthDate': _birthDate!.toIso8601String(),
      'birthCity': _cityController.text.trim(),
      if (_coatColorController.text.trim().isNotEmpty)
        'coatColor': _coatColorController.text.trim(),
      if (_number(_birthWeightController.text) != null)
        'birthWeight': _number(_birthWeightController.text),
      if (_number(_weaningWeightController.text) != null)
        'weaningWeight': _number(_weaningWeightController.text),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_selectedSex == 'FEMALE' && _coverageDate != null)
        'coverageDate': _coverageDate!.toIso8601String(),
      if (_selectedSex == 'FEMALE' && _lambingDate != null)
        'lambingDate': _lambingDate!.toIso8601String(),
      if (_selectedSex == 'FEMALE' && _offspringIds.isNotEmpty)
        'offspringIds': _offspringIds.toList(),
    };

    final result = await _animalService.createAnimal(data);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] != true) {
      _showMessage(
        result['message'] ?? 'Não foi possível cadastrar o ovino.',
        isError: true,
      );
      return;
    }
    _showMessage(
      result['queued'] == true
          ? result['message'] ?? 'Cadastro salvo no aparelho.'
          : 'Ovino cadastrado com sucesso!',
    );
    Navigator.popUntil(context, ModalRoute.withName('/home'));
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dados do Ovino'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section('Identificação'),
            _field(
              _tagController,
              'Número da coleira',
              Icons.tag,
              required: true,
              digitsOnly: true,
            ),
            const SizedBox(height: 20),
            _section('Características'),
            Row(
              children: [
                Expanded(
                  child: _sexCard('Fêmea', 'FEMALE', Icons.female, Colors.pink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sexCard('Macho', 'MALE', Icons.male, Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_breedController, 'Raça', Icons.pets, required: true),
            const SizedBox(height: 12),
            _field(
              _coatColorController,
              'Pelagem (opcional)',
              Icons.palette_outlined,
            ),
            const SizedBox(height: 20),
            _section('Nascimento e origem'),
            _dateTile('Data de nascimento', _birthDate, _selectBirthDate),
            const SizedBox(height: 12),
            _field(
              _cityController,
              'Cidade de nascimento',
              Icons.location_city,
              required: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _weightField(
                    _birthWeightController,
                    'Peso ao nascer (kg)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _weightField(
                    _weaningWeightController,
                    'Peso ao desmame (kg)',
                  ),
                ),
              ],
            ),
            if (_selectedSex == 'FEMALE') ...[
              const SizedBox(height: 20),
              _section('Reprodução'),
              _dateTile(
                'Data de cobertura (opcional)',
                _coverageDate,
                () => _selectFemaleDate(true),
              ),
              const SizedBox(height: 12),
              _dateTile(
                'Data do parto (opcional)',
                _lambingDate,
                () => _selectFemaleDate(false),
              ),
              const SizedBox(height: 12),
              _offspringSelector(),
            ],
            const SizedBox(height: 20),
            _section('Observações'),
            _field(
              _notesController,
              'Notas zootécnicas (opcional)',
              Icons.notes,
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Salvando...' : 'Finalizar cadastro'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offspringSelector() {
    if (_offspringOptions.isEmpty) {
      return const Text(
        'Nenhuma cria cadastrada nesta propriedade.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }
    return Card(
      elevation: 0,
      child: ExpansionTile(
        title: const Text('Crias já cadastradas'),
        subtitle: Text('${_offspringIds.length} selecionada(s)'),
        children: _offspringOptions.map((animal) {
          final id =
              animal['sisovId']?.toString() ?? animal['id']?.toString() ?? '';
          final pending =
              id.startsWith('local_') ||
              animal['syncStatus']?.toString() == 'PENDING';
          return CheckboxListTile(
            value: _offspringIds.contains(id),
            onChanged: pending
                ? (_) => _showMessage(
                    'Esta cria ainda aguarda sincronização. Envie o cadastro '
                    'antes de vinculá-la.',
                    isError: true,
                  )
                : (checked) => setState(() {
                    checked == true
                        ? _offspringIds.add(id)
                        : _offspringIds.remove(id);
                  }),
            title: Text('Coleira ${animal['tagId'] ?? 'N/A'}'),
            subtitle: pending ? const Text('Aguardando sincronização') : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _decoration(label, Icons.calendar_month),
          child: Text(
            value == null
                ? 'Selecionar'
                : '${value.day.toString().padLeft(2, '0')}/'
                      '${value.month.toString().padLeft(2, '0')}/${value.year}',
          ),
        ),
      );

  Widget _weightField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        decoration: _decoration(label, Icons.scale_outlined),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          final parsed = _number(value);
          return parsed == null || parsed <= 0 ? 'Peso inválido' : null;
        },
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool digitsOnly = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
    inputFormatters: digitsOnly
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    decoration: _decoration(label, icon),
    validator: required
        ? (value) =>
              value == null || value.trim().isEmpty ? 'Campo obrigatório' : null
        : null,
  );

  Widget _sexCard(String label, String value, IconData icon, Color color) {
    final selected = _selectedSex == value;
    return InkWell(
      onTap: () => setState(() {
        _selectedSex = value;
        if (value == 'MALE') {
          _coverageDate = null;
          _lambingDate = null;
          _offspringIds.clear();
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    ),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
