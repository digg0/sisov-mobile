import 'package:flutter/material.dart';
import '../../properties/services/property_service.dart';
import '../../properties/models/property_model.dart'; // Importe o model aqui
import 'animal_create_screen.dart';

class SelectPropertyForAnimalScreen extends StatelessWidget {
  const SelectPropertyForAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyService = PropertyService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Fazenda', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8F82),
      ),
      // Tipamos o FutureBuilder para esperar uma lista de PropertyModel
      body: FutureBuilder<List<PropertyModel>>(
        future: propertyService.getProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar fazendas: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhuma fazenda encontrada."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              // Aqui está a mágica: prop agora é um objeto da sua classe PropertyModel
              final prop = snapshot.data![index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A0F8F82),
                    child: Icon(Icons.agriculture, color: Color(0xFF0F8F82)),
                  ),
                  // Acesso via ponto (.) em vez de colchetes ([])
                  title: Text(
                      prop.farmName,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text("${prop.city} - ${prop.state}"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalCreateScreen(
                          propertyId: prop.id!, // Passando o ID do objeto
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}