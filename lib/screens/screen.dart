import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final TabBar? bottom;
  const ScreenWidget(
      {super.key, required this.title, required this.child, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(title),
            bottom: bottom,
            leading: Visibility(
              visible: context.canPop(),
              replacement: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  context.pop();
                },
              ),
            )),
        body:
            Flex(direction: Axis.vertical, children: [Expanded(child: child)]));
  }
}
