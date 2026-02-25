import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class ListaRebanhoScreen extends StatefulWidget {
  const ListaRebanhoScreen({super.key});

  @override
  State<ListaRebanhoScreen> createState() => _ListaRebanhoScreenState();
}

class _ListaRebanhoScreenState extends State<ListaRebanhoScreen> {
  List<Ovino> todosOvinos = []; // Lista original (o "banco de dados")
  List<Ovino> ovinosFiltrados = []; // Lista que aparece na tela
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosDoCache();
    _searchController.addListener(_filtrarOvinos);
  }

  // --- LÓGICA DE CACHE (Persistência) ---

  Future<void> _carregarDadosDoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ovinosJson = prefs.getString('cache_ovinos');

    if (ovinosJson != null) {
      final List<dynamic> decoded = jsonDecode(ovinosJson);
      setState(() {
        todosOvinos = decoded.map((item) => Ovino.fromMap(item)).toList();
        ovinosFiltrados = todosOvinos;
      });
    }
  }

  Future<void> _salvarNoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(todosOvinos.map((o) => o.toMap()).toList());
    await prefs.setString('cache_ovinos', encoded);
  }

  // --- LÓGICA DE BUSCA ---

  void _filtrarOvinos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      ovinosFiltrados = todosOvinos.where((ovino) {
        return ovino.codigo.toLowerCase().contains(query) ||
            ovino.raca.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _adicionarAnimalDummy() {
    final novo = Ovino(
      id: DateTime.now().toString(),
      nome: 'Novo Animal',
      sexo: 'M',
      raca: 'Dorper',
      peso: 50.0,
      codigo: 'OV-${todosOvinos.length + 1000}',
      datanasc: '01/01/2024',
      localizacao: 'Pasto C',
    );
    setState(() {
      todosOvinos.add(novo);
      _filtrarOvinos(); // Atualiza a lista visível
    });
    _salvarNoCache();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gerenciar Rebanho', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(onPressed: _adicionarAnimalDummy, icon: const Icon(Icons.add_chart)),
        ],
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: ovinosFiltrados.isEmpty
                ? const Center(child: Text("Nenhum animal encontrado"))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: ovinosFiltrados.length,
              itemBuilder: (context, index) => _buildCard(ovinosFiltrados[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por ID, raça...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _adicionarAnimalDummy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Ovino ovino) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detalhes_ovino', arguments: ovino),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Icon(Icons.pets, color: Color(0xFF94A3B8), size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ovino.codigo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(ovino.raca, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  const Text('Saudável', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}