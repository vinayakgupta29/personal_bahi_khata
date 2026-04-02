import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_bahi_khata/data/database.dart';
import 'package:personal_bahi_khata/data/expenses.dart';
import 'package:personal_bahi_khata/main.dart';

class SmsApi {
  static SmsQuery query = SmsQuery();
  static List<SmsMessage> messages0 = [];
  static List<Expense> exp0 = [];
  static DateTime? lastDate;

  static String _buildSmsExpenseId(SmsMessage message) {
    return "sms_${message.date?.millisecondsSinceEpoch ?? 0}_${message.address ?? "unknown"}";
  }

  static Future<bool> ensureSmsPermission() async {
    PermissionStatus permissionStatus = await Permission.sms.status;
    if (PermissionStatus.granted == permissionStatus) {
      return true;
    }

    permissionStatus = await Permission.sms.request();
    return permissionStatus.isGranted;
  }

  static Future<List<SmsMessage>> getSms() async {
    if (!DataBase.smsExpensesEnabled) {
      return [];
    }

    final hasPermission = await ensureSmsPermission();
    if (!hasPermission) {
      return [];
    }
    var messagees = await query.querySms(kinds: [SmsQueryKind.inbox]);
    messagees =
        messagees.where((e) => isTransactionMessage(e.body ?? "")).toList();
    for (var e in messagees) {
      final smsId = _buildSmsExpenseId(e);
      if (DataBase.expenses.any((expense) => expense.id == smsId)) {
        continue;
      }
      debugPrint(e.body);
      DataBase.expenses.add(
        Expense(
          name: "From SMS ${e.address}",
          label: ["SMS"],
          id: smsId,
          amount: getAmount(e.body?.replaceAll(",", "") ?? "").toString(),
          date: e.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
          isDebit: e.body?.contains("debited") ?? false,
          isSMS: true,
        ),
      );
      if (DataBase.uniqueyears.contains(e.date?.year) && e.date != null) {
        DataBase.uniqueyears.add(e.date?.year ?? 0);
      }

      // db.updateDatabase();
    }
    debugPrint("messgers${DataBase.expenses.length}");
    return messagees;
  }

  static Future<void> filterSms() async {
    if (!DataBase.smsExpensesEnabled) {
      return;
    }

    final value = await getSms();
    messages0 =
        value.toList()..sort((a, b) {
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

    DataBase.uniqueTags.add("SMS");
    DataBase.sortExpensesByDate(DataBase.expenses);
    expenseNotifier.update(DataBase.expenses);

    if (messages0.isNotEmpty) {
      lastDate = messages0.first.date;
      debugPrint("date ${lastDate?.toIso8601String()}");
    }
    await DataBase.persistCurrentExpenses(date: lastDate);

    debugPrint("messages ${messages0.length}");
  }

  static bool isTransactionMessage(String message) {
    // Define keywords to look for
    final List<String> positiveKeywords = [
      'credited',
      'debited',
      'transfer',
      'withdrawal',
      'deposit',
    ];
    final List<String> negativeKeywords = [
      'refund',
      'return',
      "recharge",
      "congratulations",
      "customers",
    ];

    // Check for positive keywords
    bool hasPositiveKeywords = positiveKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword),
    );

    // Check for negative keywords
    bool hasNegativeKeywords = negativeKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword),
    );

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

    final regex = RegExp(r'(?:Rs\.?\s*)([0-9]+(?:\.[0-9]+)?)');
    Match? mtch2 = regex.firstMatch(message);
    if (mtch2 != null) {
      debugPrint("${(mtch2.groupCount)}");
      // Extract the matched string
      String decimalString = mtch2.group(1)!;

      // Parse it as a double
      return double.parse(decimalString);
    }

    return 0.0;
  }

  static get messages => messages0;
}
