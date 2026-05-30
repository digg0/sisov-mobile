import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';
import 'animal_details_screen.dart';
import 'qr_scanner_screen.dart';

class AnimalSearchScreen extends StatefulWidget {
  const AnimalSearchScreen({
    super.key,
    required this.isTransferMode,
    this.showSlaughtered = false,
  });

  final bool isTransferMode;
  final bool showSlaughtered;

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
          return status == 'SLAUGHTERED';
        }
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

  Future<void> _iniciarTransferenciaComDestino(Map<String, dynamic> animal) async {
    final animalId = await _getAnimalId(animal);
    if (animalId == null || animalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID do animal não encontrado'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

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
        const SnackBar(content: Text('QR inválido para transferência'), backgroundColor: Colors.red),
      );
      return;
    }

    final destinationProducerId = destinationData['producerId']?.toString() ?? '';
    final destinationPropertyId = destinationData['propertyId']?.toString() ?? '';

    if (destinationProducerId.isEmpty || destinationPropertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR de destino não contém produtor ou propriedade válidos'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final success = await _animalService.transferAnimal(
        animalId: animalId,
        destinationPropertyId: destinationPropertyId,
        destinationProducerId: destinationProducerId,
      );

      if (!mounted) return;

      if (success['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Transferência concluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
              ? 'Finalizados / Abatidos'
              : widget.isTransferMode
                  ? 'Transferência'
                  : 'Meu Rebanho',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                hintText: 'Buscar por brinco ou raça...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Área de Resultados (Lista de todos os animais)
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildResultArea(),
          ),
        ],
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
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(onPressed: _loadAnimals, child: const Text("Tentar novamente"))
          ],
        ),
      );
    }

    if (_filteredAnimals.isEmpty) {
      return const Center(
        child: Text('Nenhum animal encontrado.', style: TextStyle(color: Colors.black45, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredAnimals.length,
      itemBuilder: (context, index) {
        final animal = _filteredAnimals[index];
        final isMale = animal['sex'] == 'MALE';
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isMale ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
              child: Icon(isMale ? Icons.male : Icons.female, color: isMale ? Colors.blue : Colors.pink),
            ),
            title: Text(
              'Brinco: ${animal['tagId'] ?? 'N/A'}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
            ),
            subtitle: Text(animal['breed'] ?? 'Raça não informada'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              if (widget.isTransferMode) {
                _iniciarTransferenciaComDestino(animal);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AnimalDetailsScreen(animal: animal)),
                );
              }
            },
          ),
        );
      },
    );
  }
}