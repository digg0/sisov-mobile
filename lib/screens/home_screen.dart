import 'package:flutter/material.dart';

// Modelo de Dados (Idealmente em um arquivo separado: models/ovino.dart)
class Ovino {
  final String id, nome, sexo, raca, codigo, datanasc, localizacao;
  final double peso;

  Ovino({
    required this.id, required this.nome, required this.sexo,
    required this.raca, required this.peso, required this.codigo,
    required this.datanasc, required this.localizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'nome': nome, 'sexo': sexo, 'raca': raca,
      'peso': peso, 'codigo': codigo, 'datanasc': datanasc, 'localizacao': localizacao,
    };
  }

  // Converte de Mapa para Objeto (para ler)
  factory Ovino.fromMap(Map<String, dynamic> map) {
    return Ovino(
      id: map['id'], nome: map['nome'], sexo: map['sexo'], raca: map['raca'],
      peso: map['peso'], codigo: map['codigo'], datanasc: map['datanasc'], localizacao: map['localizacao'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ovino> listaOvinos = [];

  // Definição de Cores do Design System
  final Color tealColor = const Color(0xFF0D9488);
  final Color slateColor = const Color(0xFF64748B);
  final Color darkSlate = const Color(0xFF0F172A);
  final Color bgColor = const Color(0xFFF8FAFC);

  Future<void> _atualizarDados() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Aqui você carregaria dados de uma API ou Banco Local
      listaOvinos = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: tealColor,
        onRefresh: _atualizarDados,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildTopDashboard()),
            _buildListHeader(),
            _buildMainContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // --- Widgets de Composição ---

  Widget _buildListHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Produções Recentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
            Icon(Icons.filter_list, size: 20, color: slateColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: listaOvinos.isEmpty
          ? SliverToBoxAdapter(child: _buildEmptyState())
          : SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildListItem(listaOvinos[index], index == listaOvinos.length - 1),
          childCount: listaOvinos.length,
        ),
      ),
    );
  }

  Widget _buildTopDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VISÃO GERAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: slateColor, letterSpacing: 1.1)),
          Text('Painel de Controle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkSlate)),
          const SizedBox(height: 20),
          _buildStatCards(),
          const SizedBox(height: 30),
          Text('Ações Rápidas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
          const SizedBox(height: 15),
          _buildActionGrid(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _statCard(listaOvinos.length.toString(), 'Total Animais', Icons.analytics_outlined, tealColor),
          _statCard('0%', 'Saúde', Icons.favorite_border, Colors.blue),
          _statCard('01/01', 'Vacina', Icons.medical_services_outlined, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _actionBtn('Gerenciar', Icons.pets, tealColor, false, () {
            Navigator.pushNamed(context, '/lista_rebanho');
          }),
          const SizedBox(width: 12), // Espaçamento entre botões
          _actionBtn('Alimentação', Icons.grass, Colors.orange, false, () {
            Navigator.pushNamed(context, '/alimentacao');
          }),
          const SizedBox(width: 12),
          _actionBtn('Vacinas', Icons.vaccines_outlined, Colors.blue, false, () {
            Navigator.pushNamed(context, '/vacinacao');
          }),
          const SizedBox(width: 12),
          _actionBtn('Procedimentos', Icons.phonelink_setup, Colors.purple, false, () {
            Navigator.pushNamed(context, '/procedimentos');
          }),
          const SizedBox(width: 12),
          _actionBtn('Transações', Icons.account_balance_wallet_outlined, Colors.green, false, () {
            Navigator.pushNamed(context, '/transacoes');
          }),
          const SizedBox(width: 20), // Padding extra no final para o bounce
        ],
      ),
    );
  }

  // --- Componentes Atômicos (Botões e Cards) ---

  Widget _actionBtn(String label, IconData icon, Color col, bool isPrimary, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            color: isPrimary ? col : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isPrimary ? null : Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: isPrimary ? [BoxShadow(color: col.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(icon, color: isPrimary ? Colors.white : col, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: darkSlate)),
      ]),
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color col) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9))
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: col, size: 22),
        const SizedBox(height: 12),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate)),
        Text(label, style: TextStyle(color: slateColor, fontSize: 12)),
      ]),
    );
  }

  Widget _buildListItem(Ovino item, bool isLast) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Aumenta a área do clique e o tamanho visual
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tealColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets, color: tealColor, size: 24),
            ),
            title: Text(
                item.codigo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  '${item.raca} • ${item.peso}kg\n${item.localizacao}',
                  style: const TextStyle(fontSize: 13)
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {},
          ),
          if (!isLast) const Divider(height: 1, indent: 80, color: Color(0xFFF1F5F9)),
          if (isLast) const SizedBox(height: 30), // Margem final maior
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300, // Aumentado para dar mais destaque
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone maior para preencher o espaço
            Icon(Icons.inbox_outlined, color: slateColor.withOpacity(0.2), size: 60),
            const SizedBox(height: 16),
            Text(
                'Nenhum registro encontrado',
                style: TextStyle(
                    color: darkSlate,
                    fontSize: 16,
                    fontWeight: FontWeight.w600
                )
            ),
            const SizedBox(height: 8),
            Text(
              'Puxe para atualizar ou adicione novos\nanimais na aba "Gerenciar".',
              textAlign: TextAlign.center,
              style: TextStyle(color: slateColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: bgColor, elevation: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SISOV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
        Text('Sistema de Rastreabilidade', style: TextStyle(fontSize: 11, color: slateColor)),
      ]),
      actions: [
        IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: Icon(Icons.logout_rounded, color: slateColor)),
      ],
    );
  }
}