import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddVacinacaoScreen extends StatefulWidget {
  const AddVacinacaoScreen({super.key});

  @override
  State<AddVacinacaoScreen> createState() => _AddVacinacaoScreenState();
}

class _AddVacinacaoScreenState extends State<AddVacinacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataController = TextEditingController();
  final _loteController = TextEditingController();

  Future<void> _salvarVacina() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // 1. Ler o que já existe no cache
      final String? cacheExistente = prefs.getString('cache_vacinacao');
      List<dynamic> listaVacinas = cacheExistente != null ? jsonDecode(cacheExistente) : [];

      // 2. Criar o novo registo
      Map<String, dynamic> novaVacina = {
        'id': DateTime.now().toIso8601String(),
        'nome': _nomeController.text,
        'data': _dataController.text,
        'lote': _loteController.text,
      };

      // 3. Adicionar à lista e guardar
      listaVacinas.add(novaVacina);
      await prefs.setString('cache_vacinacao', jsonEncode(listaVacinas));

      // 4. Voltar para a tela anterior
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registar Vacina')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Vacina', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data da Aplicação', prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  // Abre um seletor de data
                  DateTime? picked = await showDatePicker(
                      context: context, initialDate: DateTime.now(),
                      firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) _dataController.text = "${picked.day}/${picked.month}/${picked.year}";
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _loteController,
                decoration: const InputDecoration(labelText: 'Lote / Fabricante'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvarVacina,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('SALVAR REGISTO', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}