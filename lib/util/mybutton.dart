// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import '../util/constants.dart';

class MyButton extends StatelessWidget {
  final String text;
  VoidCallback onPressed;
  MyButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: itemcolor,
      child: Text(text,
      style: const TextStyle(color: textcolor),),
    );
  }
}
