import 'package:flutter/material.dart';

class ScreenWidget extends StatelessWidget {
  final String title;
  final Widget child;
  const ScreenWidget({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body:
            Flex(direction: Axis.vertical, children: [Expanded(child: child)]));
  }
}
