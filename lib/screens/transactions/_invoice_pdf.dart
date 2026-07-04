import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../utils/app_constants.dart';

/// Minimal PDF invoice. Uses `pdf` package's built-in Helvetica (no
/// bundled font asset). Renderer is intentionally boring — headline,
/// table, totals, footer. Extend when the design brief has an invoice
/// mockup.
class InvoicePdf {
  InvoicePdf._();

  static Future<Uint8List> build(Transaction txn) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.appName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        txn.type.displayLabel,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice #${txn.id.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dateFmt.format(txn.createdAt),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              if (txn.entityName.isNotEmpty)
                pw.Text(
                  txn.type == TransactionType.purchase
                      ? 'Supplier: ${txn.entityName}'
                      : 'Customer: ${txn.entityName}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const ['Item', 'Qty', 'Unit', 'Line total'],
                data: [
                  for (final item in txn.items)
                    [
                      item.productName,
                      '${item.quantity} ${item.productUnit}',
                      currency.format(item.priceAtTime),
                      currency.format(item.lineSubtotal),
                    ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: const {
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                cellStyle: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _totalRow('Discount',
                            '- ${currency.format(txn.discount)}'),
                        _totalRow('Tax', currency.format(txn.taxAmount)),
                        pw.Divider(),
                        _totalRow(
                          'Total',
                          currency.format(txn.totalAmount),
                          bold: true,
                        ),
                        _totalRow(
                          'Paid',
                          currency.format(txn.paidAmount),
                        ),
                        if (txn.balance > 0)
                          _totalRow(
                            'Balance',
                            currency.format(txn.balance),
                            color: PdfColors.red,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontSize: bold ? 13 : 11,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
