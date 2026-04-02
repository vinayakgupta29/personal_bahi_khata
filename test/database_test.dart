import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_platform_interface/src/method_channel_path_provider.dart';
import 'package:personal_bahi_khata/data/database.dart';
import 'package:personal_bahi_khata/data/expenses.dart';
import 'package:personal_bahi_khata/data/pbke_file.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MethodChannelPathProvider pathProvider;
  String? lastSavedJson;
  DateTime? lastSavedDate;

  Expense buildExpense({
    required String id,
    required String date,
    String amount = '10.0',
    bool isDebit = true,
    bool isSMS = false,
    List<String> label = const ['Food'],
  }) {
    return Expense(
      name: 'Expense $id',
      id: id,
      date: date,
      amount: amount,
      isDebit: isDebit,
      isSMS: isSMS,
      label: label,
    );
  }

  Future<File> createImportFile(String name, String content) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  setUpAll(() {
    pathProvider = MethodChannelPathProvider();
    pathProvider.setMockPathProviderPlatform(
      FakePlatform(operatingSystem: 'android'),
    );
    PathProviderPlatform.instance = pathProvider;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pbk_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider.methodChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getTemporaryDirectory':
              return tempDir.path;
            case 'getStorageDirectory':
              return tempDir.path;
            default:
              return null;
          }
        });

    DataBase.expenses = [];
    DataBase.uniqueTags = {};
    DataBase.selectedTags = [];
    DataBase.selectedDate = null;
    DataBase.uniqueyears = {};
    DataBase.filepath = '';
    DataBase.expFile = null;
    DataBase.json = """{"expenses":[]}""";
    DataBase.smsExpensesEnabled = false;
    DataBase.saveExpensesHook = (newJson, date) async {
      lastSavedJson = newJson;
      lastSavedDate = date;
    };
    lastSavedJson = null;
    lastSavedDate = null;
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider.methodChannel, null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    DataBase.saveExpensesHook = null;
  });

  test('validateFileHeader accepts matching signatures', () {
    final validHeader = <int>[
      ...utf8.encode(DataBase.signature),
      ...utf8.encode(DataBase.version),
      0,
      0,
      0,
      0,
      0,
      0,
    ];

    expect(() => PbkeFile.validateFileHeader(validHeader), returnsNormally);
  });

  test('validateFileHeader rejects a non-matching signature', () {
    final invalidSignatureHeader = <int>[
      ...utf8.encode('%WRNG%'),
      ...utf8.encode(DataBase.version),
      0,
      0,
      0,
      0,
      0,
      0,
    ];
    expect(
      () => PbkeFile.validateFileHeader(invalidSignatureHeader),
      throwsFormatException,
    );
  });

  test('buildFileHeader writes the latest pbke version header', () {
    final bytes = PbkeFile.buildFileHeader(null);
    final versionStart = PbkeFile.signature.length;
    final versionEnd = versionStart + PbkeFile.version.length;
    final storedVersion = utf8.decode(bytes.sublist(versionStart, versionEnd));

    expect(storedVersion, PbkeFile.version);
  });

  test('readFileVersion falls back to previous version when header has no version', () {
    final legacyHeader = <int>[
      ...utf8.encode(PbkeFile.signature),
      0,
      0,
      0,
      0,
      ...List<int>.filled(13, 0),
    ];

    expect(PbkeFile.readFileVersion(legacyHeader), '');
  });

  test('json import merges into current db and keeps descending date order', () async {
    DataBase.expenses = [
      buildExpense(id: 'base', date: '2024-01-01T00:00:00.000'),
    ];

    final file = await createImportFile(
      'import.json',
      jsonEncode([
        buildExpense(id: 'newer', date: '2025-03-01T00:00:00.000').toJson(),
        buildExpense(id: 'middle', date: '2024-06-01T00:00:00.000').toJson(),
      ]),
    );

    final imported = await DataBase.importExpensesFromFile(file.path);

    expect(imported.map((expense) => expense.id), ['newer', 'middle', 'base']);
  });

  test('json import rejects data that is not a valid expense type', () async {
    final file = await createImportFile(
      'invalid.json',
      jsonEncode([
        {
          'name': 'Broken',
          'label': ['Food'],
          'id': 'bad',
          'date': '2025-01-01T00:00:00.000',
          'amount': '10',
          'isDebit': 'true',
          'isSMS': false,
        },
      ]),
    );

    expect(
      () => DataBase.importExpensesFromFile(file.path),
      throwsFormatException,
    );
  });

  test('csv import accepts expense columns and parses labels', () async {
    final file = await createImportFile(
      'import.csv',
      [
        DataBase.expenseFileKeys.join(','),
        '"Lunch","Food|Office","csv1","2025-02-01T00:00:00.000","150.0","true","false"',
      ].join('\n'),
    );

    final imported = await DataBase.importExpensesFromFile(file.path);

    expect(imported, hasLength(1));
    expect(imported.first.label, ['Food', 'Office']);
    expect(imported.first.id, 'csv1');
  });

  test('csv import rejects invalid headers or types', () async {
    final file = await createImportFile(
      'invalid.csv',
      [
        'name,label,id,date,amount,isDebit',
        '"Lunch","Food","csv1","invalid-date","150.0","true"',
      ].join('\n'),
    );

    expect(
      () => DataBase.importExpensesFromFile(file.path),
      throwsFormatException,
    );
  });

  test('pbke import validates the file version before merging', () async {
    final fileBytes = <int>[
      ...utf8.encode(DataBase.signature),
      ...utf8.encode('00.99'),
      0,
      0,
      0,
      0,
      0,
      0,
      ...List<int>.filled(PbkeFile.footerLengthForMode(PbkeFormatMode.legacy) + 4, 1),
    ];
    final tamperedFile = File('${tempDir.path}/invalid.pbke');
    await tamperedFile.writeAsBytes(fileBytes);

    expect(
      () => DataBase.importExpensesFromFile(tamperedFile.path),
      throwsFormatException,
    );
  });

  test('disabling sms removes sms expenses from the stored db', () async {
    DataBase.expenses = [
      buildExpense(id: 'sms', date: '2025-01-02T00:00:00.000', isSMS: true),
      buildExpense(id: 'manual', date: '2025-01-01T00:00:00.000'),
    ];
    DataBase.smsExpensesEnabled = true;

    await DataBase.setSmsExpensesEnabled(false);

    expect(DataBase.smsExpensesEnabled, isFalse);
    expect(DataBase.expenses.map((expense) => expense.id), ['manual']);
    expect(lastSavedJson, isNotNull);

    final decoded = jsonDecode(lastSavedJson!) as Map<String, dynamic>;
    expect(decoded['smsEnabled'], isFalse);
    expect((decoded['expenses'] as List).map((item) => item['id']), ['manual']);
  });
}
