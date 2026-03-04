import 'package:flutter/material.dart';
import '../ovino_model.dart';

class DetalhesOvinoScreen extends StatelessWidget {
  final Ovino ovino;
  final Color primaryTeal = const Color(0xFF0F8F82);

  const DetalhesOvinoScreen({super.key, required this.ovino});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Ficha do Animal", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryTeal,
        elevation: 0,
        actions: [
          // INDICADOR DE SINCRONIZAÇÃO
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              ovino.sincronizado == 1 ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: ovino.sincronizado == 1 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
      // Ativando o scroll com efeito elástico
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- HEADER: DADOS GERAIS ---
            _buildHeader(),

            // --- GRID DE BOTÕES DE AÇÃO ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Scroll controlado pelo pai
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _actionBtn(Icons.vaccines, "Vacinação"),
                  _actionBtn(Icons.medical_services, "Tratamento"),
                  _actionBtn(Icons.local_shipping, "Movimentação"),
                  _actionBtn(Icons.favorite, "Reprodução"),
                  _actionBtn(Icons.description, "Documentos"),
                  _actionBtn(Icons.timeline, "Linha do\nTempo"),
                ],
              ),
            ),

            // --- INFORMAÇÕES DETALHADAS (Propriedade, Município, etc) ---
            _buildInfoSection("Localização e Status", [
              _infoRow("Propriedade atual", "Não informado"),
              _infoRow("Município atual", "${ovino.municipio} - ${ovino.estado}"),
              _infoRow("Situação Reprodutiva", "Em aberto"),
            ]),

            _buildInfoSection("Detalhes Técnicos", [
              _infoRow("Data Nascimento", ovino.dataNasc),
              _infoRow("Peso Nascimento", "${ovino.pesoNasc} kg"),
              _infoRow("Pai", ovino.pai ?? "Não informado"),
              _infoRow("Mãe", ovino.mae ?? "Não informado"),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget do Topo com Destaque
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.pets, color: primaryTeal, size: 35),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ovino.tagId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(ovino.raca, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 4),
              _badge(ovino.sexo == 'M' ? "MACHO" : "FÊMEA", ovino.sexo == 'M' ? Colors.blue : Colors.pink),
            ],
          )
        ],
      ),
    );
  }

  // Widget dos Botões Quadrados (Design Anterior)
  Widget _actionBtn(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primaryTeal, size: 28),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // Seções de informação
  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 8),
          child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}