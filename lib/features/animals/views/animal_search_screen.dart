import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/slaughter_registration_model.dart';
import '../services/animal_service.dart';
import 'animal_death_report_screen.dart';
import 'animal_details_screen.dart';
import 'qr_scanner_screen.dart';
import 'slaughter_registration_screen.dart';

class AnimalSearchScreen extends StatefulWidget {
  const AnimalSearchScreen({
    super.key,
    required this.isTransferMode,
    this.showSlaughtered = false,
    this.showDead = false,
    this.isSlaughterMode = false,
    this.isDeathMode = false,
  });

  final bool isTransferMode;
  final bool showSlaughtered;
  final bool showDead;
  final bool isSlaughterMode;
  final bool isDeathMode;

  @override
  State<AnimalSearchScreen> createState() => _AnimalSearchScreenState();
}

class _AnimalSearchScreenState extends State<AnimalSearchScreen> {
  final _searchController = TextEditingController();
  final _animalService = AnimalService();

  bool _isLoading = true;
  List<dynamic> _allAnimals = [];
  List<dynamic> _filteredAnimals = [];
  String? _errorMessage;
  final Set<String> _selectedAnimalIds = {};

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _animalService.getAnimals();
      final loadedAnimals = data.where((animal) {
        final status = animal['status']?.toString().toUpperCase() ?? '';
        if (widget.showSlaughtered) {
          return status == 'SLAUGHTERED' || status == 'SLAUGHTER_PENDING';
        }
        if (widget.showDead) return status == 'DEAD';
        return status == 'ACTIVE';
      }).toList();

      setState(() {
        _allAnimals = loadedAnimals;
        _filteredAnimals = loadedAnimals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao carregar o rebanho.";
        _isLoading = false;
      });
    }
  }

  void _filterAnimals(String query) {
    if (query.isEmpty) {
      setState(() => _filteredAnimals = _allAnimals);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredAnimals = _allAnimals.where((animal) {
        final tag = animal['tagId']?.toString().toLowerCase() ?? '';
        final breed = animal['breed']?.toString().toLowerCase() ?? '';
        return tag.contains(lowerQuery) || breed.contains(lowerQuery);
      }).toList();
    });
  }

  Future<String?> _getAnimalId(Map<String, dynamic> animal) async {
    final String? id = animal['sisovId']?.toString();
    if (id != null && id.isNotEmpty) return id;

    final String? fallbackId = animal['id']?.toString();
    if (fallbackId != null && fallbackId.isNotEmpty) return fallbackId;

    final String? underscoreId = animal['_id']?.toString();
    if (underscoreId != null && underscoreId.isNotEmpty) return underscoreId;

    final String? animalId = animal['animalId']?.toString();
    if (animalId != null && animalId.isNotEmpty) return animalId;

    return null;
  }

  Future<void> _openSlaughterBatch() async {
    final selected = _allAnimals
        .where((animal) {
          final id =
              animal['sisovId']?.toString() ?? animal['id']?.toString() ?? '';
          return _selectedAnimalIds.contains(id);
        })
        .map(
          (animal) =>
              SlaughterAnimal.fromMap(Map<String, dynamic>.from(animal as Map)),
        )
        .toList();
    if (selected.isEmpty) return;
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SlaughterRegistrationScreen(animals: selected),
      ),
    );
    if (!mounted) return;
    if (completed == true) Navigator.pop(context, true);
  }

  Future<void> _openDeathReport(Map<String, dynamic> animal) async {
    final animalId = await _getAnimalId(animal);
    if (!mounted) return;
    if (animalId == null || animalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar este animal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDeathReportScreen(
          animalId: animalId,
          tagId: animal['tagId']?.toString() ?? 'Animal',
        ),
      ),
    );
    if (!mounted) return;
    if (completed == true) Navigator.pop(context, true);
  }

  Future<void> _transferSelectedAnimals() async {
    if (_selectedAnimalIds.isEmpty) return;
    final animalIds = _selectedAnimalIds.toList(growable: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (!mounted) return;

    Map<String, dynamic>? destinationData;
    if (result is Map<String, dynamic>) {
      destinationData = result;
    } else if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic>) {
          destinationData = decoded;
        }
      } catch (_) {
        destinationData = null;
      }
    }

    if (destinationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR inválido para transferência'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final destinationProducerId =
        destinationData['producerId']?.toString() ?? '';
    final destinationPropertyId =
        destinationData['propertyId']?.toString() ?? '';

    if (destinationProducerId.isEmpty || destinationPropertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR de destino não contém produtor ou propriedade válidos',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await _animalService.transferAnimalsBatch(
        animalIds: animalIds,
        destinationPropertyId: destinationPropertyId,
        destinationProducerId: destinationProducerId,
      );

      if (!mounted) return;

      if (success['success']) {
        final queued = success['queued'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              queued
                  ? (success['message'] ??
                        'Transferência em lote salva no aparelho. Será enviada quando houver internet.')
                  : '✓ ${animalIds.length} animal(is) transferido(s) com sucesso!',
            ),
            backgroundColor: queued ? Colors.orange : Colors.green,
          ),
        );
        // Retorna true para o home screen contabilizar a transferência
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success['message'] ?? 'Erro na transferência'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar transferência: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.showSlaughtered
              ? 'Abatidos / Pendentes'
              : widget.showDead
              ? 'Animais mortos'
              : widget.isSlaughterMode
              ? 'Selecionar animais'
              : widget.isDeathMode
              ? 'Comunicar morte'
              : widget.isTransferMode
              ? 'Selecionar para transferência'
              : 'Meu Rebanho',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Área de Busca no Topo (Agora funciona como filtro em tempo real)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterAnimals,
              decoration: InputDecoration(
                hintText: 'Buscar por coleira ou raça...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Área de Resultados (Lista de todos os animais)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _buildResultArea(),
          ),
        ],
      ),
      bottomNavigationBar: widget.isSlaughterMode || widget.isTransferMode
          ? _buildSelectionBottomBar()
          : null,
    );
  }

  Widget _buildSelectionBottomBar() {
    final selectedCount = _selectedAnimalIds.length;
    final enabled = selectedCount > 0;
    final actionDescription = widget.isSlaughterMode
        ? 'Continuar para registrar o abate'
        : 'Continuar para transferir os animais';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.borderSoft)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          enabled: enabled,
          label: enabled
              ? '$actionDescription. $selectedCount animais selecionados.'
              : 'Selecione pelo menos um animal para continuar.',
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: enabled
                  ? (widget.isSlaughterMode
                        ? _openSlaughterBatch
                        : _transferSelectedAnimals)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                enabled ? 'Continuar ($selectedCount)' : 'Selecione um animal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderSoft,
                disabledForegroundColor: AppColors.textMuted,
                elevation: enabled ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _loadAnimals,
              child: const Text("Tentar novamente"),
            ),
          ],
        ),
      );
    }

    if (_filteredAnimals.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum animal encontrado. Tente outro termo ou volte ao início.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black45, fontSize: 16, height: 1.4),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredAnimals.length,
      itemBuilder: (context, index) {
        final animal = _filteredAnimals[index];
        final isMale = animal['sex'] == 'MALE';
        final id =
            animal['sisovId']?.toString() ?? animal['id']?.toString() ?? '';
        final selected = _selectedAnimalIds.contains(id);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: widget.isSlaughterMode || widget.isTransferMode
                ? Checkbox(
                    value: selected,
                    onChanged: (_) => setState(() {
                      selected
                          ? _selectedAnimalIds.remove(id)
                          : _selectedAnimalIds.add(id);
                    }),
                  )
                : CircleAvatar(
                    backgroundColor: isMale
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.pink.withValues(alpha: 0.1),
                    child: Icon(
                      isMale ? Icons.male : Icons.female,
                      color: isMale ? Colors.blue : Colors.pink,
                    ),
                  ),
            title: Text(
              'Coleira: ${animal['tagId'] ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              widget.showSlaughtered &&
                      animal['status']?.toString() == 'SLAUGHTER_PENDING'
                  ? '${animal['breed'] ?? 'Raça não informada'} · Validação pendente'
                  : animal['syncStatus'] == 'PENDING'
                  ? '${animal['breed'] ?? 'Raça não informada'} · Aguardando envio'
                  : (animal['breed'] ?? 'Raça não informada'),
            ),
            trailing: widget.isSlaughterMode || widget.isTransferMode
                ? null
                : animal['syncStatus'] == 'PENDING'
                ? const Icon(Icons.cloud_upload_outlined, color: Colors.orange)
                : const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              if (widget.isSlaughterMode || widget.isTransferMode) {
                setState(() {
                  selected
                      ? _selectedAnimalIds.remove(id)
                      : _selectedAnimalIds.add(id);
                });
              } else if (widget.isDeathMode) {
                _openDeathReport(Map<String, dynamic>.from(animal as Map));
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnimalDetailsScreen(animal: animal),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
