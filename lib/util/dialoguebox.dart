// ignore_for_file: must_be_immutable, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:personal_bahi_khata/util/mybutton.dart';
import '../util/constants.dart';

class DialogBox extends StatelessWidget {
  final titlecontroller;
  final desccontroller;
  VoidCallback onSave;
  VoidCallback onCancel;

  DialogBox({
    super.key,
    required this.titlecontroller,
    required this.onSave,
    required this.onCancel,
    required this.desccontroller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: bgcolor,
      content: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // get user input
            TextField(
              style: const TextStyle(color: textcolor),
              controller: titlecontroller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Add a new task",
                hintStyle: TextStyle(color: hintcol),
              ),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              style: const TextStyle(color: textcolor),
              controller: desccontroller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Description",
                hintStyle: TextStyle(color: hintcol),
              ),
              textInputAction: TextInputAction.done,
            ),

            // buttons -> save + cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // save button
                MyButton(text: "Save", onPressed: onSave),

                const SizedBox(width: 15),

                // cancel button
                MyButton(text: "Cancel", onPressed: onCancel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
