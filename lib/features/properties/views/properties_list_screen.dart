import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../models/property_model.dart';
import '../services/property_service.dart';
import '../../animals/views/receive_animal_screen.dart';

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
  final _propertyService =
      PropertyService();


  // Simulação do perfil carregado
  // Idealmente isso vem do AuthService
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();

    // Exemplo mock
    // Troque pelo seu carregamento real
    _userProfile = {
      'id': 'USER_ID_LOGADO',
    };
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
                    'Nenhuma fazenda cadastrada.\nClique no + para começar.',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      color:
                          Colors.grey,
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
                        '${item.city} - ${item.state}',
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

                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          ReceiveAnimalScreen(
                                            producerId:
                                                _userProfile!['id'],

                                            propertyId:
                                                item.id,

                                            farmName:
                                                item.farmName,
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