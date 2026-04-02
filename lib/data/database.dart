import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_bahi_khata/data/pbke_file.dart';
import 'package:personal_bahi_khata/data/sms_api.dart';
import 'package:personal_bahi_khata/data/expenses.dart';

class DataBase {
  static const String applicationId = "com.vins.personal_bahi_khata";
  static const String unsupportedFileTypeMessage = "unsupported file type";
  static const String unsupportedFileMessage = PbkeFile.unsupportedFileMessage;
  static const List<String> expenseFileKeys = [
    "name",
    "label",
    "id",
    "date",
    "amount",
    "isDebit",
    "isSMS",
  ];
  static const List<String> privateExpenseFileKeys = [
    "name",
    "label",
    "date",
    "amount",
  ];
  static List<Expense> expenses = [];
  static Set<String> uniqueTags = {};
  static List<String> selectedTags = [];
  static DateTime? selectedDate;
  static Set<int> uniqueyears = {};
  static String filepath = '';
  static bool smsExpensesEnabled = false;

  static String libDir = '';

  static String? downDir;
  static const String signature = PbkeFile.signature;
  static const String version = PbkeFile.version;
  static const int headerSize = PbkeFile.headerSize;

  static List<Directory>? dirs;

  static bool isPermitted = false;
  static void createInitialData() {
    expenses = [];
  }

  static void loadData() {
    debugPrint("json $json");

    loadExpenses().then((value) {
      expenses = Expense.listFromRawJson(json);
    });
  }

  //FileHandlerWR.writeToFile('fis', jsonEncode(encryptedCompressedJson));

  void updateDatabase(DateTime? lastDate) {
    persistCurrentExpenses(date: lastDate);
  }

  static String json = """{"expenses":[]}""";
  static File? expFile;
  static Future<void> Function(String newJson, DateTime? date)?
  saveExpensesHook;

  static Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw const FileSystemException("Storage directory is unavailable");
      }
      return directory;
    }

    if (Platform.isLinux) {
      final home = Platform.environment["HOME"];
      if (home == null || home.isEmpty) {
        throw const FileSystemException("HOME is not available");
      }
      return Directory(
        "$home/.local/state/$applicationId",
      ).create(recursive: true);
    }

    return (await getApplicationSupportDirectory()).create(recursive: true);
  }

  static Future<Directory> _getExportDirectory() async {
    if (Platform.isLinux) {
      final exportDirectory = Directory(
        "${(await _getStorageDirectory()).path}/exports",
      );
      return exportDirectory.create(recursive: true);
    }

    return await getTemporaryDirectory();
  }

  static String getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf(".");
    if (lastDot == -1 || lastDot == filePath.length - 1) {
      return "";
    }
    return filePath.substring(lastDot + 1).toLowerCase();
  }

  static void validateImportFileType(String filePath) {
    final extension = getFileExtension(filePath);
    if (extension != "json" && extension != "pbke" && extension != "csv") {
      throw const FormatException(unsupportedFileTypeMessage);
    }
  }

  static bool _matchesExpenseKeys(List<String> headers) {
    if (headers.length != expenseFileKeys.length) {
      return false;
    }

    for (int index = 0; index < expenseFileKeys.length; index++) {
      if (headers[index].trim() != expenseFileKeys[index]) {
        return false;
      }
    }

    return true;
  }

  static Map<String, dynamic> _normalizeImportedExpenseMap(
    Map<String, dynamic> item,
  ) {
    final normalized = Map<String, dynamic>.from(item);

    if (normalized["id"] != null) {
      normalized["id"] = normalized["id"].toString();
    }
    if (normalized["amount"] != null) {
      normalized["amount"] = normalized["amount"].toString();
    }

    if (normalized["label"] is String) {
      normalized["label"] = _decodeCsvLabels(normalized["label"] as String);
    }

    if (normalized["label"] == null) {
      normalized["label"] = <String>[];
    }

    if (!normalized.containsKey("isSMS")) {
      normalized["isSMS"] = false;
    }

    return normalized;
  }

  static String _stripUtf8Bom(String content) {
    if (content.isNotEmpty && content.codeUnitAt(0) == 0xFEFF) {
      return content.substring(1);
    }
    return content;
  }

  static List<dynamic> _extractJsonExpenseItems(dynamic decodedJson) {
    if (decodedJson is List) {
      return decodedJson;
    }

    if (decodedJson is Map<String, dynamic> &&
        decodedJson["expenses"] is List) {
      return List<dynamic>.from(decodedJson["expenses"] as List);
    }

    throw const FormatException(unsupportedFileMessage);
  }

  static void _validateExpenseMap(
    Map<String, dynamic> item, {
    required bool requireExactKeys,
  }) {
    if (requireExactKeys) {
      const requiredKeys = {"name", "label", "id", "date", "amount", "isDebit"};
      final itemKeys = item.keys.toSet();
      if (!itemKeys.containsAll(requiredKeys)) {
        throw const FormatException(unsupportedFileMessage);
      }
    }

    if (item["name"] is! String ||
        item["id"] is! String ||
        item["date"] is! String ||
        item["amount"] is! String ||
        item["isDebit"] is! bool ||
        item["isSMS"] is! bool) {
      throw const FormatException(unsupportedFileMessage);
    }

    final label = item["label"];
    if (label != null &&
        (label is! List || label.any((value) => value is! String))) {
      throw const FormatException(unsupportedFileMessage);
    }

    try {
      DateTime.parse(item["date"] as String);
      double.parse(item["amount"] as String);
    } catch (_) {
      throw const FormatException(unsupportedFileMessage);
    }
  }

  static List<Expense> _decodeExpenseList(dynamic decodedJson) {
    final expenseItems = _extractJsonExpenseItems(decodedJson);

    return List<Expense>.from(
      expenseItems.map((item) {
        if (item is! Map) {
          throw const FormatException(unsupportedFileMessage);
        }
        final expenseMap = _normalizeImportedExpenseMap(
          Map<String, dynamic>.from(item),
        );
        _validateExpenseMap(expenseMap, requireExactKeys: true);
        return Expense.fromJson(expenseMap);
      }),
    );
  }

  static List<Expense> _decodePbkeExpenses(dynamic decodedJson) {
    if (decodedJson is! Map<String, dynamic> ||
        decodedJson["expenses"] is! List) {
      throw const FormatException(unsupportedFileMessage);
    }

    return List<Expense>.from(
      (decodedJson["expenses"] as List).map((item) {
        final expenseMap = Map<String, dynamic>.from(item);
        _validateExpenseMap(expenseMap, requireExactKeys: false);
        return Expense.fromJson(expenseMap);
      }),
    );
  }

  static String _escapeCsvValue(String value) {
    final escapedValue = value.replaceAll('"', '""');
    return '"$escapedValue"';
  }

  static List<String> _decodeCsvLabels(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return <String>[];
    }

    if (trimmedValue.startsWith("[") && trimmedValue.endsWith("]")) {
      return List<String>.from(jsonDecode(trimmedValue));
    }

    return trimmedValue
        .split("|")
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  static List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final character = content[i];
      final nextCharacter = i + 1 < content.length ? content[i + 1] : null;

      if (character == '"') {
        if (insideQuotes && nextCharacter == '"') {
          cell.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
        continue;
      }

      if (character == "," && !insideQuotes) {
        row.add(cell.toString());
        cell.clear();
        continue;
      }

      if ((character == "\n" || character == "\r") && !insideQuotes) {
        if (character == "\r" && nextCharacter == "\n") {
          i++;
        }
        row.add(cell.toString());
        cell.clear();
        if (row.any((value) => value.isNotEmpty)) {
          rows.add(List<String>.from(row));
        }
        row.clear();
        continue;
      }

      cell.write(character);
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      if (row.any((value) => value.isNotEmpty)) {
        rows.add(List<String>.from(row));
      }
    }

    return rows;
  }

  static List<Expense> _decodeCsvExpenses(String csvContent) {
    final rows = _parseCsv(csvContent);
    if (rows.isEmpty || !_matchesExpenseKeys(rows.first)) {
      throw const FormatException(unsupportedFileMessage);
    }

    final expenses = <Expense>[];
    for (final row in rows.skip(1)) {
      if (row.length != expenseFileKeys.length) {
        throw const FormatException(unsupportedFileMessage);
      }

      final expenseMap = <String, dynamic>{};
      for (int index = 0; index < expenseFileKeys.length; index++) {
        expenseMap[expenseFileKeys[index]] = row[index];
      }

      final labelValue = expenseMap["label"]?.toString() ?? "";
      expenseMap["label"] = _decodeCsvLabels(labelValue);
      expenseMap["isDebit"] =
          (expenseMap["isDebit"]?.toString().toLowerCase() == "true");
      expenseMap["isSMS"] =
          (expenseMap["isSMS"]?.toString().toLowerCase() == "true");
      _validateExpenseMap(expenseMap, requireExactKeys: true);
      expenses.add(Expense.fromJson(expenseMap));
    }

    return expenses;
  }

  static void sortExpensesByDate(List<Expense> items) {
    items.sort((a, b) {
      final dateA = DateTime.parse(a.date!);
      final dateB = DateTime.parse(b.date!);
      return dateB.compareTo(dateA);
    });
  }

  static Future<List<Expense>> _readJsonExpenses(String filePath) async {
    final content = _stripUtf8Bom(await File(filePath).readAsString());

    try {
      return _decodeExpenseList(jsonDecode(content));
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw const FormatException(unsupportedFileMessage);
    }
  }

  static Future<List<Expense>> _readPbkeExpenses(String filePath) async {
    final pbkeData = await PbkeFile.readPbkeFile(filePath);
    if (pbkeData == null) {
      throw const FormatException(unsupportedFileMessage);
    }
    SmsApi.lastDate = pbkeData.lastDate;
    return _decodePbkeExpenses(pbkeData.data);
  }

  static Future<List<Expense>> _readCsvExpenses(String filePath) async {
    final content = await File(filePath).readAsString();
    return _decodeCsvExpenses(content);
  }

  static String expenseIdentity(Expense expense) {
    if ((expense.id ?? "").isNotEmpty) {
      return "id:${expense.id}";
    }
    return [
      expense.name ?? "",
      expense.date ?? "",
      expense.amount ?? "",
      expense.isDebit?.toString() ?? "",
      expense.isSMS.toString(),
    ].join("|");
  }

  static String buildStorageJson([List<Expense>? items]) {
    return jsonEncode({
      "expenses": Expense.listToJson(items ?? expenses),
      "smsEnabled": smsExpensesEnabled,
    });
  }

  static Future<void> persistCurrentExpenses({DateTime? date}) async {
    sortExpensesByDate(expenses);
    json = buildStorageJson();
    await saveExpenses(json, date ?? SmsApi.lastDate);
  }

  static Future<void> setSmsExpensesEnabled(bool enabled) async {
    smsExpensesEnabled = enabled;
    if (!enabled) {
      expenses = expenses.where((expense) => !expense.isSMS).toList();
    }
    sortExpensesByDate(expenses);
    await persistCurrentExpenses();
  }

  static String exportJsonList() {
    return jsonEncode(Expense.listToJson(expenses));
  }

  static String exportCsv() {
    final lines = <String>[expenseFileKeys.join(",")];
    for (final expense in expenses) {
      final expenseJson = expense.toJson();
      final row = expenseFileKeys
          .map((key) {
            final value = expenseJson[key];
            if (key == "label") {
              final labels = List<String>.from(value ?? <String>[]);
              return _escapeCsvValue(labels.join("|"));
            }
            return _escapeCsvValue(value?.toString() ?? "");
          })
          .join(",");
      lines.add(row);
    }
    return lines.join("\n");
  }

  static String exportPrivateMonthlyCsv(DateTime month) {
    final monthExpenses =
        expenses.where((expense) {
          if (expense.date == null) {
            return false;
          }
          final expenseDate = DateTime.parse(expense.date!);
          return expenseDate.year == month.year &&
              expenseDate.month == month.month;
        }).toList();

    sortExpensesByDate(monthExpenses);

    final lines = <String>[privateExpenseFileKeys.join(",")];
    for (final expense in monthExpenses) {
      final row = <String>[
        _escapeCsvValue(expense.name ?? ""),
        _escapeCsvValue((expense.label ?? <String>[]).join("|")),
        _escapeCsvValue(expense.date ?? ""),
        _escapeCsvValue(expense.amount ?? ""),
      ].join(",");
      lines.add(row);
    }
    return lines.join("\n");
  }

  static Future<File> exportPrivateMonthlyCsvFile(DateTime month) async {
    final exportDir = await _getExportDirectory();
    final fileName =
        "private_${month.year}_${month.month.toString().padLeft(2, '0')}.csv";
    final exportFile = File("${exportDir.path}/$fileName");
    final content = exportPrivateMonthlyCsv(month);
    return exportFile.writeAsString(content);
  }

  static Future<File> exportExpensesFile(String format) async {
    if (format != "json" && format != "pbke" && format != "csv") {
      throw const FormatException(unsupportedFileTypeMessage);
    }

    sortExpensesByDate(expenses);
    await persistCurrentExpenses();

    final tempDir = await _getExportDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportFile = File('${tempDir.path}/expenses_$timestamp.$format');

    if (format == "pbke") {
      final sourcePath = expFile?.path ?? filepath;
      if (sourcePath.isEmpty || !File(sourcePath).existsSync()) {
        throw const FormatException(unsupportedFileMessage);
      }
      return File(sourcePath).copy(exportFile.path);
    }

    final content = format == "json" ? exportJsonList() : exportCsv();
    return exportFile.writeAsString(content);
  }

  static Future<List<Expense>> importExpensesFromFile(String filePath) async {
    validateImportFileType(filePath);

    final extension = getFileExtension(filePath);
    final importedExpenses =
        extension == "json"
            ? await _readJsonExpenses(filePath)
            : extension == "csv"
            ? await _readCsvExpenses(filePath)
            : await _readPbkeExpenses(filePath);

    final existingIds = expenses.map(expenseIdentity).toSet();
    for (final importedExpense in importedExpenses) {
      final identity = expenseIdentity(importedExpense);
      if (existingIds.add(identity)) {
        expenses.add(importedExpense);
      }
    }
    await persistCurrentExpenses();
    return expenses;
  }

  static Future<String> loadExpenses() async {
    try {
      Directory path = await _getStorageDirectory();
      final file = await File(
        '${path.path}/fins.pbke',
      ).create(recursive: true); // Create if not found
      filepath = file.path;
      expFile = file;
      final pbkeData = await PbkeFile.readPbkeFile(file.path);
      if (pbkeData != null) {
        SmsApi.lastDate = pbkeData.lastDate;
        debugPrint("decrypted ${pbkeData.data}");
        smsExpensesEnabled = pbkeData.data["smsEnabled"] ?? false;
        json = jsonEncode(pbkeData.data);
      }

      expenses = Expense.listFromRawJson(json);
      sortExpensesByDate(expenses);
      debugPrint("json load $json");
      return json;
    } catch (e) {
      debugPrint("Error loading expenses: $e");
    }
    return json;
  }

  static Future<void> saveExpenses(String newJson, DateTime? date) async {
    try {
      if (saveExpensesHook != null) {
        await saveExpensesHook!(newJson, date);
        return;
      }

      Directory path = await _getStorageDirectory();
      debugPrint(path.path);
      var file = await PbkeFile.writePbkeFile(
        '${path.path}/fins.pbke',
        newJson,
        date,
        fileVersion: version,
      );
      filepath = file.path;
      expFile = File('${path.path}/fins.pbke');

      debugPrint("write file \n\n\n\n");
    } catch (e) {
      debugPrint("Error saving expenses: $e");
    }
  }
}
