import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../models/property_model.dart';
import '../services/property_service.dart';
import '../../animals/views/receive_animal_screen.dart';
import '../../auth/services/auth_service.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  final _propertyService = PropertyService();
  final _authService = AuthService();

  Map<String, dynamic>? _userProfile;
  late Future<List<PropertyModel>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _propertyService.getProperties();
    _loadUserProfile();
  }

  void _refreshProperties() {
    setState(() {
      _propertiesFuture = _propertyService.getProperties();
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  Future<void> _editPropertyName(PropertyModel property) async {
    final controller = TextEditingController(text: property.farmName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nome da propriedade'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome da fazenda',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length < 2) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName == property.farmName || !mounted) return;

    final result = await _propertyService.updatePropertyName(
      property: property,
      farmName: newName,
    );
    if (!mounted) return;
    _showResult(result, successMessage: 'Nome da propriedade atualizado.');
    if (result['success'] == true) _refreshProperties();
  }

  Future<void> _confirmDeleteProperty(PropertyModel property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir propriedade?'),
        content: Text(
          'A propriedade “${property.farmName}” será excluída. '
          'Propriedades com animais cadastrados não podem ser removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await _propertyService.deleteProperty(property);
    if (!mounted) return;
    _showResult(result, successMessage: 'Propriedade excluída.');
    if (result['success'] == true) _refreshProperties();
  }

  void _showResult(
    Map<String, dynamic> result, {
    required String successMessage,
  }) {
    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : result['message']?.toString() ??
                    'Não foi possível concluir a operação.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Minhas Fazendas',

          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        backgroundColor: AppColors.primary,

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // BOTÃO FLUTUANTE
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          Navigator.pushNamed(context, '/properties/add').then((value) {
            if (value == true) {
              _refreshProperties();
            }
          });
        },
      ),

      body: FutureBuilder<List<PropertyModel>>(
        future: _propertiesFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma fazenda ainda.\nToque no botão + para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
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

                  side: const BorderSide(color: AppColors.border),
                ),

                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),

                    child: Icon(Icons.location_on, color: AppColors.primary),
                  ),

                  title: Text(
                    item.farmName,

                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    '${item.city} • ${item.state}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  trailing: SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Receber animal por QR Code',
                          icon: const Icon(
                            Icons.qr_code_2,
                            color: AppColors.primary,
                          ),
                          onPressed: _userProfile == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReceiveAnimalScreen(
                                        producerId:
                                            (_userProfile!['id'] ??
                                                    _userProfile!['_id'] ??
                                                    '')
                                                .toString(),
                                        propertyId: item.id,
                                        farmName: item.farmName,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Gerenciar propriedade',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _editPropertyName(item);
                            } else if (action == 'delete') {
                              _confirmDeleteProperty(item);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Editar nome'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
