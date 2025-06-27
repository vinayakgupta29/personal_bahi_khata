import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_bahi_khata/data/encryption.dart';
import 'package:personal_bahi_khata/data/sms_api.dart';
import 'package:zstandard/zstandard.dart';

// writeFile(Map<String, dynamic> data) async {
//   var dir = await getExternalStorageDirectory();

//   debugPrint(dir?.path);
//   await File('${dir?.path}/fin.bkx').create(recursive: true);

//   File('/storage/emulated/0/Files/fin.bkx').writeAsStringSync(jsonEncode(data));
// }
final Zstandard zstd = Zstandard();

/// Compress and encrypt a JSON string using Zstandard and AES-GCM encryption.
///
/// [jsonData] is the JSON string to be compressed and encrypted.
/// [key] is the encryption key.
///
/// Returns the encrypted data as a list of bytes.

Future<List<int>> compressAndEncryptJson(String jsonData, List<int> key) async {
  // Compress JSON data

  Uint8List? compressedData = await zstd.compress(utf8.encode(jsonData), 13);

  debugPrint("key ${key.length}");
  // // Encrypt compressed data
  // final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
  // final iv = encrypt.IV.fromLength(16);
  // final encryptedData = encrypter.encryptBytes(compressedData, iv: iv);

  // // Return base64 encoded encrypted data and IV
  // return "${base64.encode(encryptedData.bytes)}|${iv.base64}"
  //     .replaceAll('"', "");
  var encryptedData = await EncryptionAES.encryptAESGCM(
    List<int>.from(compressedData?.toList() ?? []),
    base64Encode(key),
  );
  return encryptedData;
}

// Function to decompress and decrypt JSON data
Future<Map<String, dynamic>> decryptAndDecompressJson(
  List<int> encryptedCompressedData,
  String key,
) async {
  // Extract IV and encrypted data
  debugPrint("key $key");
  // List<String> data = encryptedCompressedData.split("|");
  // String ivString = data[1];
  // SmsApi.lastDate =
  //     data[2] == "null" || data[2].isEmpty ? null : DateTime.parse(data[2]);
  // debugPrint("lastdate decompress ${data[2]}");
  // List<int> encryptedData = base64.decode(data[0]);

  // // Decrypt data
  // final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
  // final iv = encrypt.IV.fromBase64(ivString);
  // final decryptedData = encrypter.decryptBytes(
  //     encrypt.Encrypted(Uint8List.fromList(encryptedData)),
  //     iv: iv);

  var decryptedData = await EncryptionAES.decryptAESGCM(
    encryptedCompressedData,
    base64Encode(utf8.encode(key)),
  );

  // Decompress decrypted data
  Uint8List? decompressedData = await zstd.decompress(
    Uint8List.fromList(decryptedData),
  );

  // Convert decompressed data to string and parse as JSON
  String jsonString = utf8.decode(List.from(decompressedData ?? []));
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  debugPrint("json decry $jsonData");
  // Return JSON data
  return jsonData;
}

List<int> getUnixTime(DateTime? date) {
  // Get the current date as Unix time (seconds since epoch)
  if (date != null) {
    var unixTime =
        DateTime.parse(date.toIso8601String()).millisecondsSinceEpoch ~/ 1000;
    return [
      (unixTime >> 24) & 0xFF,
      (unixTime >> 16) & 0xFF,
      (unixTime >> 8) & 0xFF,
      unixTime & 0xFF,
    ];
  } else {
    return [0, 0, 0, 0];
  }
}

DateTime getDateTimeFromUnixTime(List<int> dateAsBytes) {
  int unixTimeStartIndex = 7; // String length (7 bytes)
  List<int> unixTimeBytes = dateAsBytes.sublist(
    unixTimeStartIndex,
    unixTimeStartIndex + 4,
  );

  int unixTime =
      unixTimeBytes[0] << 24 |
      unixTimeBytes[1] << 16 |
      unixTimeBytes[2] << 8 |
      unixTimeBytes[3];
  return DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
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
  static String SIGNATURE = "%PBKE%";

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
      final file = await File(
        '${path?.path}/fins.pbke',
      ).create(recursive: true); // Create if not found
      filepath = file.path;
      expFile = file;
      final contents = file.readAsBytesSync();
      debugPrint("contents $contents");
      // Decrypt and decompress JSON
      if (contents.isNotEmpty) {
        int headerSize = utf8.encode(SIGNATURE).length + 4 + 13;
        List<int> metadata = contents.sublist(0, headerSize - 1);
        SmsApi.lastDate = getDateTimeFromUnixTime(metadata);
        List<int> data = contents.sublist(
          headerSize,
          contents.length - EncryptionAES.KEY_LENGTH,
        );

        var decryptedDecompressedJson = await decryptAndDecompressJson(
          data,
          EncryptionAES.KEY,
        );
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
      List<int> encryptedCompressedString = await compressAndEncryptJson(
        newJson,
        utf8.encode(EncryptionAES.KEY),
      );
      List<int> fileContent = [
        ...utf8.encode(SIGNATURE),
        ...getUnixTime(date),
        ...List.generate(13, (e) => 0),
        ...encryptedCompressedString,
      ];
      debugPrint("enc $encryptedCompressedString");
      var file = await File(
        '${path?.path}/fins.pbke',
      ).writeAsBytes(fileContent);
      filepath = file.path;
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
  String currency;

  Expense({
    this.name,
    this.label,
    this.id,
    this.date,
    this.amount,
    this.isDebit = true,
    this.currency = "INR",
  });

  factory Expense.fromRawJson(String str) => Expense.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    name: json["name"],
    label:
        json["label"] == null
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
    List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(
      list.map((item) => item.toJson()),
    );
    return jsonList;
  }

  String getMonthYear() {
    // Convert ISO date to DateTime and then format it as "MMMM yyyy"
    DateTime dateTime = DateTime.parse(date!);
    return DateFormat.yMMMM().format(dateTime);
  }
}
