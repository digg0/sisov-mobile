import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/animal_service.dart';

class AnimalSearchScreen extends StatefulWidget {
  const AnimalSearchScreen({super.key});

  @override
  State<AnimalSearchScreen> createState() => _AnimalSearchScreenState();
}

class _AnimalSearchScreenState extends State<AnimalSearchScreen> {
  final _searchController = TextEditingController();
  final _animalService = AnimalService();

  bool _isLoading = false;
  Map<String, dynamic>? _animalData; // Guarda os dados do animal se encontrado
  String? _errorMessage;

  final Color primaryTeal = const Color(0xFF0F8F82);

  void _searchAnimal() async {
    final identifier = _searchController.text.trim();
    if (identifier.isEmpty) return;

    FocusScope.of(context).unfocus(); // Esconde o teclado

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _animalData = null;
    });

    final result = await _animalService.getAnimal(identifier);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _animalData = result['data'];
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ficha do Animal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Área de Busca no Topo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Digite o número do Brinco',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _searchAnimal(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _searchAnimal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: _isLoading
                        ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.arrow_forward_ios, color: primaryTeal, size: 20),
                  ),
                )
              ],
            ),
          ),

          // Área de Resultados
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildResultArea(),
            ),
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
            const SizedBox(height: 40),
            const Icon(Icons.search_off, size: 80, color: Colors.black26),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_animalData != null) {
      return _buildAnimalProfile(_animalData!);
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Text(
          'Busque por um brinco para ver a ficha completa.',
          style: TextStyle(color: Colors.black45, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimalProfile(Map<String, dynamic> animal) {
    // Formatação de dados
    final isMale = animal['sex'] == 'MALE';
    final statusCor = animal['status'] == 'ACTIVE' ? Colors.green : Colors.red;

    // Tentativa simples de formatar data (se falhar, mostra o original)
    String dataNasc = animal['birthDate'] ?? '';
    try {
      final date = DateTime.parse(dataNasc);
      dataNasc = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: statusCor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(
            animal['status'] == 'ACTIVE' ? '🟢 ATIVO NA PROPRIEDADE' : '🔴 ABATIDO/INATIVO',
            style: TextStyle(color: statusCor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Card Principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isMale ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
                    child: Icon(isMale ? Icons.male : Icons.female, color: isMale ? Colors.blue : Colors.pink, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brinco: ${animal['tagId'] ?? 'N/A'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text(animal['breed'] ?? 'Raça não informada', style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

              _infoRow(Icons.cake, 'Nascimento', dataNasc),
              const SizedBox(height: 12),
              _infoRow(Icons.location_city, 'Local de Nascimento', animal['birthCity'] ?? ''),
              const SizedBox(height: 12),
              _infoRow(Icons.agriculture, 'Propriedade Atual', animal['property']?['farmName'] ?? 'Desconhecida'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Aqui futuramente colocaremos os botões de Ações:
        // "Transferir", "Abater" e "Ver Histórico".
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14))),
        Text(value, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}