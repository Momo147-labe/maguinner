import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/user.dart';
import '../models/store_info.dart';
import '../models/product.dart';
import '../core/database/database_helper.dart';

class InvoiceService {
  static Future<void> generateSaleInvoice(Sale sale) async {
    final storeInfo = await DatabaseHelper.instance.getStoreInfo();
    final customer = sale.customerId != null 
        ? await DatabaseHelper.instance.getCustomer(sale.customerId!)
        : null;
    final user = sale.userId != null 
        ? await DatabaseHelper.instance.getUser(sale.userId!)
        : null;
    final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête magasin
              _buildStoreHeader(storeInfo),
              pw.SizedBox(height: 20),
              
              // Titre facture
              pw.Center(
                child: pw.Text(
                  'FACTURE DE VENTE',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Informations facture
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('N° Facture: ${sale.id}'),
                      pw.Text('Date: ${_formatDate(sale.saleDate)}'),
                      pw.Text('Type: ${_getPaymentTypeLabel(sale.paymentType)}'),
                      if (sale.dueDate != null)
                        pw.Text('Échéance: ${_formatDate(sale.dueDate)}'),
                    ],
                  ),
                  if (customer != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLIENT:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(customer.name),
                        if (customer.phone != null) pw.Text('Tél: ${customer.phone}'),
                        if (customer.address != null) pw.Text(customer.address!),
                      ],
                    )
                  else
                    pw.Text('VENTE DIRECTE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Tableau des produits
              _buildSaleItemsTable(saleLines),
              pw.SizedBox(height: 20),
              
              // Total
              _buildSaleTotal(sale),
              pw.SizedBox(height: 20),
              
              // Vendeur
              if (user != null)
                pw.Text('Vendeur: ${user.fullName ?? user.username}'),
            ],
          );
        },
      ),
    );
    
    await _savePdf(pdf, 'facture_vente_${sale.id}');
  }

  static Future<void> generatePurchaseInvoice(Purchase purchase) async {
    final storeInfo = await DatabaseHelper.instance.getStoreInfo();
    final supplier = purchase.supplierId != null 
        ? await DatabaseHelper.instance.getSupplier(purchase.supplierId!)
        : null;
    final user = purchase.userId != null 
        ? await DatabaseHelper.instance.getUser(purchase.userId!)
        : null;
    final purchaseLines = await DatabaseHelper.instance.getPurchaseLines(purchase.id!);
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête magasin
              _buildStoreHeader(storeInfo),
              pw.SizedBox(height: 20),
              
              // Titre facture
              pw.Center(
                child: pw.Text(
                  'BON D\'ACHAT',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Informations achat
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('N° Bon: ${purchase.id}'),
                      pw.Text('Date: ${_formatDate(purchase.purchaseDate)}'),
                      pw.Text('Type: ${_getPaymentTypeLabel(purchase.paymentType)}'),
                      if (purchase.dueDate != null)
                        pw.Text('Échéance: ${_formatDate(purchase.dueDate)}'),
                    ],
                  ),
                  if (supplier != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FOURNISSEUR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(supplier.name),
                        if (supplier.phone != null) pw.Text('Tél: ${supplier.phone}'),
                        if (supplier.address != null) pw.Text(supplier.address!),
                      ],
                    )
                  else
                    pw.Text('ACHAT DIRECT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Tableau des produits
              _buildPurchaseItemsTable(purchaseLines),
              pw.SizedBox(height: 20),
              
              // Total
              _buildPurchaseTotal(purchase),
              pw.SizedBox(height: 20),
              
              // Acheteur
              if (user != null)
                pw.Text('Acheteur: ${user.fullName ?? user.username}'),
            ],
          );
        },
      ),
    );
    
    await _savePdf(pdf, 'bon_achat_${purchase.id}');
  }

  static pw.Widget _buildStoreHeader(StoreInfo? storeInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            storeInfo?.name ?? 'MAGASIN',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (storeInfo?.ownerName != null)
            pw.Text('Propriétaire: ${storeInfo!.ownerName}'),
          if (storeInfo?.phone != null)
            pw.Text('Tél: ${storeInfo!.phone}'),
          if (storeInfo?.email != null)
            pw.Text('Email: ${storeInfo!.email}'),
          if (storeInfo?.location != null)
            pw.Text('Adresse: ${storeInfo!.location}'),
        ],
      ),
    );
  }

  static pw.Widget _buildSaleItemsTable(List<dynamic> saleLines) {
    final headers = ['Produit', 'Qté', 'Prix Unit.', 'Sous-total'];
    final data = <List<String>>[];
    
    for (final line in saleLines) {
      data.add([
        'Produit ${line.productId}', // Simplified for now
        '${line.quantity}',
        '${line.salePrice.toStringAsFixed(0)} GNF',
        '${line.subtotal.toStringAsFixed(0)} GNF',
      ]);
    }
    
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  static pw.Widget _buildPurchaseItemsTable(List<dynamic> purchaseLines) {
    final headers = ['Produit', 'Qté', 'Prix Unit.', 'Sous-total'];
    final data = <List<String>>[];
    
    for (final line in purchaseLines) {
      data.add([
        'Produit ${line.productId}', // Simplified for now
        '${line.quantity}',
        '${line.purchasePrice.toStringAsFixed(0)} GNF',
        '${line.subtotal.toStringAsFixed(0)} GNF',
      ]);
    }
    
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  static pw.Widget _buildSaleTotal(Sale sale) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (sale.discount != null && sale.discount! > 0) ...[
            pw.Text('Sous-total: ${((sale.totalAmount ?? 0) + sale.discount!).toStringAsFixed(0)} GNF'),
            pw.Text('Remise: -${sale.discount!.toStringAsFixed(0)} GNF'),
            pw.Divider(),
          ],
          pw.Text(
            'TOTAL: ${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPurchaseTotal(Purchase purchase) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (purchase.discount != null && purchase.discount! > 0) ...[
            pw.Text('Sous-total: ${((purchase.totalAmount ?? 0) + purchase.discount!).toStringAsFixed(0)} GNF'),
            pw.Text('Remise: -${purchase.discount!.toStringAsFixed(0)} GNF'),
            pw.Divider(),
          ],
          pw.Text(
            'TOTAL: ${(purchase.totalAmount ?? 0).toStringAsFixed(0)} GNF',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
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

  static String _getPaymentTypeLabel(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return 'Paiement direct';
      case 'client':
        return 'Vente avec client';
      case 'credit':
        return 'Vente à crédit';
      case 'debt':
        return 'Achat à crédit';
      default:
        return paymentType ?? 'Direct';
    }
  }

  static Future<void> _savePdf(pw.Document pdf, String filename) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: filename,
      );
    } catch (e) {
      // Fallback: sauvegarder dans le dossier Documents
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());
    }
  }
}