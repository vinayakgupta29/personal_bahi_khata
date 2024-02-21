import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/data/database.dart';
import 'package:personal_finance_tracker/util/constants.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onPopCallback;

  const SearchPage({super.key, required this.onPopCallback});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int selectedMonth = DataBase.selectedDate?.month ?? 0;

  int selectedYear = DataBase.selectedDate?.year ?? 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (val) {
        if (widget.onPopCallback != null) {
          widget.onPopCallback!();
        }
      },
      child: Scaffold(
        backgroundColor: bgcolor,
        appBar: AppBar(
          title: const Text(
            "Search",
            style: TextStyle(
                color: textcolor, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(
              Icons.check_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (widget.onPopCallback != null) {
                DataBase.selectedDate = selectedMonth != 0 && selectedYear != 0
                    ? DateTime(selectedYear, selectedMonth, 1)
                    : null;
                widget.onPopCallback!();
              }
            },
          ),
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    elevation: 16,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(
                      height: 2,
                      color: Colors.indigo,
                    ),
                    dropdownColor: bgcolor,
                    menuMaxHeight: 300,
                    onChanged: (int? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        selectedMonth = value ?? 0;
                      });
                    },
                    items: const [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text("---"),
                      ),
                      DropdownMenuItem<int>(
                        value: 1,
                        child: Text("January"),
                      ),
                      DropdownMenuItem<int>(
                        value: 2,
                        child: Text("February"),
                      ),
                      DropdownMenuItem<int>(
                        value: 3,
                        child: Text("March"),
                      ),
                      DropdownMenuItem<int>(
                        value: 4,
                        child: Text("April"),
                      ),
                      DropdownMenuItem<int>(
                        value: 5,
                        child: Text("May"),
                      ),
                      DropdownMenuItem<int>(
                        value: 6,
                        child: Text("June"),
                      ),
                      DropdownMenuItem<int>(
                        value: 7,
                        child: Text("July"),
                      ),
                      DropdownMenuItem<int>(
                        value: 8,
                        child: Text("August"),
                      ),
                      DropdownMenuItem<int>(
                        value: 9,
                        child: Text("September"),
                      ),
                      DropdownMenuItem<int>(
                        value: 10,
                        child: Text("October"),
                      ),
                      DropdownMenuItem<int>(
                        value: 11,
                        child: Text("November"),
                      ),
                      DropdownMenuItem<int>(
                        value: 12,
                        child: Text("December"),
                      ),
                    ],
                  ),
                  DropdownButton(
                      value: selectedYear,
                      elevation: 16,
                      style: const TextStyle(color: Colors.white),
                      underline: Container(
                        height: 2,
                        color: Colors.indigo,
                      ),
                      dropdownColor: bgcolor,
                      menuMaxHeight: 300,
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text("---"),
                        ),
                        ...DataBase.uniqueyears
                            .map((e) => DropdownMenuItem<int>(
                                value: e, child: Text(e.toString())))
                            .toList()
                      ],
                      onChanged: (int? val) {
                        setState(() {
                          selectedYear = val ?? 0;
                        });
                      })
                ],
              ),
              Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.center,
                  spacing: 8.0, // Spacing between chips
                  runSpacing: 8.0, // Spacing between lines
                  children: DataBase.uniqueTags
                      .toList()
                      .map(
                        (e) => ChoiceChip(
                            side: BorderSide(
                                color: DataBase.selectedTags.contains(e)
                                    ? Colors.indigo
                                    : Colors.blue),
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30))),
                            backgroundColor: bgcolor,
                            selectedColor: Colors.indigo,
                            checkmarkColor: Colors.white,
                            label: Text(
                              e,
                              style: TextStyle(
                                color: DataBase.selectedTags.contains(e)
                                    ? const Color(0xFFF7F7F7)
                                    : Colors.blue,
                              ),
                            ),
                            selected: DataBase.selectedTags.contains(e),
                            onSelected: (bool value) {
                              debugPrint(DataBase.uniqueTags.toString());
                              if (DataBase.selectedTags.contains(e)) {
                                DataBase.selectedTags.remove(e);
                              } else {
                                DataBase.selectedTags.add(e);
                              }
                              setState(() {});
                            }),
                      )
                      .toList()),
            ],
          ),
        ),
      ),
    );
  }
}
