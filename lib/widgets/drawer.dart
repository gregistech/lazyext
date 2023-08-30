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
        Consumer<Google>(
          builder: (BuildContext context, Google google, _) => DrawerHeader(
              child: Column(
            children: [
              FutureBuilder<GoogleAccount?>(
                  future: google.account,
                  builder: (BuildContext context,
                      AsyncSnapshot<GoogleAccount?> snapshot) {
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ProfilePicture(
                          name: snapshot.data?.name ?? "Anonymous",
                          img: snapshot.data?.photoUrl,
                          radius: 21,
                          fontsize: 21,
                        ),
                        title: Text(snapshot.data?.name ?? "Anonymous"),
                        subtitle:
                            Text(snapshot.data?.email ?? "Not logged in"));
                  }),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    google.logOut();
                  },
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text("Log out")),
            ],
          )),
        ),
        ListTile(
          leading: const Icon(Icons.class_rounded),
          title: const Text("Courses"),
          onTap: () {
            context.go("/courses");
            Scaffold.of(context).openEndDrawer();
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
          onTap: () {
            context.push("/settings");
            Scaffold.of(context).openEndDrawer();
          },
        )
      ],
    ));
  }
}
