import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:go_router/go_router.dart';
import 'package:lazyext/google/google.dart';
import 'package:lazyext/preferences.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    dynamic prefs = Preferences();
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 250,
          child: Consumer<Google>(
            builder: (BuildContext context, Google google, _) => DrawerHeader(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<dynamic>(
                    future: prefs.name,
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> nameSnapshot) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<dynamic>(
                                future: prefs.photo,
                                builder: (BuildContext context,
                                    AsyncSnapshot<dynamic> photoSnapshot) {
                                  return ProfilePicture(
                                    name: google.account?.displayName ??
                                        nameSnapshot.data ??
                                        "Anonymous",
                                    img: google.account?.photoUrl ??
                                        photoSnapshot.data,
                                    radius: 31,
                                    fontsize: 21,
                                  );
                                }),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(google.account?.displayName ??
                                    nameSnapshot.data ??
                                    "Anonymous"),
                                FutureBuilder<dynamic>(
                                    future: prefs.email,
                                    builder: (BuildContext context,
                                        AsyncSnapshot<dynamic> emailSnapshot) {
                                      return Text(google.account?.email ??
                                          emailSnapshot.data ??
                                          "Not logged in");
                                    }),
                              ],
                            ),
                          ]);
                    }),
                TextButton(
                    onPressed: () async {
                      google.logOut();
                    },
                    child: const Text("Log out")),
              ],
            )),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.class_rounded),
          title: const Text("Courses"),
          onTap: () {
            context.go("/courses");
            context.pop();
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
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
