import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/presentation/bottomsheet.dart';
import 'package:personal_finance_tracker/util/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  await Hive.initFlutter();

  //open the box
  await Hive.openBox("financeBox");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _myBox = Hive.box("financeBox");
  DataBase db = DataBase();
  var tags = ["Mandir", "Food", "Fast Food", "Donation", "Travel", "Other"];
  var selectedTags = [];
  List<Expense> _foundExpense = [];
  List<Widget> widgets = [];

  File? file;
  // text controller
  String json = """[
    
  {
    "name": "Expense1",
    "label": null,
    "id": "1641345460000",
    "date": "2023-01-01T00:00:00.000Z",
    "amount": "100",
    "isDebit": true
  },
  {
    "name": "Expense2",
    "label": null,
    "id": "1642246460000",
    "date": "2023-01-15T00:00:00.000Z",
    "amount": "150",
    "isDebit": false
  },
  {
    "name": "Expense3",
    "label": null,
    "id": "1643751060000",
    "date": "2023-02-02T00:00:00.000Z",
    "amount": "80",
    "isDebit": true
  },
  {
    "name": "Expense4",
    "label": null,
    "id": "1645395260000",
    "date": "2023-02-20T00:00:00.000Z",
    "amount": "120",
    "isDebit": false
  },
  {
    "name": "Expense5",
    "label": null,
    "id": "1646549460000",
    "date": "2023-03-05T00:00:00.000Z",
    "amount": "200",
    "isDebit": true
  },
  {
    "name": "Expense6",
    "label": null,
    "id": "1647747060000",
    "date": "2023-03-18T00:00:00.000Z",
    "amount": "90",
    "isDebit": false
  },
  {
    "name": "Expense7",
    "label": null,
    "id": "1649107260000",
    "date": "2023-04-10T00:00:00.000Z",
    "amount": "180",
    "isDebit": true
  },
  {
    "name": "Expense8",
    "label": null,
    "id": "1650015060000",
    "date": "2023-04-25T00:00:00.000Z",
    "amount": "130",
    "isDebit": false
  },
  {
    "name": "Expense9",
    "label": null,
    "id": "1651403860000",
    "date": "2023-05-08T00:00:00.000Z",
    "amount": "160",
    "isDebit": true
  },
  {
    "name": "Expense10",
    "label": null,
    "id": "1652305460000",
    "date": "2023-05-22T00:00:00.000Z",
    "amount": "110",
    "isDebit": false
  },{
    "name":"expense11",
    "label":"",
    "id":"001",
    "date":"2024-01-07T00:00:00.000Z",
    "amount":"15",
    "isDebit":true
  },{
    "name":"expense12",
    "label":"",
    "id":"002",
    "date":"2024-01-08T00:00:00.000Z",
    "amount":"75",
    "isDebit":true
  }
]
""";

  @override
  void initState() {
    // if this is the 1st time ever open in the app, then create default data
    if (_myBox.get("expenses") == null) {
      DataBase.createInitialData();
    } else {
      // there already exists data
    }
    DataBase.loadExpenses().then((value) {
      setState(() {
        json = value;
        DataBase.expenses = Expense.listFromRawJson(json);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _foundExpense = DataBase.expenses;
    _foundExpense.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date!);
      DateTime dateB = DateTime.parse(b.date!);
      return dateB.compareTo(dateA);
    });
    // // Group objects by month and year
    Map<String, List<Expense>> groupedObjects = {};

    for (Expense obj in _foundExpense) {
      String monthYear = obj.getMonthYear();
      if (!groupedObjects.containsKey(monthYear)) {
        groupedObjects[monthYear] = [];
      }
      groupedObjects[monthYear]!.add(obj);
    }

    // // Create a list of widgets for ListView.builder
    // double sum = 0;
    // groupedObjects.forEach((monthYear, objects) {
    //   for (var obj in objects) {
    //     obj.isDebit ?? true
    //         ? sum -= double.parse(obj.amount ?? "0")
    //         : sum += double.parse(obj.amount ?? "0");
    //   }

    //   widgets.add(
    //     Container(
    //       color: bgcolor,
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           // Header with month and year
    //           Row(
    //             children: [
    //               Text(
    //                 monthYear,
    //                 style: const TextStyle(
    //                     fontSize: 20,
    //                     fontWeight: FontWeight.bold,
    //                     color: textcolor),
    //               ),
    //               const Spacer(),
    //               Padding(
    //                 padding: const EdgeInsets.only(right: 8.0),
    //                 child: Text(
    //                   sum.toString(),
    //                   style: const TextStyle(
    //                       fontSize: 20,
    //                       fontWeight: FontWeight.bold,
    //                       color: textcolor),
    //                 ),
    //               )
    //             ],
    //           ),
    //           const Divider(
    //             thickness: 0.5,
    //           ),
    //           // List of items for that month and year
    //           for (Expense obj in objects)
    //             ListTile(
    //               key: Key(obj.id ?? ""),
    //               tileColor: itemcolor,
    //               title: Text(
    //                 obj.name ?? "hi",
    //                 style: const TextStyle(color: textcolor),
    //               ),
    //               subtitle: Text(
    //                 DateFormat.yMEd().format(
    //                   DateTime.parse(obj.date!),
    //                 ),
    //                 style: const TextStyle(color: textcolor),
    //               ),
    //               trailing: Text(
    //                 (obj.isDebit ?? false ? "- " : "+ ") +
    //                     (obj.amount ?? "N/A"),
    //                 style: TextStyle(
    //                     fontSize: 20,
    //                     fontWeight: FontWeight.w900,
    //                     color:
    //                         (obj.isDebit ?? false) ? Colors.red : Colors.green),
    //               ),
    //             ),
    //           // Divider between months
    //           const Divider(
    //             thickness: 2,
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // });

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
                DataBase.expFile != null
                    ? Share.shareXFiles([XFile(DataBase.expFile?.path ?? "")])
                    : null;
              },
              icon: const Icon(Icons.share))
        ],
      ),
      body: ListView.builder(
        itemCount: groupedObjects.length * 2, // *2 for dividers
        itemBuilder: (context, index) {
          if (index.isOdd) {
            // Divider
            return const Divider(thickness: 2);
          }

          // Header or List Item
          int headerIndex = index ~/ 2;
          String monthYear = groupedObjects.keys.elementAt(headerIndex);
          List<Expense> objects = groupedObjects[monthYear]!;

          double sum = 0;
          for (var obj in objects) {
            obj.isDebit ?? true
                ? sum -= double.parse(obj.amount ?? "0")
                : sum += double.parse(obj.amount ?? "0");
          }

          return Container(
            color: bgcolor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with month and year
                Row(
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
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textcolor),
                      ),
                    )
                  ],
                ),
                const Divider(
                  thickness: 0.5,
                ),
                // List of items for that month and year
                for (Expense obj in objects)
                  ListTile(
                    key: Key(obj.id ?? ""),
                    tileColor: itemcolor,
                    title: Text(
                      obj.name ?? "hi",
                      style: const TextStyle(color: textcolor),
                    ),
                    subtitle: Text(
                      DateFormat.yMEd().format(
                        DateTime.parse(obj.date!),
                      ),
                      style: const TextStyle(color: textcolor),
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
              ],
            ),
          );
        },
      )
      // ListView.builder(
      //     itemCount: _foundExpense.length,
      //     itemBuilder: (context, ind) {
      //       return
      //     }),
      ,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.07, right: 10),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (_) => const PaymntBottomSheet());
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
