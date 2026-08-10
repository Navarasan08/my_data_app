import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:my_data_app/src/home/home_record_model.dart';

/// Outcome of an import attempt — rows we successfully turned into records,
/// plus a count of rows we couldn't parse with a short reason for the user.
class ImportResult {
  final List<HomeRecord> imported;
  final List<HomeRecord> duplicatesSkipped;
  final List<String> errors;

  const ImportResult({
    required this.imported,
    required this.duplicatesSkipped,
    required this.errors,
  });

  int get newCount => imported.length;
  int get skippedCount => duplicatesSkipped.length;
  int get errorCount => errors.length;
}

class ExpenseIoService {
  static const List<String> columns = [
    'Date',
    'Title',
    'Category',
    'Amount',
    'Quantity',
    'Unit',
    'Payment Type',
    'Description',
    'Notes',
    'Type', // 'Expense' | 'Income' — appended last so older files still import
  ];

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // ── Filtering ─────────────────────────────────────────────────────────────

  static List<HomeRecord> recordsInRange(
    List<HomeRecord> records,
    DateTime start,
    DateTime end,
  ) {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return records
        .where((r) => !r.date.isBefore(from) && !r.date.isAfter(to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Encode rows ───────────────────────────────────────────────────────────

  static List<List<String>> _rows(List<HomeRecord> records) {
    final rows = <List<String>>[columns];
    for (final r in records) {
      rows.add([
        _dateFormat.format(r.date),
        r.title,
        r.category.displayName,
        r.amount.toString(),
        r.quantity == null
            ? ''
            : (r.quantity! % 1 == 0
                ? r.quantity!.toInt().toString()
                : r.quantity!.toString()),
        r.unit?.name ?? '',
        r.paymentType?.displayName ?? '',
        r.description ?? '',
        r.notes ?? '',
        r.isIncome ? 'Income' : 'Expense',
      ]);
    }
    return rows;
  }

  // ── Export ────────────────────────────────────────────────────────────────

  /// Write [records] as CSV to a temp file and return the file path.
  static Future<String> exportToCsv(
    List<HomeRecord> records, {
    String filenameSlug = 'expenses',
  }) async {
    final csv = const ListToCsvConverter().convert(_rows(records));
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/${filenameSlug}_${_stampNow()}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }

  /// Write [records] as `.xlsx` to a temp file and return the file path.
  static Future<String> exportToExcel(
    List<HomeRecord> records, {
    String filenameSlug = 'expenses',
  }) async {
    final excel = Excel.createExcel();
    // The default sheet is named 'Sheet1' — rename to "Expenses" but keep
    // the workbook tidy by removing any other sheets that may exist.
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, 'Expenses');
    final sheet = excel['Expenses'];

    final rows = _rows(records);
    // Header row with bold styling.
    for (int c = 0; c < rows[0].length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(rows[0][c]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#EDEDED'),
      );
    }
    // Data rows. Amount + Quantity go in as numbers so spreadsheet apps
    // can sum / filter them directly.
    for (int r = 1; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: c, rowIndex: r));
        final value = rows[r][c];
        if (c == 3) {
          // Amount column
          final n = double.tryParse(value);
          cell.value = n == null ? TextCellValue(value) : DoubleCellValue(n);
        } else if (c == 4 && value.isNotEmpty) {
          // Quantity column
          final n = double.tryParse(value);
          cell.value = n == null ? TextCellValue(value) : DoubleCellValue(n);
        } else {
          cell.value = TextCellValue(value);
        }
      }
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to encode Excel workbook');
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/${filenameSlug}_${_stampNow()}.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Parse [path] (`.csv` or `.xlsx`) into [HomeRecord]s. [existing] is used
  /// to skip rows whose date+title (case-insensitive) already exists, and to
  /// resolve category / payment-type names back to objects.
  static Future<ImportResult> importFromFile(
    String path, {
    required List<HomeCategory> allCategories,
    required List<PaymentType> paymentTypes,
    required List<HomeRecord> existing,
  }) async {
    final lower = path.toLowerCase();
    List<List<String>> rows;
    if (lower.endsWith('.csv')) {
      rows = await _readCsv(path);
    } else if (lower.endsWith('.xlsx')) {
      rows = await _readExcel(path);
    } else {
      throw Exception('Unsupported file type — expected .csv or .xlsx');
    }
    return _rowsToResult(
      rows,
      allCategories: allCategories,
      paymentTypes: paymentTypes,
      existing: existing,
    );
  }

  static Future<List<List<String>>> _readCsv(String path) async {
    final content = await File(path).readAsString();
    final raw = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);
    return raw
        .map((row) => row.map((e) => e == null ? '' : e.toString()).toList())
        .toList();
  }

  static Future<List<List<String>>> _readExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final out = <List<String>>[];
    for (final row in sheet.rows) {
      final mapped = row.map((c) {
        final v = c?.value;
        if (v == null) return '';
        if (v is TextCellValue) return v.value.text ?? '';
        if (v is IntCellValue) return v.value.toString();
        if (v is DoubleCellValue) {
          final d = v.value;
          return d % 1 == 0 ? d.toInt().toString() : d.toString();
        }
        if (v is DateCellValue) {
          return DateFormat('yyyy-MM-dd')
              .format(DateTime(v.year, v.month, v.day));
        }
        return v.toString();
      }).toList();
      out.add(mapped);
    }
    return out;
  }

  static ImportResult _rowsToResult(
    List<List<String>> rows, {
    required List<HomeCategory> allCategories,
    required List<PaymentType> paymentTypes,
    required List<HomeRecord> existing,
  }) {
    if (rows.isEmpty) {
      return const ImportResult(
        imported: [],
        duplicatesSkipped: [],
        errors: ['File is empty'],
      );
    }

    // Header → column index. We're forgiving — match on lowercase to allow
    // user-edited headers; missing optional columns are fine.
    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    int idx(String name) => header.indexOf(name.toLowerCase());

    final cDate = idx('Date');
    final cTitle = idx('Title');
    final cCategory = idx('Category');
    final cAmount = idx('Amount');
    final cQuantity = idx('Quantity');
    final cUnit = idx('Unit');
    final cPayment = idx('Payment Type');
    final cDescription = idx('Description');
    final cNotes = idx('Notes');
    final cType = idx('Type');

    if (cDate == -1 || cTitle == -1 || cAmount == -1) {
      return const ImportResult(
        imported: [],
        duplicatesSkipped: [],
        errors: [
          'Missing required columns. Need at least Date, Title, Amount.'
        ],
      );
    }

    final catByName = {
      for (final c in allCategories) c.displayName.toLowerCase(): c,
    };
    final paymentByName = {
      for (final p in paymentTypes) p.displayName.toLowerCase(): p,
    };
    final unitByName = {
      for (final u in MeasureUnit.values) u.name.toLowerCase(): u,
    };
    final dupKeys = {
      for (final r in existing)
        '${_dateFormat.format(r.date)}|${r.title.toLowerCase().trim()}',
    };

    final imported = <HomeRecord>[];
    final duplicates = <HomeRecord>[];
    final errors = <String>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      String cell(int c) =>
          (c >= 0 && c < row.length) ? row[c].trim() : '';

      try {
        final dateStr = cell(cDate);
        final title = cell(cTitle);
        final amountStr = cell(cAmount);
        if (dateStr.isEmpty && title.isEmpty && amountStr.isEmpty) {
          continue; // silently skip blank rows
        }
        if (dateStr.isEmpty || title.isEmpty || amountStr.isEmpty) {
          errors.add('Row ${i + 1}: missing date / title / amount');
          continue;
        }
        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Row ${i + 1}: invalid date "$dateStr"');
          continue;
        }
        final amount = double.tryParse(amountStr.replaceAll(',', ''));
        if (amount == null) {
          errors.add('Row ${i + 1}: invalid amount "$amountStr"');
          continue;
        }

        // Missing/blank Type column (older files) means expense.
        final isIncome = cell(cType).toLowerCase() == 'income';

        final fallbackCategory =
            isIncome ? HomeCategory.otherIncome : HomeCategory.groceries;
        final categoryRaw = cell(cCategory);
        final category = categoryRaw.isEmpty
            ? fallbackCategory
            : (catByName[categoryRaw.toLowerCase()] ?? fallbackCategory);

        final qtyStr = cell(cQuantity);
        final qty = qtyStr.isEmpty ? null : double.tryParse(qtyStr);
        final unitName = cell(cUnit);
        final unit = qty == null
            ? null
            : (unitByName[unitName.toLowerCase()] ?? MeasureUnit.piece);

        final paymentName = cell(cPayment);
        final paymentType =
            paymentName.isEmpty ? null : paymentByName[paymentName.toLowerCase()];

        final description = cell(cDescription);
        final notes = cell(cNotes);

        final key =
            '${_dateFormat.format(date)}|${title.toLowerCase().trim()}';
        final record = HomeRecord(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          title: title,
          category: category,
          amount: amount,
          date: date,
          description: description.isEmpty ? null : description,
          notes: notes.isEmpty ? null : notes,
          quantity: qty,
          unit: unit,
          paymentType: paymentType,
          isIncome: isIncome,
        );
        if (dupKeys.contains(key)) {
          duplicates.add(record);
        } else {
          imported.add(record);
          dupKeys.add(key);
        }
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
      }
    }

    return ImportResult(
      imported: imported,
      duplicatesSkipped: duplicates,
      errors: errors,
    );
  }

  /// Lenient date parser — accepts yyyy-MM-dd, dd/MM/yyyy, dd-MM-yyyy, or
  /// a Dart ISO 8601 string.
  static DateTime? _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}
    final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(s);
    if (m != null) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final y = int.parse(m.group(3)!);
      try {
        return DateTime(y, mo, d);
      } catch (_) {}
    }
    return null;
  }

  static String _stampNow() {
    final n = DateTime.now();
    return DateFormat('yyyyMMdd_HHmmss').format(n);
  }
}
