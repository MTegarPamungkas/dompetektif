import 'dart:convert';

import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl();

  @override
  Future<ExportResult> export(
    ExportRequest request,
    ExportFormat format,
  ) async {
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final baseName =
        'dompetektif-${request.periodStart.year}${request.periodStart.month.toString().padLeft(2, '0')}-$stamp';

    return switch (format) {
      ExportFormat.csv => _exportCsv(request, baseName),
      ExportFormat.pdf => _exportPdf(request, baseName),
    };
  }

  Future<ExportResult> _exportCsv(
    ExportRequest request,
    String baseName,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Date,Type,Category,Wallet,Destination,Merchant,Note,Amount,Currency',
    );

    for (final entry in request.entries) {
      final transaction = entry.transaction;
      final amount = transaction.amount.amountMinor;
      final amountValue = transaction.amount.currency == 'IDR'
          ? amount.toString()
          : (amount / 100).toStringAsFixed(2);
      buffer.writeln(
        [
          DateFormat('yyyy-MM-dd HH:mm').format(transaction.occurredAt),
          _typeLabel(transaction.type, request.localeCode),
          entry.category?.name ?? '',
          entry.wallet.name,
          entry.toWallet?.name ?? '',
          transaction.merchant,
          transaction.note,
          amountValue,
          transaction.amount.currency,
        ].map(_csvCell).join(','),
      );
    }

    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$buffer'));
    final savedPath = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
    return ExportResult(
      fileName: '$baseName.csv',
      byteCount: bytes.length,
      savedPath: savedPath,
    );
  }

  Future<ExportResult> _exportPdf(
    ExportRequest request,
    String baseName,
  ) async {
    final baseFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final mediumFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
    final serifFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/InstrumentSerif-Regular.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: baseFont,
      ),
    );

    final totals = _totals(request.entries);
    final locale = request.localeCode;
    final isId = locale != 'en';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Dompetektif • ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DOMPETEKTIF',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      letterSpacing: 2.4,
                      color: PdfColor.fromInt(0xFF9A6B0D),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    isId ? 'Laporan Penyelidikan' : 'Investigation Report',
                    style: pw.TextStyle(font: serifFont, fontSize: 32),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${CaseDates.fullDate(request.periodStart, locale)} — ${CaseDates.fullDate(request.periodEnd, locale)}',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFE8B84B),
                    width: 1.2,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      request.walletName ??
                          (isId ? 'Semua dompet' : 'All wallets'),
                      style: pw.TextStyle(font: mediumFont, fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${request.entries.length} ${isId ? 'transaksi' : 'transactions'}',
                      style: pw.TextStyle(
                        font: baseFont,
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _summaryBox(
                isId ? 'Pemasukan' : 'Income',
                MoneyFormatter.format(
                  totals.$1,
                  currency: 'IDR',
                  localeCode: locale,
                ),
                PdfColor.fromInt(0xFF2F7B55),
                mediumFont,
              ),
              pw.SizedBox(width: 10),
              _summaryBox(
                isId ? 'Pengeluaran' : 'Spending',
                MoneyFormatter.format(
                  totals.$2,
                  currency: 'IDR',
                  localeCode: locale,
                ),
                PdfColor.fromInt(0xFFB8442D),
                mediumFont,
              ),
              pw.SizedBox(width: 10),
              _summaryBox(
                isId ? 'Selisih bersih' : 'Net difference',
                MoneyFormatter.format(
                  totals.$1 - totals.$2,
                  currency: 'IDR',
                  localeCode: locale,
                  signed: true,
                ),
                PdfColor.fromInt(0xFF171812),
                mediumFont,
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            isId ? 'RINCIAN BARANG BUKTI' : 'EVIDENCE LEDGER',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 9,
              letterSpacing: 1.8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              isId ? 'Tanggal' : 'Date',
              isId ? 'Jenis' : 'Type',
              isId ? 'Kategori' : 'Category',
              isId ? 'Dompet' : 'Wallet',
              isId ? 'Catatan' : 'Note',
              isId ? 'Nominal' : 'Amount',
            ],
            data: request.entries
                .map(
                  (entry) => [
                    DateFormat('dd/MM/yy').format(entry.transaction.occurredAt),
                    _typeLabel(entry.transaction.type, locale),
                    entry.category?.name ?? '—',
                    entry.wallet.name,
                    _shortNote(entry.transaction),
                    MoneyFormatter.format(
                      entry.transaction.amount.amountMinor,
                      currency: entry.transaction.amount.currency,
                      localeCode: locale,
                    ),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF171812),
            ),
            cellStyle: pw.TextStyle(font: baseFont, fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {5: pw.Alignment.centerRight},
            oddRowDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF6F1E5),
            ),
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(
                color: PdfColor.fromInt(0xFFD8CEB9),
                width: 0.4,
              ),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.0),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.3),
              4: const pw.FlexColumnWidth(2.6),
              5: const pw.FlexColumnWidth(1.6),
            },
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF6F1E5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isId ? 'CATATAN PENYELIDIKAN' : 'INVESTIGATION NOTE',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    letterSpacing: 1.6,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  isId
                      ? 'Laporan ini dibuat otomatis dari data yang tersimpan di perangkat. Periksa kembali bukti fisik sebelum mengambil keputusan finansial.'
                      : 'This report was generated from data stored on device. Verify physical evidence before making financial decisions.',
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 8.5,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final savedPath = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return ExportResult(
      fileName: '$baseName.pdf',
      byteCount: bytes.length,
      savedPath: savedPath,
    );
  }

  pw.Widget _summaryBox(
    String label,
    String value,
    PdfColor color,
    pw.Font font,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColor.fromInt(0xFFE3DAC7),
            width: 0.7,
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                letterSpacing: 1.2,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }

  (int, int) _totals(List<dynamic> entries) {
    var income = 0;
    var expense = 0;
    for (final entry in entries) {
      final transaction = entry.transaction as Transaction;
      if (transaction.type == TransactionType.income) {
        income += transaction.amount.amountMinor;
      } else if (transaction.type == TransactionType.expense) {
        expense += transaction.amount.amountMinor;
      }
    }
    return (income, expense);
  }

  String _shortNote(Transaction transaction) {
    final value = transaction.note.trim().isEmpty
        ? transaction.merchant.trim()
        : transaction.note.trim();
    if (value.isEmpty) return '—';
    return value.length > 44 ? '${value.substring(0, 41)}…' : value;
  }

  String _typeLabel(TransactionType type, String localeCode) {
    final isId = localeCode != 'en';
    return switch (type) {
      TransactionType.expense => isId ? 'Pengeluaran' : 'Expense',
      TransactionType.income => isId ? 'Pemasukan' : 'Income',
      TransactionType.transfer => isId ? 'Transfer' : 'Transfer',
    };
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
