import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_service.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _sync = SyncService.instance;

  Map<String, dynamic>? _profile;
  bool _checkingConnection = true;
  bool _online = false;
  bool _refreshingData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _checkingConnection = true);
    final results = await Future.wait([
      _authService.getProfile(),
      _sync.checkConnection(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _online = results[1] as bool;
      _checkingConnection = false;
    });
  }

  Future<void> _syncNow() async {
    final online = await _sync.checkConnection();
    if (!online) {
      _showMessage(
        'Sem conexão com o SISOV. As operações continuarão salvas no aparelho.',
        error: true,
      );
      if (mounted) setState(() => _online = false);
      return;
    }

    await _sync.flush();
    if (!mounted) return;
    setState(() => _online = true);
    _showMessage(
      _sync.pendingCount.value == 0
          ? 'Todos os dados foram sincronizados.'
          : 'Ainda existem operações aguardando envio.',
      error: _sync.pendingCount.value > 0,
    );
  }

  Future<void> _refreshOfflineData() async {
    if (_refreshingData) return;
    final online = await _sync.checkConnection();
    if (!online) {
      _showMessage(
        'Conecte-se à internet para atualizar os dados deste aparelho.',
        error: true,
      );
      return;
    }

    setState(() => _refreshingData = true);
    await SessionService.instance.warmCache();
    if (!mounted) return;
    setState(() {
      _refreshingData = false;
      _online = true;
    });
    _showMessage('Dados offline atualizados com sucesso.');
  }

  Future<void> _logout() async {
    if (_sync.pendingCount.value > 0) {
      _showMessage(
        'Sincronize as operações pendentes antes de sair para não perder dados.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'A sessão e os dados salvos neste aparelho serão removidos. '
          'Operações já sincronizadas permanecem seguras no SISOV.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SessionService.instance.logoutAndWipe();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  String _lastSyncLabel(DateTime? value) {
    if (value == null) return 'Ainda não executada nesta sessão';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Hoje às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'Conta do produtor',
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                title: Text(_profile?['name']?.toString() ?? 'Produtor SISOV'),
                subtitle: Text(
                  _profile?['email']?.toString() ?? 'E-mail não informado',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('CPF ou CNPJ'),
                subtitle: Text(
                  _profile?['document']?.toString() ?? 'Não informado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Sincronização e modo offline',
            children: [
              ListTile(
                leading: Icon(
                  _online
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: _online ? Colors.green : Colors.orange,
                ),
                title: const Text('Conexão com o SISOV'),
                subtitle: Text(
                  _checkingConnection
                      ? 'Verificando...'
                      : _online
                      ? 'Servidor disponível'
                      : 'Modo offline',
                ),
                trailing: IconButton(
                  tooltip: 'Verificar novamente',
                  onPressed: _checkingConnection ? null : _loadData,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _sync.pendingCount,
                builder: (_, count, _) => ListTile(
                  leading: const Icon(Icons.outbox_outlined),
                  title: const Text('Operações aguardando envio'),
                  subtitle: const Text(
                    'Cadastros e manejos feitos sem conexão.',
                  ),
                  trailing: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<DateTime?>(
                valueListenable: _sync.lastSyncAt,
                builder: (_, value, _) => ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Última sincronização'),
                  subtitle: Text(_lastSyncLabel(value)),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _sync.cellularSyncEnabled,
                builder: (_, enabled, _) => SwitchListTile(
                  secondary: const Icon(Icons.signal_cellular_alt),
                  title: const Text('Usar dados móveis'),
                  subtitle: const Text(
                    'Quando desativado, o envio automático espera Wi-Fi.',
                  ),
                  value: enabled,
                  onChanged: _sync.setCellularSyncEnabled,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _sync.syncing,
                builder: (_, syncing, _) => ListTile(
                  leading: syncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  title: Text(
                    syncing ? 'Sincronizando...' : 'Sincronizar agora',
                  ),
                  subtitle: const Text(
                    'Tenta enviar todas as operações salvas.',
                  ),
                  onTap: syncing ? null : _syncNow,
                ),
              ),
              ListTile(
                leading: _refreshingData
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                title: const Text('Atualizar dados deste aparelho'),
                subtitle: const Text(
                  'Baixa novamente propriedades e rebanho para uso offline.',
                ),
                onTap: _refreshingData ? null : _refreshOfflineData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Segurança e suporte',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Armazenamento protegido'),
                subtitle: const Text(
                  'Sua sessão fica protegida pelo sistema de segurança do aparelho.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Contato do SISOV'),
                subtitle: const Text('sisov.startup@gmail.com'),
                trailing: const Icon(Icons.copy),
                onTap: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: 'sisov.startup@gmail.com'),
                  );
                  _showMessage('E-mail de suporte copiado.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Servidor utilizado'),
                subtitle: const Text(ApiClient.baseUrl),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sair e limpar dados deste aparelho',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'SISOV — Rastreabilidade que gera confiança. '
            'Confiança que gera valor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
