import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction.dart';
import '../../data/models/budget.dart';

class PdfExporter {
  PdfExporter._();

  /// Generates a beautiful vector PDF ledger statement and opens native system sharing
  static Future<void> generateAndShareReport({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required String currencySymbol,
    required double monthlyIncome,
  }) async {
    // Load custom fonts to support dynamic currency glyphs (e.g. ₹, €, etc.)
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: robotoRegular,
        bold: robotoBold,
        italic: robotoItalic,
      ),
    );

    // Calculate financials
    double totalIncome = monthlyIncome;
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (final tx in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    final dateRangeString = DateFormat('MMMM yyyy').format(DateTime.now());

    // Define PDF stylesheet styles
    final fontTitle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 24,
      color: PdfColors.indigo900,
    );
    final fontHeader = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 13,
      color: PdfColors.blueGrey800,
    );
    final fontBody = const pw.TextStyle(
      fontSize: 10,
      color: PdfColors.blueGrey900,
    );
    final fontBold = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
      color: PdfColors.blueGrey900,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. BRAND HEADER & LETTERHEAD
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TRACKLY PRO', style: fontTitle),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'PREMIUM WEALTH INTELLIGENCE REPORT',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.blueGrey400,
                        letterSpacing: 1.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT PERIOD',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.blueGrey400,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(dateRangeString.toUpperCase(), style: fontBold),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 2, color: PdfColors.indigo700),
            pw.SizedBox(height: 24),

            // 2. FINANCIAL METRICS TILES GRID
            pw.Row(
              children: [
                _buildPdfMetricTile(
                  'TOTAL INFLOW',
                  '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                  PdfColors.green700,
                  fontBold,
                ),
                pw.SizedBox(width: 16),
                _buildPdfMetricTile(
                  'TOTAL OUTFLOW',
                  '$currencySymbol${totalExpense.toStringAsFixed(2)}',
                  PdfColors.red700,
                  fontBold,
                ),
                pw.SizedBox(width: 16),
                _buildPdfMetricTile(
                  'NET CASH BALANCE',
                  '$currencySymbol${netBalance.toStringAsFixed(2)}',
                  netBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                  fontBold,
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // 3. CATEGORY ALLOCATION BREAKDOWN
            pw.Text('CATEGORY SPENDING ANALYSIS', style: fontHeader),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Table Header
                pw.TableRow(
                  children: [
                    _buildTableCell(
                      'Category',
                      fontBold,
                      align: pw.TextAlign.left,
                      backgroundColor: PdfColors.grey100,
                    ),
                    _buildTableCell(
                      'Total Allocated Spent',
                      fontBold,
                      align: pw.TextAlign.right,
                      backgroundColor: PdfColors.grey100,
                    ),
                    _buildTableCell(
                      'Percentage Share',
                      fontBold,
                      align: pw.TextAlign.right,
                      backgroundColor: PdfColors.grey100,
                    ),
                  ],
                ),
                // Table Rows
                ...categoryTotals.entries.map((entry) {
                  final percent = totalExpense > 0
                      ? (entry.value / totalExpense) * 100
                      : 0.0;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        entry.key,
                        fontBody,
                        align: pw.TextAlign.left,
                      ),
                      _buildTableCell(
                        '$currencySymbol${entry.value.toStringAsFixed(2)}',
                        fontBody,
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        '${percent.toStringAsFixed(1)}%',
                        fontBody,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 32),

            // 4. CHRONOLOGICAL TRANSACTIONS LEDGER
            pw.Text('CHRONOLOGICAL TRANSACTIONS LEDGER', style: fontHeader),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                // Header Row
                pw.TableRow(
                  children: [
                    _buildTableCell(
                      'Date',
                      fontBold,
                      align: pw.TextAlign.left,
                      backgroundColor: PdfColors.grey200,
                    ),
                    _buildTableCell(
                      'Title Details',
                      fontBold,
                      align: pw.TextAlign.left,
                      backgroundColor: PdfColors.grey200,
                    ),
                    _buildTableCell(
                      'Category',
                      fontBold,
                      align: pw.TextAlign.left,
                      backgroundColor: PdfColors.grey200,
                    ),
                    _buildTableCell(
                      'Flow',
                      fontBold,
                      align: pw.TextAlign.center,
                      backgroundColor: PdfColors.grey200,
                    ),
                    _buildTableCell(
                      'Amount',
                      fontBold,
                      align: pw.TextAlign.right,
                      backgroundColor: PdfColors.grey200,
                    ),
                  ],
                ),
                // Data Rows
                ...transactions.map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  final dateFormatted = DateFormat(
                    'MMM dd, yyyy',
                  ).format(tx.date);

                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        dateFormatted,
                        fontBody,
                        align: pw.TextAlign.left,
                      ),
                      _buildTableCell(
                        tx.title,
                        fontBody,
                        align: pw.TextAlign.left,
                      ),
                      _buildTableCell(
                        tx.category,
                        fontBody,
                        align: pw.TextAlign.left,
                      ),
                      _buildTableCell(
                        isIncome ? 'INFLOW' : 'OUTFLOW',
                        pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: isIncome
                              ? PdfColors.green700
                              : PdfColors.red700,
                        ),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        '${isIncome ? '+' : '-'}$currencySymbol${tx.amount.toStringAsFixed(2)}',
                        pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: isIncome
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Trackly Pro Ledger Synced Node [CLIENT-SANDBOX]',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and Share PDF dynamically using printing library
    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'TracklyPro_Ledger_${dateRangeString.replaceAll(' ', '_')}.pdf',
    );
  }

  // PDF grid card helper builder
  static pw.Widget _buildPdfMetricTile(
    String label,
    String value,
    PdfColor accentColor,
    pw.TextStyle fontBold,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey400,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: fontBold.copyWith(fontSize: 14, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  // PDF tablecell helper builder
  static pw.Widget _buildTableCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? backgroundColor,
  }) {
    final cell = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(text, style: style, textAlign: align),
    );
    if (backgroundColor != null) {
      return pw.Container(color: backgroundColor, child: cell);
    }
    return cell;
  }
}
