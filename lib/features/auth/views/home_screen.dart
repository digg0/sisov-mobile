import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../animals/services/animal_service.dart';
import '../../animals/views/animal_search_screen.dart';
import '../../animals/views/animal_details_screen.dart';
import '../../animals/views/qr_scanner_screen.dart';
import '../../properties/views/properties_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _animalService = AnimalService();

  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  int _cachedSlaughteredCount = 0;

  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      // Carrega o count de abatidos separadamente
      final slaughteredCount = await _getSlaughteredCount();
      
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
        _cachedSlaughteredCount = slaughteredCount;
      });
    }
  }

  Future<void> _navTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadUserData();
  }

  void _scanAnimalQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result == null) return;

    String scannedText = result.toString();
    String animalId = "";
    bool isManagementQR = false;

    scannedText = scannedText.trim();

    if (scannedText.contains("sisov://manage/")) {
      animalId = scannedText.replaceAll("sisov://manage/", "").trim();
      isManagementQR = true;
    } else if (scannedText.contains("https://sisov.com.br/rastreabilidade/")) {
      animalId = scannedText.replaceAll("https://sisov.com.br/rastreabilidade/", "").trim();
      isManagementQR = false;
    }

    if (animalId.isNotEmpty) {
      animalId = animalId.replaceAll(" ", "");

      setState(() => _isLoadingProfile = true);
      final res = await _animalService.getAnimal(animalId);

      if (res['success']) {
        final animal = res['data'];
        
        // If it's a management QR code, verify ownership
        if (isManagementQR) {
          final currentUserId = _userProfile?['id']?.toString();
          final animalProducerId = animal['producerId']?.toString() ?? 
                                   animal['property']?['producerId']?.toString();
          
          if (currentUserId == null || currentUserId != animalProducerId) {
            _loadUserData();
            _mostrarErro("Acesso negado: Este animal pertence a outro produtor.");
            return;
          }
        }
        
        _navTo(AnimalDetailsScreen(animal: animal));
      } else {
        _loadUserData();
        _mostrarErro("Animal não localizado.");
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<int> _getSlaughteredCount() async {
    // Primeiro tenta os nomes de campo conhecidos
    final fieldCount = _countProfileValue([
      'slaughteredCount',
      'slaughtered_count',
      'slaughteredAnimalsCount',
      'slaughtered_animals_count',
      'finishedCount',
      'finished_count',
      'finalizadosCount',
      'finalizados_count',
      'slaughterCount',
      'slaughter_count',
      'abatedCount',
      'abated_count',
    ]);

    
    if (fieldCount > 0) return fieldCount;

    
    try {
      final animals = await _animalService.getAnimals();
      final count = animals
          .where((animal) => 
              animal is Map && 
              animal['status'] == 'SLAUGHTERED'
          )
          .length;
      return count;
        } catch (_) {
      
    }

    return 0;
  }

  int _countProfileValue(List<String> keys) {
    if (_userProfile == null) return 0;
    for (final key in keys) {
      final value = _userProfile![key];
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  void _showDebugProfile() {
    final profileJson = _userProfile != null ? _userProfile!.toString() : "Nenhum perfil carregado";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Debug: Perfil Completo"),
        content: SingleChildScrollView(
          child: Text(
            profileJson,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, 
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background, 
        systemNavigationBarIconBrightness: Brightness.dark, 
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Tela Inicial',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => HapticFeedback.selectionClick(),
            ),
          ],
        ),
        
        body: SafeArea(
          
          bottom: true,
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
            onRefresh: _loadUserData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildStatHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BOTÃO DEBUG: Mostra todos os campos do perfil
                        GestureDetector(
                          onLongPress: () => _showDebugProfile(),
                          child: const SizedBox.shrink(),
                        ),
                        const Text(
                          "Ações Rápidas",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        const Text(
                          "Resumo do Rebanho",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          "Fêmeas em reprodução",
                          _countProfileValue([
                            'femaleCount',
                            'female_count',
                            'femalesCount',
                            'females_count',
                            'female_animals_count',
                          ]).toString().padLeft(2, '0'),
                          Icons.female,
                          Colors.pink,
                        ),
                        _buildStatusItem(
                          "Transferências recentes",
                          _countProfileValue([
                            'transfersCount',
                            'transfers_count',
                            'transferCount',
                            'transfer_count',
                          ]).toString().padLeft(2, '0'),
                          Icons.swap_horiz,
                          Colors.blue,
                        ),
                        _buildStatusItem("Alertas Sanitários", "00", Icons.warning_amber_rounded, Colors.orange),
                        _buildStatusItem(
                          "Finalizados (Abatidos)",
                          _cachedSlaughteredCount.toString().padLeft(2, '0'),
                          Icons.verified,
                          Colors.purple,
                          onTap: () {
                            _navTo(const AnimalSearchScreen(
                              isTransferMode: false,
                              showSlaughtered: true,
                            ));
                          },
                        ),
                        // Espaço extra no final para não "colar" na borda inferior do celular
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildStatHeader() {
    final total = _countProfileValue([
      'totalAnimals',
      'total_animals',
      'animalsCount',
      'animals_count',
    ]).toString();
    final ativos = _countProfileValue([
      'activeAnimals',
      'active_animals',
      'activeAnimalCount',
      'active_animal_count',
    ]).toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopStat("Total Ovinos", total),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildTopStat("Ativos", ativos),
        ],
      ),
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: [
        _actionButton("Novo Ovino", Icons.add_circle_outline, AppColors.primary, () async {
          await Navigator.pushNamed(context, '/select-property');
          _loadUserData();
        }),
        _actionButton("Ler QR Code", Icons.qr_code_scanner, AppColors.primary, _scanAnimalQRCode),
        _actionButton("Transferência", Icons.sync_alt, AppColors.primary, () {
          _navTo(const AnimalSearchScreen(isTransferMode: true));
        }),
        _actionButton("Rebanho", Icons.agriculture, AppColors.primary, () {
          _navTo(const AnimalSearchScreen(isTransferMode: false));
        }),
        _actionButton("Nova Propriedade", Icons.location_on, AppColors.primary, () {
          _navTo(const PropertyCreateScreen());
        }),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String count, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textSecondary))),
                Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.borderSoft, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      // backgroundColor: bgGray, // Opcional: define a cor de fundo do menu
      child: Column(
        children: [
          // O UserAccountsDrawerHeader já tenta respeitar o topo,
          // mas embrulhamos em um MediaQuery para garantir que ele
          // saiba exatamente o tamanho da barra de status.
          UserAccountsDrawerHeader(
            margin: EdgeInsets.zero, // Remove margens que podem causar desalinhamento
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AppColors.primary),
            ),
            accountName: Text(
              _userProfile?['name'] ?? 'Carregando...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_userProfile?['email'] ?? ''),
          ),

          // Itens do Menu
          _drawerItem(
            Icons.agriculture,
            'Minhas Propriedades',
                () => Navigator.pushNamed(context, '/properties'),
          ),
          _drawerItem(
            Icons.settings_outlined,
            'Configurações',
                () {},
          ),

          const Spacer(), // Empurra o botão de sair para o final

          const Divider(),

          // AJUSTE: SafeArea inferior para o botão de Sair não ficar
          // em cima da barra de navegação/gestos do sistema.
          SafeArea(
            top: false, // O topo já é tratado pelo Header
            child: _drawerItem(
              Icons.logout,
              'Sair da Conta',
                  () async {
                await _authService.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10), // Respiro final
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}