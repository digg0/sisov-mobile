import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database_helper.dart';
import '../ovino_model.dart';

class ListaRebanhoScreen extends StatefulWidget {
  const ListaRebanhoScreen({super.key});

  @override
  State<ListaRebanhoScreen> createState() => _ListaRebanhoScreenState();
}

class _ListaRebanhoScreenState extends State<ListaRebanhoScreen> {
  // --- DECLARAÇÃO DAS VARIÁVEIS ---
  List<Ovino> ovinos = [];
  List<Ovino> filtrados = [];
  bool _estaSincronizando = false; // AQUI ESTAVA O ERRO: Faltava declarar

  final TextEditingController _buscaController = TextEditingController();
  final Color primaryTeal = const Color(0xFF0F8F82);

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _buscaController.addListener(_filtrar);
  }

  Future<void> _carregarDados() async {
    final list = await DatabaseHelper.instance.getOvinos();
    setState(() {
      ovinos = list.map((m) => Ovino.fromMap(m)).toList();
      filtrados = ovinos;
    });
  }

  void _filtrar() {
    setState(() {
      filtrados = ovinos.where((o) =>
      o.tagId.toLowerCase().contains(_buscaController.text.toLowerCase()) ||
          o.raca.toLowerCase().contains(_buscaController.text.toLowerCase())
      ).toList();
    });
  }

  void _iniciarSincronizacao() async {
    setState(() => _estaSincronizando = true);
    // Simula sincronismo com banco robusto
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _estaSincronizando = false);
    _showToast("Sincronização concluída!");
  }

  void _mostrarModalCadastro() {
    final controllers = {
      'tag': TextEditingController(),
      'raca': TextEditingController(),
      'data': TextEditingController(),
      'mun': TextEditingController(),
      'est': TextEditingController(),
      'peso': TextEditingController(),
      'pai': TextEditingController(),
      'mae': TextEditingController(),
    };
    String sexo = 'M';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Novo Cadastro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTeal)),
                          const SizedBox(height: 25),
                          _input(controllers['tag']!, "Tag ID ", Icons.qr_code_scanner),
                          const Text("Sexo do Animal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _botaoSexo("Macho", 'M', sexo, (v) => setModalState(() => sexo = v)),
                              const SizedBox(width: 12),
                              _botaoSexo("Fêmea", 'F', sexo, (v) => setModalState(() => sexo = v)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _input(controllers['raca']!, "Raça", Icons.pets),
                          _input(controllers['data']!, "Data de Nascimento", Icons.calendar_today, keyboard: TextInputType.datetime),
                          Row(
                            children: [
                              Expanded(child: _input(controllers['mun']!, "Município", Icons.location_city)),
                              const SizedBox(width: 10),
                              Expanded(child: _input(controllers['est']!, "Estado (UF)", Icons.map)),
                            ],
                          ),
                          _input(controllers['peso']!, "Peso Nasc. (kg)", Icons.scale, keyboard: TextInputType.number),
                          const Divider(height: 40),
                          const Text("Genealogia", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _input(controllers['pai']!, "ID do Pai (Opcional)", Icons.male),
                          _input(controllers['mae']!, "ID da Mãe (Opcional)", Icons.female),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (controllers['tag']!.text.isEmpty) {
                            _showToast("O Tag ID é obrigatório");
                            return;
                          }
                          final novo = Ovino(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            tagId: controllers['tag']!.text,
                            sexo: sexo,
                            raca: controllers['raca']!.text,
                            dataNasc: controllers['data']!.text,
                            municipio: controllers['mun']!.text,
                            estado: controllers['est']!.text,
                            pesoNasc: double.tryParse(controllers['peso']!.text.replaceAll(',', '.')) ?? 0.0,
                            pai: controllers['pai']!.text,
                            mae: controllers['mae']!.text,
                          );
                          await DatabaseHelper.instance.insertOvino(novo.toMap());
                          _carregarDados();
                          Navigator.pop(context);
                        },
                        child: const Text("SALVAR ANIMAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoSexo(String label, String value, String selecionado, Function(String) onTab) {
    bool ativo = selecionado == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTab(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 55,
          decoration: BoxDecoration(
            color: ativo ? primaryTeal : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ativo ? primaryTeal : Colors.transparent),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: ativo ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryTeal, size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SISOV Rebanho", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryTeal,
        elevation: 0,
        actions: [
          _estaSincronizando
              ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal)
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _iniciarSincronizacao,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: "Buscar por Tag ou Raça...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? Center(child: Text("Nenhum animal encontrado", style: TextStyle(color: Colors.grey[400])))
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtrados.length,
              itemBuilder: (context, i) => _buildCard(filtrados[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalCadastro,
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CADASTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCard(Ovino o) {
    return GestureDetector(
      onTap: () {
        // NAVEGAÇÃO PARA DETALHES
        Navigator.pushNamed(
            context,
            '/detalhes_ovino',
            arguments: o
        );
      },
      onLongPress: () => _confirmarDeletar(o),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Icon(Icons.pets, color: primaryTeal, size: 35),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(o.tagId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(o.raca, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _confirmarDeletar(Ovino o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remover Animal?"),
        content: Text("Deseja apagar o animal ${o.tagId} permanentemente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteOvino(o.id);
                _carregarDados();
                Navigator.pop(ctx);
              },
              child: const Text("Sim, Apagar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}