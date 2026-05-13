import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class ReceiveAnimalScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // O conteúdo que o Scanner do remetente vai ler
    final String receiveData = jsonEncode({
      'producerId': producerId,
      'propertyId': propertyId,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Receber Ovino"),
        backgroundColor: const Color(0xFF0F8F82),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Mostre este QR Code para o vendedor",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Destino: $farmName", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: receiveData,
                version: QrVersions.auto,
                size: 250.0,
                foregroundColor: const Color(0xFF0F8F82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}