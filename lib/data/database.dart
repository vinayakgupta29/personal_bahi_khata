import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

// writeFile(Map<String, dynamic> data) async {
//   var dir = await getExternalStorageDirectory();

//   debugPrint(dir?.path);
//   await File('${dir?.path}/fin.bkx').create(recursive: true);

//   File('/storage/emulated/0/Files/fin.bkx').writeAsStringSync(jsonEncode(data));
// }

Map<String, dynamic> compressAndEncryptJson(String jsonData, String key) {
  // Compress JSON data
  List<int> compressedData = GZipCodec().encode(utf8.encode(jsonData));

  debugPrint("key $key");
  // Encrypt compressed data
  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
  final iv = encrypt.IV.fromLength(16);
  final encryptedData = encrypter.encryptBytes(compressedData, iv: iv);

  // Return base64 encoded encrypted data and IV
  return {"data": base64.encode(encryptedData.bytes), "iv": iv.base64};
}

// Function to decompress and decrypt JSON data
Map<String, dynamic> decryptAndDecompressJson(
    Map<String, dynamic> encryptedCompressedData, String key) {
  // Extract IV and encrypted data
  debugPrint("key $key");
  String ivString = encryptedCompressedData['iv'];
  List<int> encryptedData = base64.decode(encryptedCompressedData['data']);

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
  var jsonData = jsonDecode(jsonString);
  debugPrint("json decry $jsonData");
  // Return JSON data
  return jsonData;
}

class DataBase {
  static List<Expense> expenses = [];
  static Set<String> uniqueTags = {};
  static List<String> selectedTags = [];
  static DateTime? selectedDate;
  static List<int> uniqueyears = [];
  static String filepath = '';

  static String libDir = '';

  static String? downDir;
  static String key = 'viksviksviksviks';

  static List<Directory>? dirs;
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

  void updateDatabase() {
    //_myBox.put("expenses", Expense.listToJson(expenses));
    Map<String, dynamic> newJson = {"expenses": DataBase.expenses};
    saveExpenses(jsonEncode(newJson));
  }

  static String json = """{"expenses":[]}""";
  static File? expFile;

  static Future<String> loadExpenses() async {
    try {
      Directory? path = await getApplicationDocumentsDirectory();

      final file = await File('${path.path}/fins.bkx')
          .create(recursive: true); // Create if not found
      expFile = file;
      final contents = await file.readAsString();
      debugPrint("contents $contents");
      // Decrypt and decompress JSON
      if (contents.isNotEmpty) {
        var decryptedDecompressedJson =
            decryptAndDecompressJson(jsonDecode(contents), key);
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

  static Future<void> saveExpenses(String newJson) async {
    try {
      Directory path = await getApplicationDocumentsDirectory();
      debugPrint(path.path);
      // Encrypt and compress JSON
      var encryptedCompressedJson = compressAndEncryptJson(newJson, key);
      debugPrint("enc $encryptedCompressedJson");
      await File('${path.path}/fins.bkx')
          .writeAsString(jsonEncode(encryptedCompressedJson));
      expFile = File('${path.path}/fins.bkx');
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
