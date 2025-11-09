import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Widget generator for creating and saving loan receipts as images
class ReceiptImageGenerator {
  /// Generates a receipt widget that can be captured as image
  static Widget buildReceiptWidget({
    required String receiptNumber,
    required String loanNumber,
    required String clientName,
    required String clientId,
    required double paymentAmount,
    required DateTime paymentDate,
    required String adminName,
    required double remainingDebt,
    required double totalPaid,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'RECIBO DE PAGO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TPay - Sistema de Préstamos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[400], thickness: 1),
          const SizedBox(height: 16),

          // Receipt Info
          _buildInfoRow('Recibo N°:', receiptNumber),
          _buildInfoRow('Fecha:', dateFormat.format(paymentDate)),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Client Info
          Text(
            'Información del Cliente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Cliente:', clientName),
          _buildInfoRow('ID Cliente:', clientId),
          _buildInfoRow('Préstamo N°:', loanNumber),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Payment Info
          Text(
            'Detalles del Pago',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Monto Pagado:',
            currencyFormat.format(paymentAmount),
            color: Color(0xFF4CAF50),
            isBold: true,
          ),
          _buildInfoRow(
            'Total Abonado:',
            currencyFormat.format(totalPaid),
          ),
          _buildAmountRow(
            'Deuda Restante:',
            currencyFormat.format(remainingDebt),
            color: remainingDebt > 0 ? Color(0xFFF44336) : Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Admin Info
          _buildInfoRow('Atendido por:', adminName),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  '________________________________',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Firma del Cliente',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gracias por su pago',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAmountRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Captures a widget as an image and saves it to the device
  static Future<String?> captureAndSaveReceipt({
    required GlobalKey key,
    required String fileName,
  }) async {
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      // Get the directory to save the image
      Directory? directory;
      if (Platform.isAndroid) {
        // For Android, use external storage
        directory = Directory('/storage/emulated/0/Download/TPay');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      // Create the file
      final String filePath = '${directory.path}/$fileName.png';
      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

  /// Shows a dialog with the receipt and option to save it
  static Future<void> showReceiptDialog({
    required BuildContext context,
    required String receiptNumber,
    required String loanNumber,
    required String clientName,
    required String clientId,
    required double paymentAmount,
    required DateTime paymentDate,
    required String adminName,
    required double remainingDebt,
    required double totalPaid,
  }) async {
    final GlobalKey receiptKey = GlobalKey();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Receipt preview
                Container(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: receiptKey,
                      child: buildReceiptWidget(
                        receiptNumber: receiptNumber,
                        loanNumber: loanNumber,
                        clientName: clientName,
                        clientId: clientId,
                        paymentAmount: paymentAmount,
                        paymentDate: paymentDate,
                        adminName: adminName,
                        remainingDebt: remainingDebt,
                        totalPaid: totalPaid,
                      ),
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setState(() => isSaving = true);
                                final fileName =
                                    'recibo_${receiptNumber}_${DateTime.now().millisecondsSinceEpoch}';
                                final filePath =
                                    await captureAndSaveReceipt(
                                  key: receiptKey,
                                  fileName: fileName,
                                );
                                setState(() => isSaving = false);

                                if (filePath != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Recibo guardado en:\n$filePath',
                                      ),
                                      duration: const Duration(seconds: 4),
                                      backgroundColor: Color(0xFF4CAF50),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error al guardar el recibo',
                                      ),
                                      backgroundColor: Color(0xFFF44336),
                                    ),
                                  );
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isSaving ? 'Guardando...' : 'Guardar Imagen',
                        ),
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
}
