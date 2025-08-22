import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:scanner_app/shared/shared.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  Map<String, dynamic>? jsonData;
  bool isFlashOn = false;
  bool isScanning = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    AudioService.initialize();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanning || isSending) return;
      setState(() {
        isScanning = false;
      });

      _processQRData(scanData.code);
    });
  }

  void _processQRData(String? data) async {
    if (data == null) {
      _showErrorDialog('No se pudo leer el código QR');
      return;
    }

    try {
      // Reproducir sonido de escaneo
      await AudioService.playScanSound();
      print('Escaneado: $data');
      // Intentar parsear como JSON
      final parsedJson = json.decode(data);
      if (parsedJson is Map<String, dynamic>) {
        setState(() {
          jsonData = parsedJson;
          isSending = true;
        });
        // Petición al backend
        final response = await ApiService.sendScannedData(parsedJson);

        if (response['success'] == true) {
          _showJsonResult(parsedJson, response);
        } else {
          _showApiErrorDialog(response);
        }
      } else {
        _showErrorDialog('El QR no contiene un JSON válido');
      }
    } catch (e) {
      _showErrorDialog('Error al procesar JSON: $e');
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void _showJsonResult(
    Map<String, dynamic> jsonData,
    Map<String, dynamic> apiResponse,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('¡Éxito!'),
            ],
          ),
          content: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Datos JSON encontrados',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...jsonData.entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'JSON Completo, Respuesta del servidor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      JsonEncoder.withIndent('  ').convert(jsonData),
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${apiResponse['statusCode']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeScanning();
              },
              child: Text('Escanear Otro'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
    );
  }

  void _showApiErrorDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Error del Servidor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${response['statusCode'] ?? 'N/A'}'),
              const SizedBox(height: 10),
              Text('Error: ${response['error'] ?? 'Error desconocido'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeScanning();
              },
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  void _resumeScanning() {
    setState(() {
      isScanning = true;
      jsonData = null;
      isSending = false;
    });
  }

  void _toggleFlash() {
    if (qrController != null) {
      qrController!.toggleFlash();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  @override
  void dispose() {
    qrController?.dispose();
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear JSON QR'),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * .8,
              ),
              onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isSending
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Enviando datos al servidor...'),
                      ],
                    )
                  : !isScanning
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Enfoca un código QR con formato JSON',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          if (isSending) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sin permisos de cámara')));
    }
  }
}
