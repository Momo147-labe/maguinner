import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../core/database/database_helper.dart';
import '../utils/currency_formatter.dart';

class ExportService {
  
  /// Exporte la liste des clients en PDF
  static Future<void> exportCustomersPDF(List<Customer> customers) async {
    final pdf = pw.Document();
    
    // Calculer les totaux
    double totalSales = 0;
    double totalDebts = 0;
    
    final List<List<String>> customerData = [];
    for (final customer in customers) {
      final sales = await DatabaseHelper.instance.getSales();
      final customerSales = sales.where((s) => s.customerId == customer.id).toList();
      final salesAmount = customerSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
      final debtsAmount = customerSales.where((s) => s.paymentType == 'debt').fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
      
      totalSales += salesAmount;
      totalDebts += debtsAmount;
      
      customerData.add([
        customer.name,
        customer.phone ?? '-',
        customer.address ?? '-',
        CurrencyFormatter.formatGNF(salesAmount),
        CurrencyFormatter.formatGNF(debtsAmount),
        _formatDate(customer.createdAt),
      ]);
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Liste des Clients', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Date d\'export: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              pw.SizedBox(height: 20),
              
              // Résumé
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉSUMÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Nombre de clients: ${customers.length}'),
                    pw.Text('Total des ventes: ${CurrencyFormatter.formatGNF(totalSales)}'),
                    pw.Text('Total des dettes: ${CurrencyFormatter.formatGNF(totalDebts)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Tableau
              pw.Table.fromTextArray(
                headers: ['Nom', 'Téléphone', 'Adresse', 'Total Ventes', 'Dettes', 'Date Création'],
                data: customerData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Exporte la liste des fournisseurs en PDF
  static Future<void> exportSuppliersPDF(List<Supplier> suppliers) async {
    final pdf = pw.Document();
    
    double totalPurchases = 0;
    double totalDebts = 0;
    
    final List<List<String>> supplierData = [];
    for (final supplier in suppliers) {
      final purchases = await DatabaseHelper.instance.getPurchases();
      final supplierPurchases = purchases.where((p) => p.supplierId == supplier.id).toList();
      final purchasesAmount = supplierPurchases.fold(0.0, (sum, purchase) => sum + (purchase.totalAmount ?? 0));
      final debtsAmount = supplierPurchases.where((p) => p.paymentType == 'debt').fold(0.0, (sum, purchase) => sum + (purchase.totalAmount ?? 0));
      
      totalPurchases += purchasesAmount;
      totalDebts += debtsAmount;
      
      supplierData.add([
        supplier.name,
        supplier.phone ?? '-',
        supplier.address ?? '-',
        CurrencyFormatter.formatGNF(purchasesAmount),
        CurrencyFormatter.formatGNF(debtsAmount),
        CurrencyFormatter.formatGNF(supplier.balance ?? 0),
        _formatDate(supplier.createdAt),
      ]);
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Liste des Fournisseurs', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Date d\'export: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉSUMÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Nombre de fournisseurs: ${suppliers.length}'),
                    pw.Text('Total des achats: ${CurrencyFormatter.formatGNF(totalPurchases)}'),
                    pw.Text('Total des dettes: ${CurrencyFormatter.formatGNF(totalDebts)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Table.fromTextArray(
                headers: ['Nom', 'Téléphone', 'Adresse', 'Total Achats', 'Dettes', 'Solde', 'Date Création'],
                data: supplierData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Exporte les clients en Excel (CSV)
  static Future<void> exportCustomersExcel(List<Customer> customers) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter les clients',
      fileName: 'clients_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      
      // En-têtes
      csv.writeln('Nom,Téléphone,Email,Adresse,Total Ventes,Dettes,Date Création');
      
      // Données
      for (final customer in customers) {
        final sales = await DatabaseHelper.instance.getSales();
        final customerSales = sales.where((s) => s.customerId == customer.id).toList();
        final salesAmount = customerSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
        final debtsAmount = customerSales.where((s) => s.paymentType == 'debt').fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
        
        csv.writeln([
          _escapeCsv(customer.name),
          _escapeCsv(customer.phone ?? ''),
          _escapeCsv(customer.email ?? ''),
          _escapeCsv(customer.address ?? ''),
          salesAmount.toStringAsFixed(0),
          debtsAmount.toStringAsFixed(0),
          _formatDate(customer.createdAt),
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
    }
  }

  /// Exporte les fournisseurs en Excel (CSV)
  static Future<void> exportSuppliersExcel(List<Supplier> suppliers) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter les fournisseurs',
      fileName: 'fournisseurs_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      
      csv.writeln('Nom,Téléphone,Email,Adresse,Total Achats,Dettes,Solde,Date Création');
      
      for (final supplier in suppliers) {
        final purchases = await DatabaseHelper.instance.getPurchases();
        final supplierPurchases = purchases.where((p) => p.supplierId == supplier.id).toList();
        final purchasesAmount = supplierPurchases.fold(0.0, (sum, purchase) => sum + (purchase.totalAmount ?? 0));
        final debtsAmount = supplierPurchases.where((p) => p.paymentType == 'debt').fold(0.0, (sum, purchase) => sum + (purchase.totalAmount ?? 0));
        
        csv.writeln([
          _escapeCsv(supplier.name),
          _escapeCsv(supplier.phone ?? ''),
          _escapeCsv(supplier.email ?? ''),
          _escapeCsv(supplier.address ?? ''),
          purchasesAmount.toStringAsFixed(0),
          debtsAmount.toStringAsFixed(0),
          (supplier.balance ?? 0).toStringAsFixed(0),
          _formatDate(supplier.createdAt),
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
    }
  }

  /// Exporte la liste des ventes en PDF
  static Future<void> exportSalesPDF(List<Sale> sales) async {
    final pdf = pw.Document();
    
    double totalAmount = 0;
    int totalSales = sales.length;
    
    final List<List<String>> salesData = [];
    for (final sale in sales) {
      String clientName = 'Direct';
      String userName = 'Utilisateur inconnu';
      
      if (sale.customerId != null) {
        final customer = await DatabaseHelper.instance.getCustomer(sale.customerId!);
        clientName = customer?.name ?? 'Client inconnu';
      }
      
      if (sale.userId != null) {
        final user = await DatabaseHelper.instance.getUser(sale.userId!);
        userName = user?.fullName ?? user?.username ?? 'Utilisateur inconnu';
      }
      
      totalAmount += sale.totalAmount ?? 0;
      
      salesData.add([
        sale.id.toString(),
        clientName,
        userName,
        _getPaymentTypeLabel(sale.paymentType),
        _formatDateTime(sale.saleDate),
        CurrencyFormatter.formatGNF(sale.totalAmount ?? 0),
      ]);
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Historique des Ventes', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Date d\'export: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉSUMÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Nombre de ventes: $totalSales'),
                    pw.Text('Montant total: ${CurrencyFormatter.formatGNF(totalAmount)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Table.fromTextArray(
                headers: ['ID', 'Client', 'Vendeur', 'Mode', 'Date', 'Montant'],
                data: salesData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Exporte les ventes en Excel (CSV)
  static Future<void> exportSalesExcel(List<Sale> sales) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter les ventes',
      fileName: 'ventes_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      
      csv.writeln('ID,Client,Vendeur,Mode de paiement,Date,Montant total');
      
      for (final sale in sales) {
        String clientName = 'Direct';
        String userName = 'Utilisateur inconnu';
        
        if (sale.customerId != null) {
          final customer = await DatabaseHelper.instance.getCustomer(sale.customerId!);
          clientName = customer?.name ?? 'Client inconnu';
        }
        
        if (sale.userId != null) {
          final user = await DatabaseHelper.instance.getUser(sale.userId!);
          userName = user?.fullName ?? user?.username ?? 'Utilisateur inconnu';
        }
        
        csv.writeln([
          sale.id.toString(),
          _escapeCsv(clientName),
          _escapeCsv(userName),
          _escapeCsv(_getPaymentTypeLabel(sale.paymentType)),
          _formatDateTime(sale.saleDate),
          (sale.totalAmount ?? 0).toStringAsFixed(0),
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
    }
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  static String _formatDateTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  static String _getPaymentTypeLabel(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return 'Paiement direct';
      case 'client':
        return 'Vente avec client';
      case 'credit':
        return 'Dette';
      default:
        return 'Paiement direct';
    }
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}