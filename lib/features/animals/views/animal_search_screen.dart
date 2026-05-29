import 'package:flutter/material.dart';
import '../services/animal_service.dart';
import 'animal_details_screen.dart'; // Importa a nova tela!

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

  final Color primaryTeal = const Color(0xFF0F8F82);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.showSlaughtered
              ? 'Finalizados / Abatidos'
              : widget.isTransferMode
                  ? 'Transferência'
                  : 'Meu Rebanho',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Área de Busca no Topo (Agora funciona como filtro em tempo real)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryTeal,
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
              ? Center(child: CircularProgressIndicator(color: primaryTeal))
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
            ),
            subtitle: Text(animal['breed'] ?? 'Raça não informada'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnimalDetailsScreen(animal: animal)),
              );
            },
          ),
        );
      },
    );
  }
}