import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/store_info.dart';

class BadgeService {
  
  /// Génère un badge PDF pour un utilisateur avec le modèle sélectionné
  static Future<void> generateBadgePDF(User user, StoreInfo store, int templateId, {Uint8List? userPhoto}) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm), // Format carte de crédit
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          switch (templateId) {
            case 1:
              return _buildTemplate1(user, store, userPhoto);
            case 2:
              return _buildTemplate2(user, store, userPhoto);
            case 3:
              return _buildTemplate3(user, store, userPhoto);
            case 4:
              return _buildTemplate4(user, store, userPhoto);
            case 5:
              return _buildTemplate5(user, store, userPhoto);
            case 6:
              return _buildTemplate6(user, store, userPhoto);
            case 7:
              return _buildTemplate7(user, store, userPhoto);
            case 8:
              return _buildTemplate8(user, store, userPhoto);
            case 9:
              return _buildTemplate9(user, store, userPhoto);
            case 10:
              return _buildTemplate10(user, store, userPhoto);
            default:
              return _buildTemplate1(user, store, userPhoto);
          }
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Modèle 1 - Classique Bleu
  static pw.Widget _buildTemplate1(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue600],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Row(
          children: [
            // Photo utilisateur
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(25),
                border: pw.Border.all(color: PdfColors.white, width: 2),
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 30, color: PdfColors.blue800),
                    ),
            ),
            pw.SizedBox(width: 12),
            // Informations
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    user.fullName ?? user.username ?? '',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _getRoleDisplayName(user.role ?? ''),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    store.name,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    store.phone,
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modèle 2 - Moderne Vert
  static pw.Widget _buildTemplate2(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      color: PdfColors.white,
      child: pw.Column(
        children: [
          // Header vert
          pw.Container(
            height: 20,
            color: PdfColors.green600,
            child: pw.Center(
              child: pw.Text(
                store.name,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          // Contenu principal
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 40,
                    height: 40,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: userPhoto != null
                        ? pw.ClipRRect(
                            child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                          )
                        : pw.Center(
                            child: pw.Icon(pw.IconData(0xe7fd), size: 25, color: PdfColors.green600),
                          ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          user.fullName ?? user.username ?? '',
                          style: pw.TextStyle(
                            color: PdfColors.green800,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _getRoleDisplayName(user.role ?? ''),
                          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
                        ),
                        pw.Text(
                          store.location,
                          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modèle 3 - Élégant Noir
  static pw.Widget _buildTemplate3(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      color: PdfColors.grey900,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Photo centrée
            pw.Container(
              width: 45,
              height: 45,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(22.5),
                border: pw.Border.all(color: PdfColors.amber, width: 2),
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 25, color: PdfColors.grey900),
                    ),
            ),
            pw.SizedBox(height: 6),
            // Nom
            pw.Text(
              user.fullName ?? user.username ?? '',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              _getRoleDisplayName(user.role ?? ''),
              style: const pw.TextStyle(color: PdfColors.amber, fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
            pw.Spacer(),
            // Footer magasin
            pw.Text(
              store.name,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modèle 4 - Coloré Orange
  static pw.Widget _buildTemplate4(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.orange600, PdfColors.deepOrange800],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 35,
                  height: 35,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(17.5),
                  ),
                  child: userPhoto != null
                      ? pw.ClipRRect(
                          child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Icon(pw.IconData(0xe7fd), size: 20, color: PdfColors.orange600),
                        ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        user.fullName ?? user.username ?? '',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _getRoleDisplayName(user.role ?? ''),
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                store.name,
                style: pw.TextStyle(
                  color: PdfColors.orange800,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modèle 5 - Minimaliste Blanc
  static pw.Widget _buildTemplate5(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      color: PdfColors.white,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  store.name,
                  style: pw.TextStyle(
                    color: PdfColors.blue800,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: 30,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue800, width: 1),
                    borderRadius: pw.BorderRadius.circular(15),
                  ),
                  child: userPhoto != null
                      ? pw.ClipRRect(
                          child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Icon(pw.IconData(0xe7fd), size: 18, color: PdfColors.blue800),
                        ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              user.fullName ?? user.username ?? '',
              style: pw.TextStyle(
                color: PdfColors.grey900,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              _getRoleDisplayName(user.role ?? ''),
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
            ),
            pw.Spacer(),
            pw.Container(
              height: 2,
              color: PdfColors.blue800,
            ),
          ],
        ),
      ),
    );
  }

  // Modèles 6-10 simplifiés pour économiser l'espace
  static pw.Widget _buildTemplate6(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.purple600, PdfColors.pink600],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Row(
          children: [
            pw.Container(
              width: 40,
              height: 40,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 25, color: PdfColors.purple600),
                    ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    user.fullName ?? user.username ?? '',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _getRoleDisplayName(user.role ?? ''),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                  ),
                  pw.Text(
                    store.name,
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplate7(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      color: PdfColors.teal600,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          children: [
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              child: userPhoto != null
                  ? pw.ClipOval(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 30, color: PdfColors.teal600),
                    ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              user.fullName ?? user.username ?? '',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              _getRoleDisplayName(user.role ?? ''),
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplate8(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.indigo800, PdfColors.blue800],
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Row(
          children: [
            pw.Container(
              width: 45,
              height: 45,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(22.5),
                border: pw.Border.all(color: PdfColors.yellow, width: 2),
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 25, color: PdfColors.indigo800),
                    ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    user.fullName ?? user.username ?? '',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _getRoleDisplayName(user.role ?? ''),
                    style: const pw.TextStyle(color: PdfColors.yellow, fontSize: 9),
                  ),
                  pw.Text(
                    store.name,
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplate9(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      color: PdfColors.red600,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              store.name,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 40,
              height: 40,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 25, color: PdfColors.red600),
                    ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              user.fullName ?? user.username ?? '',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              _getRoleDisplayName(user.role ?? ''),
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplate10(User user, StoreInfo store, Uint8List? userPhoto) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.brown600, PdfColors.orange800],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Row(
          children: [
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.black,
                    blurRadius: 2,
                    offset: const PdfPoint(1, 1),
                  ),
                ],
              ),
              child: userPhoto != null
                  ? pw.ClipRRect(
                      child: pw.Image(pw.MemoryImage(userPhoto), fit: pw.BoxFit.cover),
                    )
                  : pw.Center(
                      child: pw.Icon(pw.IconData(0xe7fd), size: 30, color: PdfColors.brown600),
                    ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    user.fullName ?? user.username ?? '',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _getRoleDisplayName(user.role ?? ''),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                  ),
                  pw.Text(
                    store.name,
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'gestionnaire':
        return 'Gestionnaire';
      case 'caissier':
        return 'Caissier';
      case 'vendeur':
        return 'Vendeur';
      default:
        return role;
    }
  }
}