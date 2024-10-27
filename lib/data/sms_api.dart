import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/main.dart';

class SmsApi {
  static SmsQuery query = SmsQuery();
  static List<SmsMessage> messages0 = [];
  static List<Expense> exp0 = [];
  static DateTime? lastDate;
  static Future<List<SmsMessage>> getSms() async {
    PermissionStatus permissionStatus = await Permission.sms.status;
    if (PermissionStatus.granted != permissionStatus) {
      PermissionStatus permissionStatus = await Permission.sms.request();
      if (permissionStatus.isDenied) {
        return [];
      }
    }
    var messagees = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );
    messagees =
        messagees.where((e) => isTransactionMessage(e.body ?? "")).toList();
    for (var e in messagees) {
      print(e.body);
      DataBase.expenses.add(
        Expense(
          name: "From SMS ${e.address}",
          label: ["SMS"],
          amount: getAmount(e.body?.replaceAll(",", "") ?? "").toString(),
          date: e.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
          isDebit: e.body?.contains("debited") ?? false,
        ),
      );
      if (DataBase.uniqueyears.contains(e.date?.year) && e.date != null) {
        DataBase.uniqueyears.add(e.date?.year ?? 0);
      }

      // db.updateDatabase();
      DataBase.uniqueTags.add("SMS");
      expenseNotifier.update(DataBase.expenses);
    }
    var newList = Expense.listToJson(DataBase.expenses);
    var newJson = jsonEncode({
      "expenses": newList,
      "lastDate": lastDate?.toIso8601String(),
    });

    DataBase.saveExpenses(newJson, lastDate);
    print("messgers${messagees.length}");
    return messagees;
  }

  static filterSms() {
    getSms().then((value) {
      messages0 = value.toList()
        ..sort((a, b) {
          if (a.date == null && b.date == null) {
            return 0; // Both are null, consider equal
          } else if (a.date == null) {
            return 1; // Nulls go last
          } else if (b.date == null) {
            return -1; // Nulls go last
          } else {
            return b.date!.compareTo(a.date!); // Sort by date
          }
        });

      lastDate = messages0.first.date;
      debugPrint("messages ${messages0.length}");
    });
  }

  static bool isTransactionMessage(String message) {
    // Define keywords to look for
    final List<String> positiveKeywords = [
      'credited',
      'debited',
      'transfer',
      'withdrawal',
      'deposit'
    ];
    final List<String> negativeKeywords = [
      'refund',
      'return',
      "recharge",
      "congratulations",
      "customers"
    ];

    // Check for positive keywords
    bool hasPositiveKeywords = positiveKeywords
        .any((keyword) => message.toLowerCase().contains(keyword));

    // Check for negative keywords
    bool hasNegativeKeywords = negativeKeywords
        .any((keyword) => message.toLowerCase().contains(keyword));

    // Only include messages that have positive keywords and do not have negative keywords
    return hasPositiveKeywords && !hasNegativeKeywords;
  }

  static double getAmount(String message) {
    // Regular expression to find decimal numbers with one or two digits of precision
    RegExp regExp = RegExp(r'(\d+\.\d{1,2})');

    // Search for matches
    Match? match = regExp.firstMatch(message);

    if (match != null) {
      // Extract the matched string
      String decimalString = match.group(0)!;

      // Parse it as a double
      return double.parse(decimalString);
    }
    return 0.0;
  }

  static get messages => messages0;
}
