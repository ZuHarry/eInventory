import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PDFExportService {
  // Generate and save PDF report
  static Future<void> exportDashboardToPDF() async {
    try {
      // Fetch all the data
      final data = await _fetchDashboardData();
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildDeviceDistributionSummary(data),
              pw.SizedBox(height: 30),
              _buildDeviceSummaryTable(data),
              pw.SizedBox(height: 30),
              _buildBuildingSummaryTable(data),
              pw.SizedBox(height: 30),
              _buildOnlineOfflineSummary(data),
            ];
          },
        ),
      );
      
      // Save PDF
      await _savePDF(pdf);
      
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Failed to generate PDF report: $e');
    }
  }
  
  // Fetch all dashboard data
  static Future<Map<String, dynamic>> _fetchDashboardData() async {
    final firestore = FirebaseFirestore.instance;
    
    // Get device counts
    final pcSnapshot = await firestore
        .collection('devices')
        .where('type', isEqualTo: 'PC')
        .count()
        .get();
    final totalPC = pcSnapshot.count ?? 0;
    
    final onlinePCSnapshot = await firestore
        .collection('devices')
        .where('type', isEqualTo: 'PC')
        .where('status', isEqualTo: 'Online')
        .count()
        .get();
    final onlinePC = onlinePCSnapshot.count ?? 0;
    
    final peripheralSnapshot = await firestore
        .collection('devices')
        .where('type', isEqualTo: 'Peripheral')
        .count()
        .get();
    final totalPeripheral = peripheralSnapshot.count ?? 0;
    
    final onlinePeripheralSnapshot = await firestore
        .collection('devices')
        .where('type', isEqualTo: 'Peripheral')
        .where('status', isEqualTo: 'Online')
        .count()
        .get();
    final onlinePeripheral = onlinePeripheralSnapshot.count ?? 0;
    
    // Get building data
    final buildingCounts = await _getDeviceCountsByBuilding();
    
    return {
      'totalPC': totalPC,
      'onlinePC': onlinePC,
      'offlinePC': totalPC - onlinePC,
      'totalPeripheral': totalPeripheral,
      'onlinePeripheral': onlinePeripheral,
      'offlinePeripheral': totalPeripheral - onlinePeripheral,
      'buildingCounts': buildingCounts,
      'generatedAt': DateTime.now(),
    };
  }
  
  // Get device counts by building (same logic as in HomePage)
  static Future<Map<String, Map<String, int>>> _getDeviceCountsByBuilding() async {
    final firestore = FirebaseFirestore.instance;
    
    final locationsSnapshot = await firestore.collection('locations').get();
    final Map<String, String> locationToBuilding = {};
    for (var doc in locationsSnapshot.docs) {
      final data = doc.data();
      final locationName = data['name'];
      final building = data['building'];
      if (locationName != null && building != null) {
        locationToBuilding[locationName] = building;
      }
    }
    
    Map<String, Map<String, int>> result = {
      'Right Wing': {'pc': 0, 'peripherals': 0},
      'Left Wing': {'pc': 0, 'peripherals': 0},
    };
    
    final devicesSnapshot = await firestore.collection('devices').get();
    for (var doc in devicesSnapshot.docs) {
      final data = doc.data();
      final locationName = data['location'];
      final type = (data['type'] as String?)?.toLowerCase();
      
      if (locationName != null &&
          locationToBuilding.containsKey(locationName) &&
          (type == 'pc' || type == 'peripheral' || type == 'peripherals')) {
        final building = locationToBuilding[locationName]!;
        if (result.containsKey(building)) {
          if (type == 'pc') {
            result[building]!['pc'] = result[building]!['pc']! + 1;
          } else {
            result[building]!['peripherals'] = result[building]!['peripherals']! + 1;
          }
        }
      }
    }
    
    return result;
  }
  
  // Build PDF header with title and timestamp
  static pw.Widget _buildHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'e-Inventory Computer Dashboard Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on ${formatter.format(now)}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.amber),
      ],
    );
  }
  
  // Build device distribution summary (replaces chart)
  static pw.Widget _buildDeviceDistributionSummary(Map<String, dynamic> data) {
    final totalPC = data['totalPC'] as int;
    final totalPeripheral = data['totalPeripheral'] as int;
    final total = totalPC + totalPeripheral;
    
    if (total == 0) {
      return pw.Container(
        child: pw.Text('No devices found', style: pw.TextStyle(fontSize: 16)),
      );
    }
    
    final pcPercentage = total > 0 ? (totalPC / total * 100).toStringAsFixed(1) : '0.0';
    final peripheralPercentage = total > 0 ? (totalPeripheral / total * 100).toStringAsFixed(1) : '0.0';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Device Distribution Overview',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Devices:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('$total', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildDistributionRow('PCs', totalPC, pcPercentage, PdfColors.amber),
              pw.SizedBox(height: 8),
              _buildDistributionRow('Peripherals', totalPeripheral, peripheralPercentage, PdfColors.grey600),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build distribution row helper
  static pw.Widget _buildDistributionRow(String label, int count, String percentage, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          color: color,
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text('$label: $count ($percentage%)', style: pw.TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
  
  // Build device summary table
  static pw.Widget _buildDeviceSummaryTable(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Device Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Device Type', isHeader: true),
                _buildTableCell('Total', isHeader: true),
                _buildTableCell('Online', isHeader: true),
                _buildTableCell('Offline', isHeader: true),
                _buildTableCell('Online %', isHeader: true),
              ],
            ),
            // PC Row
            pw.TableRow(
              children: [
                _buildTableCell('PCs'),
                _buildTableCell('${data['totalPC']}'),
                _buildTableCell('${data['onlinePC']}'),
                _buildTableCell('${data['offlinePC']}'),
                _buildTableCell(_calculatePercentage(data['onlinePC'], data['totalPC'])),
              ],
            ),
            // Peripheral Row
            pw.TableRow(
              children: [
                _buildTableCell('Peripherals'),
                _buildTableCell('${data['totalPeripheral']}'),
                _buildTableCell('${data['onlinePeripheral']}'),
                _buildTableCell('${data['offlinePeripheral']}'),
                _buildTableCell(_calculatePercentage(data['onlinePeripheral'], data['totalPeripheral'])),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  // Calculate percentage helper
  static String _calculatePercentage(int part, int total) {
    if (total == 0) return '0%';
    return '${(part / total * 100).toStringAsFixed(1)}%';
  }
  
  // Build building summary table
  static pw.Widget _buildBuildingSummaryTable(Map<String, dynamic> data) {
    final buildingCounts = data['buildingCounts'] as Map<String, Map<String, int>>;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Devices by Building',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Building', isHeader: true),
                _buildTableCell('PCs', isHeader: true),
                _buildTableCell('Peripherals', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Building rows
            ...buildingCounts.entries.map((entry) {
              final building = entry.key;
              final counts = entry.value;
              final pcCount = counts['pc'] ?? 0;
              final peripheralCount = counts['peripherals'] ?? 0;
              final total = pcCount + peripheralCount;
              
              return pw.TableRow(
                children: [
                  _buildTableCell(building),
                  _buildTableCell('$pcCount'),
                  _buildTableCell('$peripheralCount'),
                  _buildTableCell('$total'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
  
  // Build online vs offline summary (replaces chart)
  static pw.Widget _buildOnlineOfflineSummary(Map<String, dynamic> data) {
    final onlinePC = data['onlinePC'] as int;
    final offlinePC = data['offlinePC'] as int;
    final onlinePeripheral = data['onlinePeripheral'] as int;
    final offlinePeripheral = data['offlinePeripheral'] as int;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Online vs Offline Status Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Device Type', isHeader: true),
                _buildTableCell('Online', isHeader: true),
                _buildTableCell('Offline', isHeader: true),
                _buildTableCell('Total', isHeader: true),
                _buildTableCell('Uptime %', isHeader: true),
              ],
            ),
            // PC Row
            pw.TableRow(
              children: [
                _buildTableCell('PCs'),
                _buildTableCell('$onlinePC'),
                _buildTableCell('$offlinePC'),
                _buildTableCell('${onlinePC + offlinePC}'),
                _buildTableCell(_calculatePercentage(onlinePC, onlinePC + offlinePC)),
              ],
            ),
            // Peripheral Row
            pw.TableRow(
              children: [
                _buildTableCell('Peripherals'),
                _buildTableCell('$onlinePeripheral'),
                _buildTableCell('$offlinePeripheral'),
                _buildTableCell('${onlinePeripheral + offlinePeripheral}'),
                _buildTableCell(_calculatePercentage(onlinePeripheral, onlinePeripheral + offlinePeripheral)),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  // Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  // Save PDF to device
  static Future<void> _savePDF(pw.Document pdf) async {
    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${output.path}/dashboard_report_$timestamp.pdf');
    
    await file.writeAsBytes(await pdf.save());
    
    // Optional: Open the PDF or show success message
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    
    print('PDF saved to: ${file.path}');
  }
}