import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PDFExportServiceAdmin {
  // Generate and save PDF report for admin (all departments)
  static Future<void> exportDashboardToPDF() async {
    try {
      // Fetch all the data without department filtering
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
              _buildOnlineOfflineSummary(data),
              pw.SizedBox(height: 30),
              _buildBrandDistribution(data),
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
  
  // Fetch all dashboard data (no department filtering)
  static Future<Map<String, dynamic>> _fetchDashboardData() async {
    final firestore = FirebaseFirestore.instance;
    
    // Get all devices without filtering
    final allDevicesSnapshot = await firestore.collection('devices').get();
    
    int totalPC = 0;
    int onlinePC = 0;
    int totalPeripheral = 0;
    int onlinePeripheral = 0;
    Map<String, int> brandCounts = {};
    
    // Count all devices
    for (var doc in allDevicesSnapshot.docs) {
      final data = doc.data();
      final type = (data['type'] as String?)?.toLowerCase();
      final status = data['status'] as String?;
      final brand = data['brand'] as String?;
      
      // Count by type
      if (type == 'pc') {
        totalPC++;
        if (status == 'Online') {
          onlinePC++;
        }
      } else if (type == 'peripheral') {
        totalPeripheral++;
        if (status == 'Online') {
          onlinePeripheral++;
        }
      }
      
      // Count by brand
      if (brand != null && brand.trim().isNotEmpty) {
        final brandStr = brand.trim();
        brandCounts[brandStr] = (brandCounts[brandStr] ?? 0) + 1;
      }
    }
    
    return {
      'totalPC': totalPC,
      'onlinePC': onlinePC,
      'offlinePC': totalPC - onlinePC,
      'totalPeripheral': totalPeripheral,
      'onlinePeripheral': onlinePeripheral,
      'offlinePeripheral': totalPeripheral - onlinePeripheral,
      'brandCounts': brandCounts,
      'generatedAt': DateTime.now(),
    };
  }
  
  // Build PDF header with title and timestamp
  static pw.Widget _buildHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'e-Inventory Computer Admin Dashboard Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'All Departments',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue400,
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
        pw.Divider(thickness: 2, color: PdfColors.blue400),
      ],
    );
  }
  
  // Build device distribution summary
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
              _buildDistributionRow('PCs', totalPC, pcPercentage, PdfColors.blue400),
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
  
  // Build online vs offline summary
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
  
  // Build brand distribution table
  static pw.Widget _buildBrandDistribution(Map<String, dynamic> data) {
    final brandCounts = data['brandCounts'] as Map<String, int>;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Brand Distribution (All Departments)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        brandCounts.isEmpty 
          ? pw.Text('No devices found', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600))
          : pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Brand', isHeader: true),
                    _buildTableCell('Count', isHeader: true),
                    _buildTableCell('Percentage', isHeader: true),
                  ],
                ),
                // Brand rows
                ...brandCounts.entries.map((entry) {
                  final total = brandCounts.values.reduce((a, b) => a + b);
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  
                  return pw.TableRow(
                    children: [
                      _buildTableCell(entry.key),
                      _buildTableCell('${entry.value}'),
                      _buildTableCell('$percentage%'),
                    ],
                  );
                }).toList(),
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
    final file = File('${output.path}/admin_dashboard_report_$timestamp.pdf');
    
    await file.writeAsBytes(await pdf.save());
    
    // Optional: Open the PDF or show success message
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    
    print('PDF saved to: ${file.path}');
  }
}