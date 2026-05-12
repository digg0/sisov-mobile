import 'package:flutter/material.dart';
import '../services/property_service.dart';
import '../models/property_model.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  final _propertyService = PropertyService();
  final Color primaryTeal = const Color(0xFF0F8F82);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Minhas Fazendas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // BOTÃO REDONDO (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryTeal,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          // Quando clicado, abre a tela de cadastro
          Navigator.pushNamed(context, '/properties/add').then((value) {
            if (value == true) setState(() {}); // Recarrega a lista se salvou algo
          });
        },
      ),

      body: FutureBuilder<List<PropertyModel>>(
        future: _propertyService.getProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma fazenda cadastrada.\nClique no + para começar.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          final properties = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: primaryTeal.withOpacity(0.1),
                    child: Icon(Icons.location_on, color: primaryTeal),
                  ),
                  title: Text(item.farmName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.city} - ${item.state}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Aqui você pode salvar qual fazenda foi selecionada para o Dashboard
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