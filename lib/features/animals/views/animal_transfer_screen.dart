import 'package:flutter/material.dart';
import '../services/animal_service.dart';

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
  final Color primaryTeal = const Color(0xFF0F8F82);
  bool _isLoading = false;

  @override
  void dispose() {
    _producerIdController.dispose();
    _propertyIdController.dispose();
    super.dispose();
  }

  void _transferirAnimal() async {
    if (_producerIdController.text.isEmpty || _propertyIdController.text.isEmpty) {
      _mostrarErro('Por favor, preencha todos os campos');
      return;
    }

    // Confirmação antes de transferir
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Transferência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animal: ${widget.animalName}'),
            const SizedBox(height: 8),
            Text('Novo Produtor: ${_producerIdController.text}'),
            const SizedBox(height: 8),
            Text('Propriedade: ${_propertyIdController.text}'),
            const SizedBox(height: 16),
            const Text(
              'Deseja confirmar a transferência?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    final resultado = await _animalService.transferAnimal(
      animalId: widget.animalId,
      destinationPropertyId: _propertyIdController.text.trim(),
      destinationProducerId: _producerIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (resultado['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Animal transferido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } else {
      _mostrarErro(resultado['message'] ?? 'Erro ao transferir animal');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir Animal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card do animal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryTeal, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.pets, color: primaryTeal, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Animal a Transferir',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.animalName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Dados do Novo Proprietário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),

            // Campo: ID do novo produtor
            const Text(
              'ID do Novo Produtor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _producerIdController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Ex: prod_123456',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: ID da propriedade destino
            const Text(
              'ID da Propriedade de Destino',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _propertyIdController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Ex: prop_789012',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Os IDs podem ser escaneados do QR Code do novo proprietário',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botão de transferência
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _transferirAnimal,
                icon: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.swap_horiz),
                label: Text(_isLoading ? 'Processando...' : 'Confirmar Transferência'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão cancelar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
