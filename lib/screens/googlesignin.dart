import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazyext/google/google.dart';
import 'package:provider/provider.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  @override
  void initState() {
    Provider.of<Google>(context, listen: false)
        .forceSignIn()
        .then((_) => SystemNavigator.pop());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
