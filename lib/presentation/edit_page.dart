import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_bahi_khata/data/database.dart';
import 'package:personal_bahi_khata/main.dart';

class EditPage extends StatefulWidget {
  final Expense expense;
  const EditPage({super.key, required this.expense});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> with TickerProviderStateMixin {
  var tags = ["Food", "Fast Food", "Donation", "Travel", "Other"];
  List<String> selectedTags = [];
  final List<Expense> _foundExpense = [];
  final _titlecontroller = TextEditingController();
  final _amountController = TextEditingController();
  final DataBase db = DataBase();
  bool _isDebit = true;
  DateTime now = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  bool _validate = false;

  late TextEditingController _selectedTagController;

  late Animation _creditAnimation;
  late Animation _debitAnimation;

  late AnimationController _creditAnimationController;
  late AnimationController _debitAnimationController;
  // checkbox was tapped
  // void checkBoxChanged(Expense exp) {
  //   setState(() {
  //     exp.isDebit = !(exp.isDebit ?? false);
  //   });
  //   db.updateDatabase();
  // }

  // save new task
  void saveNewExpense() {
    setState(() {
      int index = DataBase.expenses.indexWhere(
        (e) => e.id == widget.expense.id,
      );
      if (index != -1) {
        DataBase.expenses[index] = Expense(
          name: _titlecontroller.text,
          date: widget.expense.date,
          id: widget.expense.id,
          amount: double.parse(_amountController.text).toString(),
          label: selectedTags,
          isDebit: _isDebit,
        );
      }
      // db.updateDatabase();

      expenseNotifier.update(DataBase.expenses);
      var newList = Expense.listToJson(DataBase.expenses);
      var newJson = jsonEncode({"expenses": newList});
      debugPrint("newJson $newJson");
      DataBase.saveExpenses(newJson, null);
    });
    for (var tag in selectedTags) {
      if (!DataBase.uniqueTags.contains(tag)) {
        DataBase.uniqueTags.add(tag);
      }
    }
    if (!DataBase.uniqueyears.contains(_selectedDate.year)) {
      DataBase.uniqueyears.add(_selectedDate.year);
    }
    DataBase.selectedTags = [];
    DataBase.selectedDate = null;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _creditAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _debitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _creditAnimation = Tween(
      begin: 0.0,
      end: -10.0,
    ).animate(_creditAnimationController);
    _debitAnimation = Tween(
      begin: 0.0,
      end: 10.0,
    ).animate(_debitAnimationController);
    _creditAnimationController.reset();

    _titlecontroller.text = widget.expense.name ?? "";
    _amountController.text = widget.expense.amount ?? "";
    _isDebit = widget.expense.isDebit ?? false;
    _selectedDate = DateTime.parse(
      widget.expense.date ?? DateTime.now().toIso8601String(),
    );
    selectedTags = widget.expense.label ?? [];
  }

  void _animatePlusIcon() {
    // Forward, reverse, reset the animation for each loop
    _creditAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      _creditAnimationController.reverse();
      Future.delayed(const Duration(milliseconds: 250), () {
        _creditAnimationController.reset();
      });
    });
  }

  void _animateMinusIcon() {
    // Forward, reverse, reset the animation for each loop
    _debitAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      _debitAnimationController.reverse();
      Future.delayed(const Duration(milliseconds: 250), () {
        _debitAnimationController.reset();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _creditAnimationController.dispose();
    _debitAnimationController.dispose();
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _titlecontroller,
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      decoration: InputDecoration(
                        label: const Text("Name"),
                        labelStyle: const TextStyle(color: Color(0xFF69656F)),
                        errorText: _validate ? "Please Fill the Name" : null,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}$'),
                        ),
                      ],
                      decoration: InputDecoration(
                        label: const Text("Amount"),
                        labelStyle: const TextStyle(color: Color(0xFF69656F)),
                        errorText: _validate ? "Please Fill the Amount" : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Autocomplete<String>(
                      optionsViewBuilder: (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Material(
                            color: Colors.white,
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children:
                                  options.map((opt) {
                                    return InkWell(
                                      onTap: () {
                                        onSelected(opt);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 25.0,
                                        ),
                                        child: Card(
                                          color: Colors.white,
                                          child: Container(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width -
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
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController selectedTagController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
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
                                const Text(
                                  "Tags",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Wrap(
                                  spacing:
                                      8.0, // Horizontal spacing between widgets
                                  runSpacing:
                                      8.0, // Vertical spacing between lines
                                  children:
                                      selectedTags
                                          .map(
                                            (e) => Chip(
                                              backgroundColor: Colors.blueGrey,
                                              labelPadding:
                                                  const EdgeInsets.only(
                                                    left: 8.0,
                                                  ),
                                              label: Text(
                                                e,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                side: const BorderSide(
                                                  width: 0.5,
                                                  color: Colors.white54,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
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
                                            ),
                                          )
                                          .toList(),
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: "Enter Tag",
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                    ), // Hint text color
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
                            return s.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
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
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      ).then((picked) {
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      });
                    },
                    child: Text((DateFormat.yMEd().format(_selectedDate))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Row(
                            children: [
                              Text(
                                "Credit",
                                style: TextStyle(
                                  fontWeight:
                                      _isDebit
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _creditAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0.0, _creditAnimation.value),
                                    child: Text(
                                      String.fromCharCode(
                                        Icons
                                            .keyboard_arrow_up_rounded
                                            .codePoint,
                                      ),
                                      style: TextStyle(
                                        inherit: false,
                                        color: Colors.green,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        fontFamily:
                                            Icons
                                                .keyboard_arrow_down
                                                .fontFamily,
                                        package:
                                            Icons
                                                .keyboard_arrow_down
                                                .fontPackage,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          thumbIcon: const WidgetStatePropertyAll(
                            Icon(Icons.attach_money, color: Color(0xff663399)),
                          ),
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.green,
                          thumbColor: const WidgetStatePropertyAll(
                            Colors.yellow,
                          ),
                          overlayColor: const WidgetStatePropertyAll(
                            Colors.green,
                          ),
                          trackOutlineColor: WidgetStatePropertyAll(
                            _isDebit ? Colors.red : Colors.green,
                          ),
                          key: UniqueKey(),
                          value: _isDebit,
                          onChanged: (val) {
                            val ? _animateMinusIcon() : _animatePlusIcon();
                            setState(() {
                              _isDebit = val;
                            });
                            debugPrint("$_isDebit");
                          },
                        ),
                        // Checkbox(
                        //     value: _isDebit,
                        //     onChanged: (newVal) {
                        //       setState(() {
                        //         _isDebit = newVal ?? false;
                        //       });
                        //     }),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Row(
                            children: [
                              Text(
                                "Debit",
                                style: TextStyle(
                                  fontWeight:
                                      _isDebit
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _debitAnimation,
                                builder:
                                    (context, child) => Transform.translate(
                                      offset: Offset(
                                        0.0,
                                        _debitAnimation.value,
                                      ),
                                      child: Text(
                                        String.fromCharCode(
                                          Icons
                                              .keyboard_arrow_down_rounded
                                              .codePoint,
                                        ),
                                        style: TextStyle(
                                          inherit: false,
                                          color: Colors.red,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          fontFamily:
                                              Icons
                                                  .keyboard_arrow_down
                                                  .fontFamily,
                                          package:
                                              Icons
                                                  .keyboard_arrow_down
                                                  .fontPackage,
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _validate = _amountController.text.isEmpty;
                            });
                            _validate ? null : saveNewExpense();
                            debugPrint("$_foundExpense");
                          },
                          child: const Text("Save"),
                        ),
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
