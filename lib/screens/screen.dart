import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  const ScreenWidget(
      {super.key,
      required this.title,
      required this.child,
      this.bottom,
      this.floatingActionButton,
      this.floatingActionButtonLocation,
      this.floatingActionButtonAnimator,
      this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        floatingActionButtonAnimator: floatingActionButtonAnimator,
        appBar: AppBar(
            title: Text(title),
            bottom: bottom,
            actions: actions,
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
