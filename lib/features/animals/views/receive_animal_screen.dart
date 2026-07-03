import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../services/animal_service.dart';

class ReceiveAnimalScreen extends StatefulWidget {
  final String producerId;
  final String propertyId;
  final String farmName;

  const ReceiveAnimalScreen({
    super.key,
    required this.producerId,
    required this.propertyId,
    required this.farmName,
  });

  @override
  State<ReceiveAnimalScreen> createState() => _ReceiveAnimalScreenState();
}

class _ReceiveAnimalScreenState extends State<ReceiveAnimalScreen> {
  final _animalService = AnimalService();

  Timer? _pollingTimer;
  int? _initialAnimalCount;
  bool _isInitializing = true;
  bool _transferReceived = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final animals = await _animalService.getAnimals();
      if (!mounted) return;
      setState(() {
        _initialAnimalCount = animals.length;
        _isInitializing = false;
      });
      _startPolling();
    } catch (_) {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _startPolling() {
    // Verifica a cada 4 segundos se chegou um novo animal
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkForNewAnimals();
    });
  }

  Future<void> _checkForNewAnimals() async {
    if (_transferReceived || _initialAnimalCount == null) return;
    try {
      final animals = await _animalService.getAnimals();
      if (!mounted) return;
      if (animals.length > _initialAnimalCount!) {
        _pollingTimer?.cancel();
        setState(() => _transferReceived = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Animal recebido com sucesso na sua propriedade!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String receiveData = jsonEncode({
      'producerId': widget.producerId,
      'propertyId': widget.propertyId,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receber animal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── STATUS HEADER ───────────────────────────────────────────
              if (_transferReceived)
                _buildSuccessCard()
              else
                _buildWaitingHeader(),

              const SizedBox(height: 28),

              // ── QR CODE ─────────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _transferReceived
                        ? Colors.green.shade300
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: receiveData,
                  version: QrVersions.auto,
                  size: 230.0,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _transferReceived ? Colors.green : AppColors.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _transferReceived ? Colors.green : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── INDICADOR DE ESTADO ─────────────────────────────────────
              if (!_transferReceived) _buildWaitingIndicator(),

              if (_transferReceived) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Voltar para Minhas Fazendas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal recebido!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'O ovino já está na sua propriedade.',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingHeader() {
    return Column(
      children: [
        const Text(
          'Mostre este código\npara o vendedor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Fazenda: ${widget.farmName}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildWaitingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isInitializing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          else
            const _PulsingDot(),
          const SizedBox(width: 10),
          Text(
            _isInitializing ? 'Preparando...' : 'Aguardando recebimento...',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Ponto pulsante para indicar que a tela está "escutando"
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
