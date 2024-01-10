import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_tracker/data/database.dart';

class PaymntBottomSheet extends StatefulWidget {
  const PaymntBottomSheet({super.key});

  @override
  State<PaymntBottomSheet> createState() => _PaymntBottomSheetState();
}

class _PaymntBottomSheetState extends State<PaymntBottomSheet> {
  var tags = ["Mandir", "Food", "Fast Food", "Donation", "Travel", "Other"];
  List<String> selectedTags = [];
  final List<Expense> _foundExpense = [];
  final _titlecontroller = TextEditingController();
  final _amountController = TextEditingController();
  final DataBase db = DataBase();
  bool _isDebit = false;

  DateTime? _selectedDate = DateTime.now();

  bool _validate = false;

  late TextEditingController _selectedTagController;

// checkbox was tapped
  // void checkBoxChanged(Expense exp) {
  //   setState(() {
  //     exp.isDebit = !(exp.isDebit ?? false);
  //   });
  //   db.updateDatabase();
  // }

  // save new task
  void saveNewTask() {
    setState(() {
      DataBase.expenses.add(Expense(
          name: _titlecontroller.text,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate != null
              ? _selectedDate?.toIso8601String()
              : DateTime.now().toIso8601String(),
          amount: (_amountController.text),
          label: selectedTags,
          isDebit: _isDebit));
      _titlecontroller.clear();
      _amountController.clear();
      print(DataBase.expenses);
      // db.updateDatabase();
      var newList = Expense.listToJson(DataBase.expenses);
      var newJson = jsonEncode({"expense": newList});
      debugPrint("newJson $newJson");
      DataBase.saveExpenses(newJson);
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6 +
            (MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            child: Column(
              children: [
                TextField(
                  controller: _titlecontroller,
                  decoration: const InputDecoration(label: Text("Name")),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}$')),
                  ],
                  decoration: InputDecoration(
                      label: Text("Amount"),
                      errorText: _validate ? "Please Fill the Amount" : null),
                ),
                Autocomplete<String>(
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Material(
                      type: MaterialType.transparency,
                      child: SingleChildScrollView(
                        child: Column(
                          children: options.map((opt) {
                            return InkWell(
                              onTap: () {
                                onSelected(opt);
                              },
                              child: Container(
                                padding: const EdgeInsets.only(right: 60),
                                child: Card(
                                  child: Container(
                                    width: double.infinity - 60,
                                    padding: const EdgeInsets.all(10),
                                    child: Text(opt),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController selectedTagController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    _selectedTagController = selectedTagController;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tags",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Wrap(
                              spacing:
                                  8.0, // Horizontal spacing between widgets
                              runSpacing: 8.0, // Vertical spacing between lines
                              children: selectedTags
                                  .map((e) => Chip(
                                        backgroundColor: Colors.blueGrey,
                                        labelPadding:
                                            const EdgeInsets.only(left: 8.0),
                                        label: Text(
                                          e,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        shape: RoundedRectangleBorder(
                                            side: const BorderSide(
                                                width: 0.5,
                                                color: Colors.white54),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.yellow,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            selectedTags.remove(e);
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: "Enter Tag",
                                hintStyle: TextStyle(
                                    color: Colors.white54), // Hint text color
                              ),
                              controller: selectedTagController,
                              focusNode: focusNode,
                              onSubmitted: (String value) {
                                if (!selectedTags.contains(value)) {
                                  setState(() {
                                    selectedTags.add(value);
                                  });
                                  selectedTagController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return tags;
                    } else {
                      List<String> matches = <String>[];
                      matches.addAll(tags);

                      matches.retainWhere((s) {
                        return s
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                      return matches;
                    }
                  },
                  onSelected: (String option) {
                    if (!selectedTags.contains(option)) {
                      setState(() {
                        selectedTags.add(option);
                        _selectedTagController.clear();
                      });
                    }
                  },
                ),
                TextButton(
                    onPressed: () {
                      showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2200))
                          .then((picked) {
                        if (picked != null) {
                          return;
                        }
                        setState(() {
                          _selectedDate = picked;
                        });
                      });
                    },
                    child: Text((_selectedDate != null
                        ? DateFormat.yMEd().format(_selectedDate!)
                        : "Select Date"))),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Switch(
                          thumbIcon: const MaterialStatePropertyAll(Icon(
                            Icons.attach_money,
                            color: Colors.white,
                          )),
                          activeTrackColor: Colors.red,
                          thumbColor: MaterialStatePropertyAll(Colors.yellow),
                          overlayColor: MaterialStatePropertyAll(Colors.green),
                          trackOutlineColor: MaterialStatePropertyAll(
                              _isDebit ? Colors.amber : Colors.green),
                          key: UniqueKey(),
                          value: _isDebit,
                          onChanged: (val) {
                            setState(() {
                              _isDebit = val;
                            });
                          }),
                      // Checkbox(
                      //     value: _isDebit,
                      //     onChanged: (newVal) {
                      //       setState(() {
                      //         _isDebit = newVal ?? false;
                      //       });
                      //     }),
                      const Text("Debit"),
                      const Spacer(),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _validate = _amountController.text.isEmpty;
                            });
                            _validate ? null : saveNewTask();
                            debugPrint("${_foundExpense}");
                          },
                          child: const Text("Add"))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
