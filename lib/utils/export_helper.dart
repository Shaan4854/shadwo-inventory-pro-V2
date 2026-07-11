import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/transaction.dart';
import '../providers/reports_provider.dart';
import 'entity_helpers.dart';
import 'formatters.dart';

CellValue? _text(String v) => TextCellValue(v);
CellValue? _int(int v) => IntCellValue(v);
CellValue? _dbl(double v) => DoubleCellValue(v);

class ExportHelper {
  ExportHelper._();

  static String _businessName = '';
  static String _businessAddress = '';

  static void setBusinessInfo(String name, String address) {
    _businessName = name;
    _businessAddress = address;
  }
  static Future<Uint8List> buildTransactionsPdf(
    List<Transaction> txns, {
    String currencySymbol = '\$',
    String currencyPosition = 'left',
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (_businessName.isNotEmpty)
              pw.Text(_businessName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (_businessAddress.isNotEmpty)
              pw.Text(_businessAddress,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
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
                    Formatters.dateTime(t.createdAt),
                    t.type.displayLabel,
                    resolveEntityName(t.entityName),
                    '${t.items.length}',
                    t.paymentMethod,
                    Formatters.currency(t.totalAmount),
                    Formatters.currency(t.paidAmount),
                    Formatters.currency(t.balance),
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
        _text(Formatters.dateTime(t.createdAt)),
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
      _text(txn.id.length >= 8 ? txn.id.substring(0, 8).toUpperCase() : txn.id.toUpperCase()),
    ]);
    sheet.appendRow([_text('Date'), _text(Formatters.dateTime(txn.createdAt))]);
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
      _text('Report: ${Formatters.date(p.from)} \u2014 ${Formatters.date(p.to)}'),
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
      sheet.appendRow([_text(Formatters.date(e.key)), _dbl(e.value)]);
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

  /// A single line in a customer/supplier statement.
  static StatementRow statementRow({
    required DateTime date,
    required String description,
    required String type,
    required double amount,
    required double balance,
  }) =>
      StatementRow(
        date: date,
        description: description,
        type: type,
        amount: amount,
        balance: balance,
      );

  static Future<Uint8List> buildStatementPdf({
    required String entityName,
    required String entityType,
    required double openingBalance,
    required double closingBalance,
    required List<StatementRow> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (_businessName.isNotEmpty)
              pw.Text(_businessName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (_businessAddress.isNotEmpty)
              pw.Text(_businessAddress,
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
            pw.Text('$entityType Statement',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(entityName, style: pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Opening Balance', style: pw.TextStyle(fontSize: 10)),
                pw.Text(Formatters.currency(openingBalance),
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Closing Balance', style: pw.TextStyle(fontSize: 10)),
                pw.Text(Formatters.currency(closingBalance),
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date', 'Type', 'Description', 'Amount', 'Balance'
              ],
              data: [
                for (final r in rows)
                  [
                    Formatters.date(r.date),
                    r.type,
                    r.description,
                    Formatters.currency(r.amount),
                    Formatters.currency(r.balance),
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
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static Future<List<int>> buildMasterDataExcel(
    List<List<Object>> header,
    List<List<Object>> rows, {
    required String sheetName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];
    sheet.appendRow(header.map((h) => _cell(h)).toList());
    for (final r in rows) {
      sheet.appendRow(r.map((c) => _cell(c)).toList());
    }
    return excel.save() ?? Uint8List(0);
  }

  static CellValue _cell(Object v) {
    if (v is int) return IntCellValue(v);
    if (v is double) return DoubleCellValue(v);
    return TextCellValue(v.toString());
  }

  /// Exports Products, Customers and Suppliers into a single multi-sheet
  /// workbook for backup / migration.
  static Future<List<int>> buildMasterDataExport({
    required List<Product> products,
    required List<Customer> customers,
    required List<Supplier> suppliers,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Products');
    final pSheet = excel['Products'];
    pSheet.appendRow([
      _text('Name'), _text('SKU'), _text('Brand'), _text('Category'),
      _text('Stock'), _text('Unit'), _text('Buy Price'),
      _text('Sell Price'), _text('Alert'), _text('Barcode'),
    ]);
    for (final p in products) {
      pSheet.appendRow([
        _text(p.name), _text(p.sku), _text(p.brand), _text(p.category),
        _int(p.stock), _text(p.unit), _dbl(p.buyPrice), _dbl(p.sellPrice),
        _int(p.alertThreshold), _text(p.barcode),
      ]);
    }

    final cSheet = excel['Customers'];
    cSheet.appendRow([
      _text('Name'), _text('Mobile'), _text('Email'), _text('Address'),
      _text('GST/VAT'), _text('Outstanding'),
    ]);
    for (final c in customers) {
      cSheet.appendRow([
        _text(c.name), _text(c.mobile), _text(c.email), _text(c.address),
        _text(c.gstVat), _dbl(c.outstandingBalance),
      ]);
    }

    final sSheet = excel['Suppliers'];
    sSheet.appendRow([
      _text('Name'), _text('Contact'), _text('Mobile'), _text('Email'),
      _text('Address'), _text('GST/VAT'), _text('Outstanding'),
    ]);
    for (final s in suppliers) {
      sSheet.appendRow([
        _text(s.name), _text(s.contactPerson), _text(s.mobile), _text(s.email),
        _text(s.address), _text(s.gstVat), _dbl(s.outstandingBalance),
      ]);
    }
    return excel.save() ?? Uint8List(0);
  }
}

class StatementRow {
  const StatementRow({
    required this.date,
    required this.description,
    required this.type,
    required this.amount,
    required this.balance,
  });
  final DateTime date;
  final String description;
  final String type;
  final double amount;
  final double balance;
}
