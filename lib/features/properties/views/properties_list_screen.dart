import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../models/property_model.dart';
import '../services/property_service.dart';
import '../../animals/views/receive_animal_screen.dart';
import '../../auth/services/auth_service.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({
    super.key,
  });

  @override
  State<PropertiesListScreen>
  createState() =>
      _PropertiesListScreenState();
}

class _PropertiesListScreenState
    extends State<
      PropertiesListScreen
    > {
  final _propertyService = PropertyService();
  final _authService = AuthService();

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Minhas Fazendas',

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            AppColors.primary,

        iconTheme:
            const IconThemeData(
              color: Colors.white,
            ),
      ),

      // BOTÃO FLUTUANTE
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/properties/add',
          ).then((value) {
            if (value == true) {
              setState(() {});
            }
          });
        },
      ),

      body:
          FutureBuilder<
            List<PropertyModel>
          >(
            future:
                _propertyService
                    .getProperties(),

            builder: (
              context,
              snapshot,
            ) {
              if (snapshot
                      .connectionState ==
                  ConnectionState
                      .waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData ||
                  snapshot
                      .data!
                      .isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma fazenda ainda.\nToque no botão + para começar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final properties =
                  snapshot.data!;

              return ListView.builder(
                padding:
                    const EdgeInsets.all(
                      16,
                    ),

                itemCount:
                    properties.length,

                itemBuilder: (
                  context,
                  index,
                ) {
                  final item =
                      properties[index];

                  return Card(
                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                16,
                              ),

                          side:
                              const BorderSide(
                                color: AppColors.border,
                              ),
                        ),

                    margin:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),

                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(
                            16,
                          ),

                      leading:
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withOpacity(
                                  0.1,
                                ),

                            child: Icon(
                              Icons
                                  .location_on,

                              color:
                                  AppColors.primary,
                            ),
                          ),

                      title: Text(
                        item.farmName,

                        style:
                            const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),

                      subtitle: Text(
                        '${item.city} • ${item.state}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),

                      // BOTÃO QR CODE
                      trailing:
                          IconButton(
                            icon:
                                const Icon(
                                  Icons
                                      .qr_code_2,

                                  color:
                                      AppColors.primary,
                                ),

                            onPressed: _userProfile == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReceiveAnimalScreen(
                                          producerId: (_userProfile!['id'] ?? _userProfile!['_id'] ?? '').toString(),
                                          propertyId: item.id,
                                          farmName: item.farmName,
                                        ),
                                      ),
                                    );
                                  },
                          ),

                      onTap: () {
                        // Aqui você pode
                        // selecionar fazenda
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