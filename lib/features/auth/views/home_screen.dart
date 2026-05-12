import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../../animals/views/animal_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final _authService = AuthService();

  Map<String, dynamic>? _userProfile;

  bool _isLoadingProfile = true;

  final Color primaryTeal =
      const Color(0xFF0F8F82);

  final Color bgGray =
      const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile =
        await _authService.getProfile();

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,

      drawer: _buildDrawer(),

      appBar: AppBar(
        backgroundColor: primaryTeal,

        elevation: 0,

        iconTheme:
            const IconThemeData(
              color: Colors.white,
            ),

        systemOverlayStyle:
            SystemUiOverlayStyle.light,

        title: const Text(
          'SISOV Dashboard',

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),

            onPressed:
                () => HapticFeedback
                    .selectionClick(),
          ),
        ],
      ),

      body: SafeArea(
        child:
            _isLoadingProfile
                ? Center(
                  child:
                      CircularProgressIndicator(
                        color:
                            primaryTeal,
                      ),
                )
                : RefreshIndicator(
                  onRefresh:
                      _loadUserData,

                  color: primaryTeal,

                  child:
                      SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),

                        child: Column(
                          children: [
                            _buildStatHeader(),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                    horizontal:
                                        20.0,
                                    vertical:
                                        24,
                                  ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    "Ações Rápidas",

                                    style:
                                        TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              Color(
                                                0xFF1E293B,
                                              ),
                                        ),
                                  ),

                                  const SizedBox(
                                    height:
                                        16,
                                  ),

                                  _buildQuickActions(),

                                  const SizedBox(
                                    height:
                                        32,
                                  ),

                                  const Text(
                                    "Resumo do Rebanho",

                                    style:
                                        TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              Color(
                                                0xFF1E293B,
                                              ),
                                        ),
                                  ),

                                  const SizedBox(
                                    height:
                                        16,
                                  ),

                                  _buildStatusItem(
                                    "Fêmeas em reprodução",

                                    _userProfile?['femaleCount']
                                            ?.toString()
                                            .padLeft(
                                              2,
                                              '0',
                                            ) ??
                                        "00",

                                    Icons.female,
                                    Colors.pink,
                                  ),

                                  _buildStatusItem(
                                    "Transferências recentes",

                                    _userProfile?['transfersCount']
                                            ?.toString()
                                            .padLeft(
                                              2,
                                              '0',
                                            ) ??
                                        "00",

                                    Icons.swap_horiz,
                                    Colors.blue,
                                  ),

                                  _buildStatusItem(
                                    "Alertas Sanitários",
                                    "00",
                                    Icons
                                        .warning_amber_rounded,
                                    Colors.orange,
                                  ),

                                  _buildStatusItem(
                                    "Finalizados em Tauá",

                                    _userProfile?['activeAnimals']
                                            ?.toString()
                                            .padLeft(
                                              2,
                                              '0',
                                            ) ??
                                        "00",

                                    Icons.verified,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
      ),
    );
  }

  Widget _buildStatHeader() {
    final total =
        _userProfile?['totalAnimals']
            ?.toString() ??
        "0";

    final ativos =
        _userProfile?['activeAnimals']
            ?.toString() ??
        "0";

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),

      decoration: BoxDecoration(
        color: primaryTeal,

        borderRadius:
            const BorderRadius.only(
              bottomLeft:
                  Radius.circular(32),
              bottomRight:
                  Radius.circular(32),
            ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

        children: [
          _buildTopStat(
            "Total Ovinos",
            total,
          ),

          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),

          _buildTopStat(
            "Ativos",
            ativos,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      childAspectRatio: 1.4,

      crossAxisSpacing: 14,

      mainAxisSpacing: 14,

      children: [
        _actionButton(
          "Novo Ovino",
          Icons.add_circle_outline,
          Colors.teal,
          () {
            Navigator.pushNamed(
              context,
              '/select-property',
            );
          },
        ),

        _actionButton(
          "Ler via BLE",
          Icons.bluetooth_searching,
          Colors.blue,
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Leitura BLE em desenvolvimento',
                ),
              ),
            );
          },
        ),

        _actionButton(
          "Transferência",
          Icons.sync_alt,
          Colors.indigo,
          () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder:
                    (_) =>
                        const AnimalSearchScreen(
                          isTransferMode:
                              true,
                        ),
              ),
            );
          },
        ),

        _actionButton(
          "Rebanho",
          Icons.agriculture,
          Colors.green,
          () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder:
                    (_) =>
                        const AnimalSearchScreen(
                          isTransferMode:
                              false,
                        ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopStat(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        Text(
          label,

          style: TextStyle(
            color: Colors.white
                .withValues(
                  alpha: 0.8,
                ),

            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(20),

      child: InkWell(
        onTap: () {
          HapticFeedback
              .mediumImpact();

          onTap();
        },

        borderRadius:
            BorderRadius.circular(20),

        splashColor:
            color.withValues(
              alpha: 0.1,
            ),

        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
                  20,
                ),

            border: Border.all(
              color: const Color(
                0xFFE2E8F0,
              ),
              width: 1.5,
            ),
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                      8,
                    ),

                decoration: BoxDecoration(
                  color:
                      color.withValues(
                        alpha: 0.1,
                      ),

                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                label,

                style:
                    const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                      color: Color(
                        0xFF334155,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
            bottom: 14,
          ),

      child: Material(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        child: InkWell(
          onTap:
              () => HapticFeedback
                  .lightImpact(),

          borderRadius:
              BorderRadius.circular(
                18,
              ),

          child: Container(
            padding:
                const EdgeInsets.all(
                  16,
                ),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                    18,
                  ),

              border: Border.all(
                color: const Color(
                  0xFFF1F5F9,
                ),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                        alpha: 0.02,
                      ),

                  blurRadius: 10,

                  offset:
                      const Offset(0, 4),
                ),
              ],
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                        10,
                      ),

                  decoration: BoxDecoration(
                    color:
                        color.withValues(
                          alpha: 0.1,
                        ),

                    shape:
                        BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child: Text(
                    title,

                    style:
                        const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w600,
                          fontSize: 15,
                          color: Color(
                            0xFF475569,
                          ),
                        ),
                  ),
                ),

                Text(
                  count,

                  style:
                      const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize: 16,
                        color: Color(
                          0xFF1E293B,
                        ),
                      ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Icon(
                  Icons.chevron_right,
                  color: Color(
                    0xFFCBD5E1,
                  ),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: primaryTeal,
            ),

            currentAccountPicture:
                const CircleAvatar(
                  backgroundColor:
                      Colors.white,

                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(
                      0xFF0F8F82,
                    ),
                  ),
                ),

            accountName: Text(
              _userProfile?['name'] ??
                  'Carregando...',

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            accountEmail: Text(
              _userProfile?['email'] ??
                  '',
            ),
          ),

          _drawerItem(
            Icons.agriculture,
            'Minhas Propriedades',
            () => Navigator.pushNamed(
              context,
              '/properties',
            ),
          ),

          _drawerItem(
            Icons.settings_outlined,
            'Configurações',
            () {},
          ),

          const Spacer(),

          const Divider(),

          _drawerItem(
            Icons.logout,
            'Sair da Conta',

            () async {
              await _authService.logout();

              if (mounted) {
                Navigator
                    .pushReplacementNamed(
                      context,
                      '/login',
                    );
              }
            },

            color: Colors.red,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            color ?? primaryTeal,
      ),

      title: Text(
        title,
        style: TextStyle(
          color: color,
        ),
      ),

      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}