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
import '../providers/reports_provider.dart';
import 'formatters.dart';

CellValue? _text(String v) => TextCellValue(v);
CellValue? _int(int v) => IntCellValue(v);
CellValue? _dbl(double v) => DoubleCellValue(v);

class ExportHelper {
  ExportHelper._();

  static final _numFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy · hh:mm a');

  static String _fmt(double v, String symbol, String pos) {
    final n = _numFmt.format(v);
    return pos == 'left' ? '$symbol$n' : '$n $symbol';
  }

  static Future<Uint8List> buildTransactionsPdf(
    List<Transaction> txns, {
    String currencySymbol = '\$',
    String currencyPosition = 'left',
  }) async {
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
                'Date', 'Type', 'Entity', 'Items',
                'Payment', 'Total', 'Paid', 'Balance'
              ],
              data: [
                for (final t in txns)
                  [
                    _dateTimeFmt.format(t.createdAt),
                    t.type.displayLabel,
                    t.entityName.isNotEmpty ? t.entityName : '\u2014',
                    '${t.items.length}',
                    t.paymentMethod,
                    _fmt(t.totalAmount, currencySymbol, currencyPosition),
                    _fmt(t.paidAmount, currencySymbol, currencyPosition),
                    _fmt(t.balance, currencySymbol, currencyPosition),
                  ],
              ],
              headerStyle: pw.TextStyle(
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

  static Future<List<int>> buildTransactionsExcel(
      List<Transaction> txns) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    sheet.appendRow([
      _text('Date'), _text('Type'), _text('Entity'), _text('Items'),
      _text('Payment Method'), _text('Total'), _text('Discount'),
      _text('Tax'), _text('Paid'), _text('Balance'), _text('Notes'),
    ]);
    for (final t in txns) {
      sheet.appendRow([
        _text(_dateTimeFmt.format(t.createdAt)),
        _text(t.type.displayLabel),
        _text(t.entityName.isNotEmpty ? t.entityName : 'Walk-in'),
        _int(t.items.length),
        _text(t.paymentMethod),
        _dbl(t.totalAmount),
        _dbl(t.discount),
        _dbl(t.taxAmount),
        _dbl(t.paidAmount),
        _dbl(t.balance),
        _text(t.notes),
      ]);
    }
    return excel.save() ?? Uint8List(0);
  }

  static Future<List<int>> buildTransactionExcel(Transaction txn) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoice'];

    sheet.appendRow([_text('Field'), _text('Value')]);
    sheet.appendRow([
      _text('Invoice #'),
      _text(txn.id.substring(0, 8).toUpperCase()),
    ]);
    sheet.appendRow([_text('Date'), _text(_dateTimeFmt.format(txn.createdAt))]);
    sheet.appendRow([_text('Type'), _text(txn.type.displayLabel)]);
    sheet.appendRow([
      _text('Entity'),
      _text(txn.entityName.isNotEmpty ? txn.entityName : 'Walk-in'),
    ]);
    sheet.appendRow([_text('Payment'), _text(txn.paymentMethod)]);
    sheet.appendRow([_text('')]);
    sheet.appendRow([
      _text('Item'), _text('Qty'), _text('Unit'),
      _text('Price'), _text('Subtotal'),
    ]);
    for (final it in txn.items) {
      sheet.appendRow([
        _text(it.productName),
        _int(it.quantity),
        _text(it.productUnit),
        _dbl(it.priceAtTime),
        _dbl(it.lineSubtotal),
      ]);
    }
    sheet.appendRow([_text('')]);
    sheet.appendRow([_text('Discount'), _dbl(txn.discount)]);
    sheet.appendRow([_text('Tax'), _dbl(txn.taxAmount)]);
    sheet.appendRow([_text('Total'), _dbl(txn.totalAmount)]);
    sheet.appendRow([_text('Paid'), _dbl(txn.paidAmount)]);
    sheet.appendRow([_text('Balance'), _dbl(txn.balance)]);
    if (txn.notes.trim().isNotEmpty) {
      sheet.appendRow([_text('')]);
      sheet.appendRow([_text('Notes'), _text(txn.notes)]);
    }
    return excel.save() ?? Uint8List(0);
  }

  static Future<List<int>> buildReportExcel(ReportsProvider p) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    sheet.appendRow([
      _text('Report: ${Formatters.date(p.from)} \u2014 ${_dateFmt.format(p.to)}'),
    ]);
    sheet.appendRow([_text('')]);
    sheet.appendRow([_text('Metric'), _text('Value')]);
    sheet.appendRow([_text('Revenue'), _dbl(p.totalRevenue)]);
    sheet.appendRow([_text('Expenses (COGS)'), _dbl(p.totalExpenses)]);
    sheet.appendRow([_text('Net Profit'), _dbl(p.netProfit)]);
    sheet.appendRow([_text('Sales Count'), _int(p.salesCount)]);
    sheet.appendRow([_text('')]);

    sheet.appendRow([_text('Sales by Day')]);
    sheet.appendRow([_text('Date'), _text('Revenue')]);
    for (final e in p.salesByDay) {
      sheet.appendRow([_text(_dateFmt.format(e.key)), _dbl(e.value)]);
    }
    sheet.appendRow([_text('')]);

    sheet.appendRow([_text('Top Products by Revenue')]);
    sheet.appendRow([_text('Product'), _text('Revenue')]);
    for (final e in p.topProductsByRevenue(limit: 20)) {
      sheet.appendRow([_text(e.key), _dbl(e.value)]);
    }
    sheet.appendRow([_text('')]);

    sheet.appendRow([_text('Revenue by Category')]);
    sheet.appendRow([_text('Category'), _text('Revenue')]);
    for (final e in p.revenueByCategory.entries) {
      sheet.appendRow([_text(e.key), _dbl(e.value)]);
    }

    return excel.save() ?? Uint8List(0);
  }

  static Future<void> sharePdf(Uint8List bytes, String name) async {
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }

  static Future<void> saveAndShareExcel(
      List<int> bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.xlsx');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: name,
    ));
  }
}
