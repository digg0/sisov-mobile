import 'package:flutter/material.dart';


class Ovino {
  final String id;
  final String nome;
  final String sexo;
  final String raca;
  final double peso;
  final String codigo;
  final String datanasc;
  final String localizacao;

  Ovino({
    required this.id,
    required this.nome,
    required this.sexo,
    required this.raca,
    required this.peso,
    required this.codigo,
    required this.datanasc,
    required this.localizacao
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ovino> listaOvinos = [];

  final Color tealColor = const Color(0xFF0D9488);
  final Color slateColor = const Color(0xFF64748B);
  final Color darkSlate = const Color(0xFF0F172A);

  Future<void> _atualizarDados() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {

      listaOvinos = [

      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: tealColor,
        onRefresh: _atualizarDados,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildTopDashboard()),

            // Cabeçalho da Lista
            SliverToBoxAdapter(
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
                    Text('Produções Recentes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    Icon(Icons.filter_list, size: 20, color: slateColor),
                  ],
                ),
              ),
            ),

            // Lista ou Empty State
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: listaOvinos.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildListItem(listaOvinos[index], index == listaOvinos.length - 1),
                  childCount: listaOvinos.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Ovino item, bool isLast) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
                backgroundColor: tealColor.withOpacity(0.1),
                child: Icon(Icons.pets, color: tealColor, size: 18)),

            title: Text(item.codigo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${item.raca} • ${item.peso}kg • ${item.localizacao}', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {

            },
          ),
          if (!isLast) const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
          if (isLast)
            Container(
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            ),
        ],
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _statCard(listaOvinos.length.toString(), 'Total Animais', Icons.analytics_outlined, tealColor),
                _statCard('0%', 'Saúde', Icons.favorite_border, Colors.blue),
                _statCard('01/01', 'Vacina', Icons.medical_services_outlined, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Ações Rápidas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionBtn('Novo', Icons.add_circle, tealColor, true),
              _actionBtn('Gerenciar', Icons.group_outlined, slateColor, false),
              _actionBtn('Vacinar', Icons.vaccines_outlined, slateColor, false),
              _actionBtn('Gerar QR', Icons.qr_code_2_outlined, slateColor, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color col) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: col, size: 22), const SizedBox(height: 12),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkSlate)),
        Text(label, style: TextStyle(color: slateColor, fontSize: 12)),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color col, bool primary) {
    return Column(children: [
      Container(
        width: 62, height: 62,
        decoration: BoxDecoration(
          color: primary ? col : Colors.white, borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: primary ? [BoxShadow(color: col.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(icon, color: primary ? Colors.white : col, size: 26),
      ),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: darkSlate)),
    ]);
  }

  Widget _buildEmptyState() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: slateColor.withOpacity(0.3), size: 40),
            const SizedBox(height: 8),
            Text('Nenhum registro encontrado.\nPuxe para atualizar.',
                textAlign: TextAlign.center, style: TextStyle(color: slateColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC), surfaceTintColor: Colors.transparent, elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Center(
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCCFBF1))),
            child: Icon(Icons.pets, color: tealColor, size: 20),
          ),
        ),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SISOV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
        Text('Sistema de Rastreabilidade', style: TextStyle(fontSize: 11, color: slateColor)),
      ]),
      actions: [
        IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: Icon(Icons.logout_rounded, color: slateColor, size: 22)),
        const SizedBox(width: 10),
      ],
    );
  }
}