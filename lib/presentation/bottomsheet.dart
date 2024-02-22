import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/main.dart';

class PaymntBottomSheet extends StatefulWidget {
  const PaymntBottomSheet({super.key});

  @override
  State<PaymntBottomSheet> createState() => _PaymntBottomSheetState();
}

class _PaymntBottomSheetState extends State<PaymntBottomSheet> {
  var tags = ["Food", "Fast Food", "Donation", "Travel", "Other"];
  List<String> selectedTags = [];
  final List<Expense> _foundExpense = [];
  final _titlecontroller = TextEditingController();
  final _amountController = TextEditingController();
  final DataBase db = DataBase();
  bool _isDebit = true;
  DateTime now = DateTime.now();
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
      // db.updateDatabase();

      expenseNotifier.update(DataBase.expenses);
      var newList = Expense.listToJson(DataBase.expenses);
      var newJson = jsonEncode({"expense": newList});
      debugPrint("newJson $newJson");
      DataBase.saveExpenses(newJson);
    });
    for (var tag in selectedTags) {
      if (!DataBase.uniqueTags.contains(tag)) {
        DataBase.uniqueTags.add(tag);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titlecontroller,
                    decoration: InputDecoration(
                        label: const Text("Name"),
                        errorText: _validate ? "Please Fill the Name" : null),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
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
                        label: const Text("Amount"),
                        errorText: _validate ? "Please Fill the Amount" : null),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Autocomplete<String>(
                      optionsViewBuilder: (BuildContext context,
                          AutocompleteOnSelected<String> onSelected,
                          Iterable<String> options) {
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Material(
                            color: Colors.white,
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: options.map((opt) {
                                return InkWell(
                                  onTap: () {
                                    onSelected(opt);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 25.0),
                                    child: Card(
                                      color: Colors.white,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                20,
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Wrap(
                                  spacing:
                                      8.0, // Horizontal spacing between widgets
                                  runSpacing:
                                      8.0, // Vertical spacing between lines
                                  children: selectedTags
                                      .map((e) => Chip(
                                            backgroundColor: Colors.blueGrey,
                                            labelPadding: const EdgeInsets.only(
                                                left: 8.0),
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
                                    labelText: "Enter Tag",
                                    hintStyle: TextStyle(
                                        color:
                                            Colors.white54), // Hint text color
                                  ),
                                  controller: selectedTagController,
                                  focusNode: focusNode,
                                  onSubmitted: (String value) {
                                    if (!selectedTags.contains(value)) {
                                      if (value.isNotEmpty) {
                                        setState(() {
                                          selectedTags.add(value);
                                        });
                                      }
                                      selectedTagController.clear();
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
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
                  ),
                  TextButton(
                      onPressed: () {
                        showDatePicker(
                                context: context,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(2200),
                                initialEntryMode:
                                    DatePickerEntryMode.calendarOnly)
                            .then((picked) {
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        });
                      },
                      child: Text((_selectedDate != null
                          ? DateFormat.yMEd().format(_selectedDate!)
                          : "Select Date"))),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: Text("Credit"),
                        ),
                        Switch(
                            thumbIcon: const MaterialStatePropertyAll(Icon(
                              Icons.attach_money,
                              color: Colors.white,
                            )),
                            activeTrackColor: Colors.red,
                            thumbColor:
                                const MaterialStatePropertyAll(Colors.yellow),
                            overlayColor:
                                const MaterialStatePropertyAll(Colors.green),
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
                              debugPrint("$_foundExpense");
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
      ),
    );
  }
}
