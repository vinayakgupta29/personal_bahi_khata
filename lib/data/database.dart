import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:personal_finance_tracker/data/sms_api.dart';

// writeFile(Map<String, dynamic> data) async {
//   var dir = await getExternalStorageDirectory();

//   debugPrint(dir?.path);
//   await File('${dir?.path}/fin.bkx').create(recursive: true);

//   File('/storage/emulated/0/Files/fin.bkx').writeAsStringSync(jsonEncode(data));
// }

String compressAndEncryptJson(String jsonData, String key) {
  // Compress JSON data
  List<int> compressedData = GZipCodec().encode(utf8.encode(jsonData));

  debugPrint("key $key");
  // Encrypt compressed data
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
  final iv = encrypt.IV.fromLength(16);
  final encryptedData = encrypter.encryptBytes(compressedData, iv: iv);

  // Return base64 encoded encrypted data and IV
  return "${base64.encode(encryptedData.bytes)}|${iv.base64}"
      .replaceAll('"', "");
}

// Function to decompress and decrypt JSON data
Map<String, dynamic> decryptAndDecompressJson(
    String encryptedCompressedData, String key) {
  // Extract IV and encrypted data
  debugPrint("key $key");
  List<String> data = encryptedCompressedData.split("|");
  String ivString = data[1];
  SmsApi.lastDate =
      data[2] == "null" || data[2].isEmpty ? null : DateTime.parse(data[2]);
  debugPrint("lastdate decompress ${data[2]}");
  List<int> encryptedData = base64.decode(data[0]);

  // Decrypt data
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
  final iv = encrypt.IV.fromBase64(ivString);
  final decryptedData = encrypter.decryptBytes(
      encrypt.Encrypted(Uint8List.fromList(encryptedData)),
      iv: iv);

  // Decompress decrypted data
  List<int> decompressedData = GZipCodec().decode(decryptedData);

  // Convert decompressed data to string and parse as JSON
  String jsonString = utf8.decode(decompressedData);
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  debugPrint("json decry $jsonData");
  // Return JSON data
  return jsonData;
}

class DataBase {
  static List<Expense> expenses = [];
  static Set<String> uniqueTags = {};
  static List<String> selectedTags = [];
  static DateTime? selectedDate;
  static Set<int> uniqueyears = {};
  static String filepath = '';

  static String libDir = '';

  static String? downDir;
  static String key = 'viksviksviksviks';

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
    //_myBox.put("expenses", Expense.listToJson(expenses));
    Map<String, dynamic> newJson = {"expenses": DataBase.expenses};
    saveExpenses(jsonEncode(newJson), lastDate);
  }

  static String json = """{"expenses":[]}""";
  static File? expFile;

  static Future<String> loadExpenses() async {
    try {
      Directory? path = await getExternalStorageDirectory();

      final file = await File('${path?.path}/fins.pbke')
          .create(recursive: true); // Create if not found
      expFile = file;
      final contents = file.readAsBytesSync();
      debugPrint("contents $contents");
      // Decrypt and decompress JSON
      if (contents.isNotEmpty) {
        var decryptedDecompressedJson =
            decryptAndDecompressJson(String.fromCharCodes(contents), key);
        debugPrint("decrypted $decryptedDecompressedJson");
        json = jsonEncode(decryptedDecompressedJson);
      }

      expenses = Expense.listFromRawJson(json);
      debugPrint("json load $json");
      return json;
    } catch (e) {
      debugPrint("Error loading expenses: $e");
    }
    return json;
  }

  static Future<void> saveExpenses(String newJson, DateTime? date) async {
    try {
      Directory? path = await getExternalStorageDirectory();
      debugPrint(path?.path);
      // Encrypt and compress JSON
      String encryptedCompressedString = compressAndEncryptJson(newJson, key);
      String fileContent =
          "${encryptedCompressedString.replaceAll('"', "")}|${date?.toIso8601String() ?? ""}";
      debugPrint("enc $encryptedCompressedString");
      await File('${path?.path}/fins.pbke').writeAsBytes(fileContent.codeUnits);
      expFile = File('${path?.path}/fins.pbke');
      debugPrint("write file \n\n\n\n");
    } catch (e) {
      debugPrint("Error saving expenses: $e");
    }
  }
}

class Expense {
  String? name;
  List<String>? label;
  String? id;
  String? date;
  String? amount;
  bool? isDebit;

  Expense({
    this.name,
    this.label,
    this.id,
    this.date,
    this.amount,
    this.isDebit = true,
  });

  factory Expense.fromRawJson(String str) => Expense.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        name: json["name"],
        label: json["label"] == null
            ? []
            : List<String>.from(json["label"]!.map((x) => x)),
        id: json["id"],
        date: json["date"],
        amount: json["amount"],
        isDebit: json["isDebit"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "label": label,
        "id": id,
        "date": date,
        "amount": amount,
        "isDebit": isDebit,
      };

  static List<Expense> listFromRawJson(String str) {
    Map<String, dynamic> jsonRes = json.decode(str);
    debugPrint(jsonRes.toString());
    List list = jsonRes['expenses'];
    return List<Expense>.from(list.map((item) => Expense.fromJson(item)));
  }

  static List<Map<String, dynamic>> listToJson(List<Expense> list) {
    List<Map<String, dynamic>> jsonList =
        List<Map<String, dynamic>>.from(list.map((item) => item.toJson()));
    return jsonList;
  }

  String getMonthYear() {
    // Convert ISO date to DateTime and then format it as "MMMM yyyy"
    DateTime dateTime = DateTime.parse(date!);
    return DateFormat.yMMMM().format(dateTime);
  }
}
