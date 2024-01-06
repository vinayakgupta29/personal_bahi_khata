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
  final _myBox = Hive.box("financeBox");
  DataBase db = DataBase();
  var tags = ["Mandir", "Food", "Fast Food", "Donation", "Travel", "Other"];
  var selectedTags = [];
  List<Expense> _foundExpense = [];

  final _titlecontroller = TextEditingController();
  final _amountController = TextEditingController();

  bool _isDebit = false;

  DateTime? _selectedDate = DateTime.now();

// checkbox was tapped
  void checkBoxChanged(Expense exp) {
    setState(() {
      exp.isDebit = !(exp.isDebit ?? false);
    });
    db.updateDatabase();
  }

  // save new task
  void saveNewTask() {
    setState(() {
      db.expenses.add(Expense(
          name: _titlecontroller.text,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate != null
              ? _selectedDate?.toIso8601String()
              : DateTime.now().toIso8601String(),
          amount: (_amountController.text),
          isDebit: _isDebit));
      _titlecontroller.clear();
      _amountController.clear();
    });
    Navigator.of(context).pop();
    db.updateDatabase();
  }

  // delete task
  void deleteTask(String id) {
    setState(() {
      db.expenses.removeWhere((item) => item.id == id);
    });
    db.updateDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(label: Text("Amount")),
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
                            spacing: 8.0, // Horizontal spacing between widgets
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
                            style: const TextStyle(color: Colors.white),
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
                        thumbIcon:
                            const MaterialStatePropertyAll(Icon(Icons.abc)),
                        key: UniqueKey(),
                        value: _isDebit,
                        onChanged: (val) {
                          _isDebit = val;
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
                          saveNewTask();
                          //debugPrint("${_foundExpense}");
                        },
                        child: const Text("Add"))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
