import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:scanner_app/shared/shared.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  Map<String, dynamic>? qrScannedData;
  List<Map<String, dynamic>>? apiResponseData;
  bool isLoading = false;
  String? errorMessage;
  final _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && scanData.code != null) {
        _onScan(scanData.code!);
      }
    });
  }

  Future<void> _playScanSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/scan_sound.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> _onScan(String code) async {
    if (!isScanning) return;

    setState(() {
      isScanning = false;
      isLoading = true;
      errorMessage = null;
    });

    await _playScanSound();

    try {
      final Map<String, dynamic> parsedQrData = json.decode(code);

      // Llamar al API
      final List<Map<String, dynamic>> apiData = await ApiService.scanQRCode(
        code,
      );

      setState(() {
        qrScannedData = parsedQrData;
        apiResponseData = apiData;
        isLoading = false;
      });

      // Mostrar diálogo con los datos
      _showScanResultDialog(parsedQrData, apiData);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        // isScanning = true;
      });
      // Mostrar error y opción para resetear
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error en el escaneo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ocurrió un error:'),
              const SizedBox(height: 10),
              Text(error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              const Text('¿Qué deseas hacer?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Reintentar escaneo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner(completeReset: true);
              },
              child: const Text('Reiniciar cámara'),
            ),
          ],
        );
      },
    );
  }

  void _showScanResultDialog(
    Map<String, dynamic> qrData,
    List<Map<String, dynamic>> data,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado del Escaneo'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📋 Datos del Código QR:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDataTable(qrData),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                // Respuesta del API
                const Text(
                  '🌐 Respuesta del Endpoint:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 10),
                Text('Total de registros: ${data.length}'),
                const SizedBox(height: 10),
                ...data.map(
                  (item) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${item['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Nombre: ${item['name']}'),
                      const Divider(),
                    ],
                  ),
                ),
                Text(
                  _formatJson(data),
                  style: TextStyle(fontFamily: 'Monospace'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: Text('Escaner de nuevo'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      children: data.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.value.toString()),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  void _resetScanner({bool completeReset = false}) {
    setState(() {
      isScanning = true;
      isLoading = false;
      errorMessage = null;
      if (completeReset) {
        qrScannedData = null;
        apiResponseData = null;
      }
    });

    if (completeReset) {
      // Reinicio completo: pausar y reanudar la cámara
      controller?.pauseCamera().then((_) {
        controller?.resumeCamera();
      });
    } else {
      // Solo reanudar el escaneo
      controller?.resumeCamera();
    }
  }

  // void _resetScanner() {
  //   setState(() {
  //     isScanning = true;
  //     apiResponseData = null;
  //   });
  //   controller?.resumeCamera();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escánear QR'),
        actions: [
          if (!isScanning)
            IconButton(icon: Icon(Icons.refresh), onPressed: _resetScanner),
        ],
      ),
      body: Stack(
        children: [
          _buildQRView(context),
          if (isLoading) _buildLoadingOverlay(),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildQRView(BuildContext context) {
    return QRView(
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Consultando API...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Coloca el código QR dentro del marco para escanear',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se otorgaron permisos de cámara')),
      );
    }
  }
}
