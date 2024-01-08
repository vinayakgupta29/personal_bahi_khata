import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DataBase {
  static List<Expense> expenses = [];
  final _myBox = Hive.box("financeBox");

  static void createInitialData() {
    expenses = [];
  }

  void delete() {
    _myBox.delete("expenses");
  }

  static void loadData() {
    debugPrint("json $json");

    loadExpenses().then((value) {
      expenses = Expense.listFromRawJson(json);
    });
  }

  void updateDatabase() {
    _myBox.put("expenses", Expense.listToRawJson(expenses));
  }

  static String json = "[]"; // Initialize as empty string
  static File? expFile;

  static Future<String> loadExpenses() async {
    try {
      Directory path = await getApplicationDocumentsDirectory();
      final file = await File('${path.path}/fins.txt')
          .create(recursive: true); // Create if not found
      expFile = file;
      final contents = await file.readAsString();
      debugPrint("contents $contents");
      json = contents.isEmpty ? "[]" : contents; // Handle empty file
      expenses = Expense.listFromRawJson(json);
      debugPrint("json load $json");
      return contents.isEmpty ? "[]" : contents;
    } catch (e) {
      print("Error loading expenses: $e");
      json = "[]"; // Set to empty string on error
    }
    return "[]";
  }

  static Future<void> saveExpenses(String newJson) async {
    try {
      Directory path = await getApplicationDocumentsDirectory();
      print(path.path);
      await File('${path.path}/fins.txt').writeAsString(newJson);
      expFile = File('${path.path}/fins.txt');
      print("write file \n\n\n\n");
    } catch (e) {
      print("Error saving expenses: $e");
    }
  }
}

class Expense {
  String? name;
  String? label;
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
        label: json["label"],
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
    List<dynamic> list = json.decode(str);
    return List<Expense>.from(list.map((item) => Expense.fromJson(item)));
  }

  static String listToRawJson(List<Expense> list) {
    List<Map<String, dynamic>> jsonList =
        List<Map<String, dynamic>>.from(list.map((item) => item.toJson()));
    return json.encode(jsonList);
  }

  String getMonthYear() {
    // Convert ISO date to DateTime and then format it as "MMMM yyyy"
    DateTime dateTime = DateTime.parse(date!);
    return DateFormat.yMMMM().format(dateTime);
  }
}
