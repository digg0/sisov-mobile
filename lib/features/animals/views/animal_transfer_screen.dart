import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:convert';
import '../services/animal_service.dart';
import 'qr_scanner_screen.dart';

class AnimalTransferScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String currentProducerId;

  const AnimalTransferScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.currentProducerId,
  });

  @override
  State<AnimalTransferScreen> createState() => _AnimalTransferScreenState();
}

class _AnimalTransferScreenState extends State<AnimalTransferScreen> {
  final _animalService = AnimalService();
  final _producerIdController = TextEditingController();
  final _propertyIdController = TextEditingController();
  bool _isLoading = false;

  void _escanearDestino() async {
    // 1. Abre o scanner
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    // 2. Se o usuário voltou sem ler nada, encerra
    if (result == null) return;

    try {
      // 3. Forçamos o resultado a virar String e removemos espaços (trim)
      final String rawText = result.toString().trim();

      // 4. Decodificamos o JSON
      final Map<String, dynamic> data = jsonDecode(rawText);

      // 5. Atualizamos os controladores garantindo que os IDs sejam Strings
      setState(() {
        _producerIdController.text = (data['producerId'] ?? '').toString();
        _propertyIdController.text = (data['propertyId'] ?? '').toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Dados de destino carregados com sucesso!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      // Caso o QR Code lido seja um link de animal ou texto inválido
      print("Erro ao processar JSON: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code inválido para transferência.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _executarTransferencia() async {
    print("Iniciando transferência do animal: ${widget.animalId}");
    print("Para a propriedade: ${_propertyIdController.text}");
    if (_producerIdController.text.isEmpty || _propertyIdController.text.isEmpty) {
      _mostrarErro('Preencha os campos ou escaneie o código de destino.');
      return;
    }

    setState(() => _isLoading = true);

    final res = await _animalService.transferAnimal(
      animalId: widget.animalId,
      destinationPropertyId: _propertyIdController.text.trim(),
      destinationProducerId: _producerIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Transferência concluída!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Volta para a ficha do animal avisando sucesso
      }
    } else {
      _mostrarErro(res['message'] ?? 'Erro no servidor ao transferir.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transferir Animal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Identificação do Animal
            _buildAnimalHeader(),
            const SizedBox(height: 30),

            // BOTÃO PRINCIPAL DE SCANNER
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                onPressed: _escanearDestino,
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text("ESCANEAR FAZENDA DESTINO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OU MANUAL", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // Campos Manuais
            _buildField("ID do Novo Produtor", _producerIdController, Icons.person),
            const SizedBox(height: 15),
            _buildField("ID da Propriedade", _propertyIdController, Icons.location_on),

            const SizedBox(height: 40),

            // Botão de Envio
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _executarTransferencia,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRMAR TRANSFERÊNCIA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.pets, color: AppColors.primary, size: 30),
          const SizedBox(width: 15),
          Text(widget.animalName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}