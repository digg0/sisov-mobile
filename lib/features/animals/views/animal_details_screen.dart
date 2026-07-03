import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_exporter.dart';
import '../services/animal_service.dart';
import 'animal_history_screen.dart';
import 'animal_management_event_screen.dart';
import 'slaughter_registration_screen.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailsScreen({super.key, required this.animal});

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  final _animalService = AnimalService();
  final GlobalKey _qrKey = GlobalKey();
  bool _isExportingImage = false;

  static const String statusActive = 'ACTIVE';

  static const String statusSlaughtered = 'SLAUGHTERED';

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    final bool isMale = animal['sex'] == 'MALE';

    final bool isActive = animal['status'] == statusActive;

    final bool isSlaughtered = animal['status'] == statusSlaughtered;

    final Color statusCor = isActive ? Colors.green : Colors.red;

    String dataNasc = animal['birthDate'] ?? '';

    try {
      final date = DateTime.parse(dataNasc);

      dataNasc =
          "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (_) {}

    final String sisovId = (animal['sisovId'] ?? '').toString();
    final String animalId = sisovId.isNotEmpty
        ? sisovId
        : (animal['id'] ?? '').toString();

    // QR de rastreabilidade usa exclusivamente o sisovId oficial do animal.
    // QR de manejo usa animalId (sisovId com fallback para id interno).
    final String publicUrl = "https://sisov.com.br/rastreabilidade/$sisovId";

    final String internalUrl = "sisov://manage/$animalId";

    final String qrData = isSlaughtered ? publicUrl : internalUrl;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          "Ficha do Animal: ${animal['tagId'] ?? 'N/A'}",

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: AppColors.primary,

        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // TAG DE STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: statusCor.withValues(alpha: 0.1),

                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                isActive ? '🟢 ATIVO NA PROPRIEDADE' : '🔴 ABATIDO/INATIVO',

                style: TextStyle(
                  color: statusCor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CARD PRINCIPAL
            _buildInfoCard(animal, isMale, dataNasc),

            const SizedBox(height: 30),

            // MÓDULO QR
            Center(
              child: Column(
                children: [
                  Text(
                    isSlaughtered
                        ? "QR Code de Rastreabilidade"
                        : "QR Code de Manejo",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),

                        width: 2,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),

                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: _qrKey,
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            foregroundColor: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isExportingImage
                                      ? null
                                      : () => _exportQRCode(false, animalId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isExportingImage
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Exportar PNG'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isExportingImage
                                      ? null
                                      : () => _exportQRCode(true, animalId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Exportar JPG'),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          isSlaughtered
                              ? "Escaneie para visualizar o histórico público da rastreabilidade."
                              : "QR Code interno para manejo e operações do sistema.",

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openFullHistory(animalId),
                icon: const Icon(Icons.history_edu),
                label: const Text('Ver Histórico Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimalManagementEventScreen(
                          animalId: animalId,
                          animalName: animal['tagId']?.toString() ?? 'Animal',
                        ),
                      ),
                    );

                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Evento de manejo registrado com sucesso.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Registrar Evento de Manejo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // BOTÃO ABATE
            if (isActive)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),

                child: SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarAbate(context, animalId),

                    icon: const Icon(Icons.gavel, color: Colors.white),

                    label: const FittedBox(
                      child: Text(
                        "REGISTRAR ABATE / SELO IG",

                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 36, 14, 233),

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    Map<String, dynamic> animal,
    bool isMale,
    String dataNasc,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 10,
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,

                backgroundColor: isMale
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.pink.withValues(alpha: 0.1),

                child: Icon(
                  isMale ? Icons.male : Icons.female,

                  color: isMale ? Colors.blue : Colors.pink,

                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Brinco: ${animal['tagId'] ?? 'N/A'}',

                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    Text(
                      animal['breed'] ?? 'Raça não informada',

                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),

            child: Divider(),
          ),

          _infoRow(Icons.cake, 'Nascimento', dataNasc),

          const SizedBox(height: 12),

          _infoRow(
            Icons.location_city,
            'Local de Nascimento',
            animal['birthCity'] ?? '',
          ),

          const SizedBox(height: 12),

          _infoRow(
            Icons.agriculture,
            'Propriedade Atual',
            animal['property']?['farmName'] ?? 'Desconhecida',
          ),
        ],
      ),
    );
  }

  Future<void> _exportQRCode(bool asJpg, String animalId) async {
    if (_qrKey.currentContext == null) return;

    setState(() => _isExportingImage = true);
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Não foi possível gerar a imagem do QR Code.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final outputBytes = asJpg ? _convertPngToJpg(pngBytes) : pngBytes;
      final extension = asJpg ? 'jpg' : 'png';
      final filename =
          'qr_animal_${animalId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final savedPath = await saveImageBytes(outputBytes, filename, extension);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savedPath),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao exportar QR: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingImage = false);
    }
  }

  Uint8List _convertPngToJpg(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw Exception('Falha na conversão para JPG.');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,

            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),

        Text(
          value,

          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // CONFIRMAÇÃO DE ABATE
  void _confirmarAbate(BuildContext context, String id) {
    final animal = widget.animal;
    final String tagId = animal['tagId']?.toString() ?? 'Animal';
    final String birthDate = animal['birthDate'] ?? '';
    
    DateTime? parsedBirthDate;
    try {
      parsedBirthDate = DateTime.parse(birthDate);
    } catch (_) {
      parsedBirthDate = DateTime.now().subtract(const Duration(days: 180));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SlaughterRegistrationScreen(
          animalId: id,
          animalTag: tagId,
          birthDate: parsedBirthDate!,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Abate registrado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  Future<void> _openFullHistory(String animalId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final events = await _animalService.getFullHistory(animalId);
    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Histórico não encontrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnimalHistoryScreen(events: events)),
    );
  }


}
