import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/main.dart';
import 'package:personal_finance_tracker/presentation/bottomsheet.dart';
import 'package:personal_finance_tracker/presentation/searchpage.dart';
import 'package:personal_finance_tracker/util/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DataBase db = DataBase();
  var tags = ["Food", "Fast Food", "Donation", "Travel", "Other"];
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

  // delete task
  void deleteExpense(String id) {
    setState(() {
      DataBase.expenses.removeWhere((item) => item.id == id);
    });
    db.updateDatabase();
    debugPrint(DataBase.expenses.toString());
    setState(() {
      expenseNotifier.update(DataBase.expenses);
    });
  }

  requestStoragePermission() async {
    bool isDenied = await Permission.accessMediaLocation.isDenied;
    if (isDenied) {
      await Permission.accessMediaLocation.request();
    }
    var status = await Permission.accessMediaLocation.status;

    if (status != PermissionStatus.granted && mounted) {
      setState(() {
        DataBase.isPermitted = true;
      });
      openAppSettings();
    } else {
      setState(() {
        DataBase.isPermitted = false;
      });
    }
  }

  @override
  void initState() {
   // requestStoragePermission();
    DataBase.loadExpenses().then((value) {
      setState(() {
        json = value;
        debugPrint(json);
        DataBase.expenses = Expense.listFromRawJson(json);
        var allTags = [];
        for (Expense obj in DataBase.expenses) {
          if (obj.date != null) {
            var year = DateTime.parse(obj.date!).year;
            debugPrint("$year ${DataBase.uniqueyears.contains(year)}");
            if (!DataBase.uniqueyears.contains(year)) {
              DataBase.uniqueyears.add(year);
            }
            debugPrint("sa ${DataBase.uniqueyears}");
          }
          if (obj.label != null) {
            allTags.addAll(obj.label!);
          }
        }
        DataBase.uniqueTags = Set<String>.from(allTags);
        expenseNotifier.update(Expense.listFromRawJson(json));
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    expenseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: expenseNotifier.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 100, maxWidth: 100),
                child: const CircularProgressIndicator());
          }
          _foundExpense = snapshot.data ?? [];
          debugPrint("found length ${DataBase.expenses.length}");
          _foundExpense.sort((a, b) {
            DateTime dateA = DateTime.parse(a.date!);
            DateTime dateB = DateTime.parse(b.date!);
            return dateB.compareTo(dateA);
          });
          var filterObjects = _foundExpense.where((obj) {
            // Return true if all tags in the object's list are contained within DB.selectedTags
            return ((DataBase.selectedTags.isNotEmpty
                    ? obj.label?.any(
                            (tag) => DataBase.selectedTags.contains(tag)) ??
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
                    color: textcolor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.black,
              elevation: 10,
              actions: [
                IconButton(
                    onPressed: () {
                      // DataBase.expFile != null
                      //     ? Share.shareXFiles([XFile(DataBase.expFile?.path ?? "")])
                      //     : null;

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SearchPage(
                                    onPopCallback: () {
                                      setState(() {});
                                    },
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
                        String monthYear =
                            groupedObjects.keys.elementAt(headerIndex);
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
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
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
                              // const Divider(
                              //   thickness: 0.5,
                              // ),
                              // List of items for that month and year
                              for (Expense obj in objects)
                                Column(
                                  children: [
                                    Slidable(
                                      endActionPane: ActionPane(
                                          motion: const StretchMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) =>
                                                  deleteExpense(obj.id ?? ""),
                                              label: "DELETE",
                                              backgroundColor: Colors.red,
                                            )
                                          ]),
                                      child: ListTile(
                                        key: Key(obj.id ?? ""),
                                        tileColor: itemcolor,
                                        title: Text(
                                          obj.name ?? "hi",
                                          style:
                                              const TextStyle(color: textcolor),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('E dd/MM/yyyy').format(
                                                DateTime.parse(obj.date!),
                                              ),
                                              style: const TextStyle(
                                                  color: textcolor),
                                            ),
                                            SizedBox(
                                              height: 50,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  100,
                                              child: ListView.builder(
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      obj.label?.length ?? 0,
                                                  itemBuilder: (context, ind) =>
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Chip(
                                                            labelStyle:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            label: Text(
                                                                obj.label?[
                                                                        ind] ??
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
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const PaymntBottomSheet(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.8, 0.8);
                            const end = Offset.zero;
                            const curve = Curves.fastEaseInToSlowEaseOut;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          }));
                },
                child: const Icon(Icons.add),
              ),
            ),
          );
        });
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
}
