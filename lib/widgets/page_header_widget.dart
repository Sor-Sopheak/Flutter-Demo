import 'package:flutter/material.dart';
import 'package:flutter_demo/constants/color_constants.dart';

class PageHeaderWidget extends StatelessWidget {
  final String title;
  final double? fontSize;
  const PageHeaderWidget({super.key, required this.title, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Color(primaryTextColor),
        fontWeight: FontWeight.w500,
        fontSize: fontSize,
      ),
    );
  }
}
