import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_bahi_khata/data/database.dart';
import 'package:personal_bahi_khata/util/constants.dart';
import 'package:share_plus/share_plus.dart';

class PrivateFeatureTile extends StatelessWidget {
  const PrivateFeatureTile({super.key});

  static bool isPrime(int value) {
    if (value < 2) {
      return false;
    }
    for (int i = 2; i * i <= value; i++) {
      if (value % i == 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showMessageDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: bgcolor,
            title: Text(title, style: const TextStyle(color: textcolor)),
            content: Text(message, style: const TextStyle(color: textcolor)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<bool> _unlockPrivateExport(BuildContext context) async {
    final controller = TextEditingController();
    final enteredPassword = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: bgcolor,
            title: const Text(
              "Private Export",
              style: TextStyle(color: textcolor),
            ),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: textcolor),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter password",
                hintStyle: TextStyle(color: hintcol),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text);
                },
                child: const Text("Unlock"),
              ),
            ],
          ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return isPrime(int.tryParse(enteredPassword?.trim() ?? "") ?? 0);
  }

  Future<DateTime?> _pickMonth(BuildContext context) async {
    final availableYears = DataBase.uniqueyears.toList()..sort();
    if (availableYears.isEmpty) {
      availableYears.add(DateTime.now().year);
    }
    int selectedMonth = DateTime.now().month;
    int selectedYear = availableYears.last;

    return showDialog<DateTime>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  backgroundColor: bgcolor,
                  title: const Text(
                    "Select Month",
                    style: TextStyle(color: textcolor),
                  ),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        elevation: 16,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(height: 2, color: Colors.indigo),
                        dropdownColor: bgcolor,
                        menuMaxHeight: 300,
                        onChanged: (int? value) {
                          setDialogState(() {
                            selectedMonth = value ?? 1;
                          });
                        },
                        items: const [
                          DropdownMenuItem<int>(value: 1, child: Text("January")),
                          DropdownMenuItem<int>(value: 2, child: Text("February")),
                          DropdownMenuItem<int>(value: 3, child: Text("March")),
                          DropdownMenuItem<int>(value: 4, child: Text("April")),
                          DropdownMenuItem<int>(value: 5, child: Text("May")),
                          DropdownMenuItem<int>(value: 6, child: Text("June")),
                          DropdownMenuItem<int>(value: 7, child: Text("July")),
                          DropdownMenuItem<int>(value: 8, child: Text("August")),
                          DropdownMenuItem<int>(value: 9, child: Text("September")),
                          DropdownMenuItem<int>(value: 10, child: Text("October")),
                          DropdownMenuItem<int>(value: 11, child: Text("November")),
                          DropdownMenuItem<int>(value: 12, child: Text("December")),
                        ],
                      ),
                      DropdownButton<int>(
                        value: selectedYear,
                        elevation: 16,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(height: 2, color: Colors.indigo),
                        dropdownColor: bgcolor,
                        menuMaxHeight: 300,
                        items:
                            availableYears
                                .map(
                                  (year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (int? value) {
                          setDialogState(() {
                            selectedYear = value ?? selectedYear;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.of(
                            dialogContext,
                          ).pop(DateTime(selectedYear, selectedMonth)),
                      child: const Text("Export"),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _handlePrivateExport(BuildContext context) async {
    final isUnlocked = await _unlockPrivateExport(context);
    if (!isUnlocked) {
      await _showMessageDialog(context, "Private Export", "Incorrect password");
      return;
    }

    final month = await _pickMonth(context);
    if (month == null) {
      return;
    }

    try {
      final exportedFile = await DataBase.exportPrivateMonthlyCsvFile(month);
      final monthLabel = DateFormat("MMMM yyyy").format(month);

      if (Platform.isLinux) {
        await _showMessageDialog(
          context,
          "Private Export",
          "$monthLabel exported to ${exportedFile.path}",
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exportedFile.path, mimeType: "text/csv")],
        ),
      );
    } catch (e) {
      final message =
          e is FormatException ? e.message : DataBase.unsupportedFileMessage;
      await _showMessageDialog(context, "Private Export", "$message");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outline, color: Colors.white),
      title: const Text("Private Export", style: TextStyle(color: textcolor)),
      subtitle: const Text(
        "Locked monthly CSV export",
        style: TextStyle(color: hintcol),
      ),
      onTap: () async {
        final navigator = Navigator.of(context);
        navigator.pop();
        await Future<void>.delayed(Duration.zero);
        await _handlePrivateExport(navigator.context);
      },
    );
  }
}
