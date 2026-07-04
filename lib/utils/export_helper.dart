import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../providers/reports_provider.dart';
import 'app_constants.dart';
import 'formatters.dart';

class ExportHelper {
  ExportHelper._();

  static final _currency = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy · hh:mm a');

  // ───── PDF: batch transactions report ─────────────────────
  static Future<Uint8List> buildTransactionsPdf(
      List<Transaction> txns) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          children: [
            pw.Text('Transaction Report',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('${txns.length} entries',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Type',
                'Entity',
                'Items',
                'Payment',
                'Total',
                'Paid',
                'Balance'
              ],
              data: [
                for (final t in txns)
                  [
                    _dateTimeFmt.format(t.createdAt),
                    t.type.displayLabel,
                    t.entityName.isNotEmpty ? t.entityName : '—',
                    '${t.items.length}',
                    t.paymentMethod,
                    _currency.format(t.totalAmount),
                    _currency.format(t.paidAmount),
                    _currency.format(t.balance),
                  ],
              ],
              headerStyle: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
              },
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  // ───── Excel: batch transactions ──────────────────────────
  static Future<List<int>> buildTransactionsExcel(
      List<Transaction> txns) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    sheet.appendRow([
      'Date',
      'Type',
      'Entity',
      'Items',
      'Payment Method',
      'Total',
      'Discount',
      'Tax',
      'Paid',
      'Balance',
      'Notes',
    ]);
    for (final t in txns) {
      sheet.appendRow([
        _dateTimeFmt.format(t.createdAt),
        t.type.displayLabel,
        t.entityName.isNotEmpty ? t.entityName : 'Walk-in',
        t.items.length,
        t.paymentMethod,
        t.totalAmount,
        t.discount,
        t.taxAmount,
        t.paidAmount,
        t.balance,
        t.notes,
      ]);
    }
    return excel.save() ?? Uint8List(0);
  }

  // ───── Excel: single transaction with items ───────────────
  static Future<List<int>> buildTransactionExcel(Transaction txn) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoice'];

    sheet.appendRow(['Field', 'Value']);
    sheet.appendRow(['Invoice #', txn.id.substring(0, 8).toUpperCase()]);
    sheet.appendRow(['Date', _dateTimeFmt.format(txn.createdAt)]);
    sheet.appendRow(['Type', txn.type.displayLabel]);
    sheet.appendRow(
        ['Entity', txn.entityName.isNotEmpty ? txn.entityName : 'Walk-in']);
    sheet.appendRow(['Payment', txn.paymentMethod]);
    sheet.appendRow(['']);
    sheet.appendRow(['Item', 'Qty', 'Unit', 'Price', 'Subtotal']);
    for (final it in txn.items) {
      sheet.appendRow([
        it.productName,
        it.quantity,
        it.productUnit,
        it.priceAtTime,
        it.lineSubtotal,
      ]);
    }
    sheet.appendRow(['']);
    sheet.appendRow(['Discount', txn.discount]);
    sheet.appendRow(['Tax', txn.taxAmount]);
    sheet.appendRow(['Total', txn.totalAmount]);
    sheet.appendRow(['Paid', txn.paidAmount]);
    sheet.appendRow(['Balance', txn.balance]);
    if (txn.notes.trim().isNotEmpty) {
      sheet.appendRow(['']);
      sheet.appendRow(['Notes', txn.notes]);
    }
    return excel.save() ?? Uint8List(0);
  }

  // ───── Excel: reports ─────────────────────────────────────
  static Future<List<int>> buildReportExcel(ReportsProvider p) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    sheet.appendRow([
      'Report: ${Formatters.date(p.from)} — ${_dateFmt.format(p.to)}'
    ]);
    sheet.appendRow(['']);
    sheet.appendRow(['Metric', 'Value']);
    sheet.appendRow(['Revenue', p.totalRevenue]);
    sheet.appendRow(['Expenses (COGS)', p.totalExpenses]);
    sheet.appendRow(['Net Profit', p.netProfit]);
    sheet.appendRow(['Sales Count', p.salesCount]);
    sheet.appendRow(['']);

    sheet.appendRow(['Sales by Day']);
    sheet.appendRow(['Date', 'Revenue']);
    for (final e in p.salesByDay) {
      sheet.appendRow([_dateFmt.format(e.key), e.value]);
    }
    sheet.appendRow(['']);

    sheet.appendRow(['Top Products by Revenue']);
    sheet.appendRow(['Product', 'Revenue']);
    for (final e in p.topProductsByRevenue(limit: 20)) {
      sheet.appendRow([e.key, e.value]);
    }
    sheet.appendRow(['']);

    sheet.appendRow(['Revenue by Category']);
    sheet.appendRow(['Category', 'Revenue']);
    for (final e in p.revenueByCategory.entries) {
      sheet.appendRow([e.key, e.value]);
    }

    return excel.save() ?? Uint8List(0);
  }

  // ───── Share helpers ──────────────────────────────────────
  static Future<void> sharePdf(Uint8List bytes, String name) async {
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }

  static Future<void> saveAndShareExcel(
      List<int> bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: name);
  }
}
