import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Expense {
  String? name;
  List<String>? label;
  String? id;
  String? date;
  String? amount;
  bool? isDebit;
  bool isSMS;
  String currency;

  Expense({
    this.name,
    this.label,
    this.id,
    this.date,
    this.amount,
    this.isDebit = true,
    this.isSMS = false,
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
    isSMS: json["isSMS"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "label": label,
    "id": id,
    "date": date,
    "amount": amount,
    "isDebit": isDebit,
    "isSMS": isSMS,
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
