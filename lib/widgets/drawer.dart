import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:go_router/go_router.dart';
import 'package:lazyext/google/google.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 250,
          child: Consumer<Google>(
            builder: (BuildContext context, Google google, _) => DrawerHeader(
                child: Visibility(
              visible: google.account != null,
              replacement: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Not logged in"),
                  TextButton(
                      onPressed: () async {
                        await google.signIn();
                      },
                      child: const Text("Sign in"))
                ],
              )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfilePicture(
                          name: google.account?.displayName ?? "Anonymous",
                          img: google.account?.photoUrl,
                          radius: 31,
                          fontsize: 21,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(google.account?.displayName ?? "Anonymous"),
                            Text(google.account?.email ?? "Not logged in"),
                          ],
                        ),
                      ]),
                  TextButton(
                      onPressed: () async {
                        google.logOut();
                      },
                      child: const Text("Log out")),
                ],
              ),
            )),
          ),
        ),
        ListTile(
          title: const Text("Courses"),
          onTap: () {
            context.go("/courses");
            context.pop();
          },
        ),
        ListTile(
          title: const Text("Settings"),
          onTap: () {
            context.push("/settings");
            context.pop();
          },
        )
      ],
    ));
  }
}
