import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/presentation/searchpage.dart';
import 'package:personal_finance_tracker/util/constants.dart';

class OpenedFilePage extends StatefulWidget {
  final String filePath;
  const OpenedFilePage({super.key, required this.filePath});

  @override
  State<OpenedFilePage> createState() => _OpenedFilePageState();
}

class _OpenedFilePageState extends State<OpenedFilePage> {
  var file;

  @override
  void initState() {
    super.initState();
    file = readFile(widget.filePath);
  }

  bool dateFilter(Expense obj) {
    if (DataBase.selectedDate != null) {
      var selectedDate = DataBase.selectedDate;
      DateTime date = DateTime.parse(obj.date!);
      return (date.year == selectedDate?.year) &&
          (date.month == selectedDate?.month);
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> jsondata = jsonDecode(readFile(widget.filePath));
    debugPrint(" open ${jsondata.keys}");
    Map<String, dynamic> data =
        decryptAndDecompressJson(jsondata, "viksviksviksviks");
    debugPrint("data key ${data.keys}");
    var foundExpense = Expense.listFromRawJson(jsonEncode(data));
    foundExpense.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date!);
      DateTime dateB = DateTime.parse(b.date!);
      return dateB.compareTo(dateA);
    });
    var filterObjects = foundExpense.where((obj) {
      // Return true if all tags in the object's list are contained within DB.selectedTags
      return ((DataBase.selectedTags.isNotEmpty
              ? obj.label?.any((tag) => DataBase.selectedTags.contains(tag)) ??
                  true
              : true) &&
          (dateFilter(obj)));
    }).toList();
    debugPrint("selected ${DataBase.selectedTags} filter $filterObjects");
    // // Group objects by month and year
    Map<String, List<Expense>> groupedObjects = {};
    var allTags = [];
    for (Expense obj in filterObjects) {
      String monthYear = obj.getMonthYear();
      if (!groupedObjects.containsKey(monthYear)) {
        groupedObjects[monthYear] = [];
      }
      groupedObjects[monthYear]!.add(obj);
    }

    return Scaffold(
      backgroundColor: bgcolor,
      appBar: AppBar(
        title: const Text(
          "Expenses",
          style: TextStyle(
              color: textcolor, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        elevation: 10,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SearchPage(
                              onPopCallback: () {
                                setState(() {});
                              },
                              filePath: widget.filePath,
                            )));
              },
              icon: const Icon(
                Icons.search_outlined,
                color: Colors.white,
                size: 30,
              ))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: groupedObjects.length * 2, // *2 for dividers
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    // Divider
                    return Container(
                      height: 0.000005,
                    );
                  }

                  // Header or List Item
                  int headerIndex = index ~/ 2;
                  String monthYear = groupedObjects.keys.elementAt(headerIndex);
                  List<Expense> objects = groupedObjects[monthYear]!;

                  double sum = 0;
                  for (var obj in objects) {
                    obj.isDebit ?? true
                        ? sum -= (double.parse(obj.amount ?? "0") * 100)
                        : sum += (double.parse(obj.amount ?? "0") * 100);
                  }
                  sum /= 100;
                  return Container(
                    color: bgcolor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with month and year
                        SizedBox(
                          height: 50,
                          width: MediaQuery.of(context).size.width,
                          child: Card(
                            color: bgcolor,
                            elevation: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text(
                                    monthYear,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textcolor),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      sum.toString(),
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: sum >= 0
                                              ? Colors.green
                                              : Colors.red),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        // List of items for that month and year
                        for (Expense obj in objects)
                          Column(
                            children: [
                              ListTile(
                                key: Key(obj.id ?? ""),
                                tileColor: itemcolor,
                                title: Text(
                                  obj.name ?? "hi",
                                  style: const TextStyle(color: textcolor),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('E dd/MM/yyyy').format(
                                        DateTime.parse(obj.date!),
                                      ),
                                      style: const TextStyle(color: textcolor),
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: MediaQuery.of(context).size.width -
                                          100,
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: obj.label?.length ?? 0,
                                          itemBuilder: (context, ind) =>
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Chip(
                                                    labelStyle: const TextStyle(
                                                        fontSize: 12),
                                                    label: Text(
                                                        obj.label?[ind] ??
                                                            "hi")),
                                              )),
                                    )
                                  ],
                                ),
                                trailing: Text(
                                  (obj.isDebit ?? false ? "- " : "+ ") +
                                      (obj.amount ?? "N/A"),
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: (obj.isDebit ?? false)
                                          ? Colors.red
                                          : Colors.green),
                                ),
                              ),
                              const Divider(
                                color: hintcol,
                              )
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String readFile(String filepath) {
    return File(filepath).readAsStringSync();
  }
}
