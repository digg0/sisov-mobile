import 'package:flutter/material.dart';
import 'home_screen.dart';

class DetalhesOvinoScreen extends StatelessWidget {
  const DetalhesOvinoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Captura o objeto passado via argumentos
    final ovino = ModalRoute.of(context)!.settings.arguments as Ovino;

    return Scaffold(
      appBar: AppBar(title: Text('Perfil: ${ovino.codigo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0D9488), child: Icon(Icons.pets, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            _infoTile('Nome', ovino.nome),
            _infoTile('Raça', ovino.raca),
            _infoTile('Peso Atual', '${ovino.peso} kg'),
            _infoTile('Nascimento', ovino.datanasc),
            _infoTile('Localização', ovino.localizacao),
            _infoTile('Sexo', ovino.sexo == 'M' ? 'Macho' : 'Fêmea'),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
    );
  }
}