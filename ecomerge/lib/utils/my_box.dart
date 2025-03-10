import 'package:flutter/material.dart';
class Mybox extends StatelessWidget {
  const Mybox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.blue,
      ),
    );
  }
}
