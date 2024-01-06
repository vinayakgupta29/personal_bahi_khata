import 'dart:convert';

import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

class DataBase {
  List<Expense> expenses = [];
  final _myBox = Hive.box("financeBox");

  void createInitialData() {
    expenses = [];
  }

  void delete() {
    _myBox.delete("expenses");
  }

  void loadData() {
    expenses = Expense.listFromRawJson(_myBox.get("expenses"));
  }

  void updateDatabase() {
    _myBox.put("expenses", Expense.listToRawJson(expenses));
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
