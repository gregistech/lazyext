import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:gdrawer/gdrawer.dart';
import 'package:lazyext/google/google.dart';
import 'package:provider/provider.dart';

class GoogleAccountHeader extends StatelessWidget {
  const GoogleAccountHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Google>(
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
                    subtitle: Text(snapshot.data?.email ?? "Not logged in"));
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
    );
  }
}

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const GDrawer(header: GoogleAccountHeader(), children: [
      DrawerTile(
          title: "Documents",
          path: "/sources",
          icon: Icon(Icons.folder_rounded)),
      DrawerTile(
          title: "Settings",
          path: "/settings",
          icon: Icon(Icons.settings_rounded)),
    ]);
  }
}
