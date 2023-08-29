import 'package:flutter/material.dart';
import 'package:googleapis/identitytoolkit/v1.dart';
import 'package:http/http.dart';

import 'google.dart';

class IdentityToolkit extends GoogleApi<IdentityToolkitApi>
    with ChangeNotifier {
  IdentityToolkit(Google google)
      : super(google, (Client client) => IdentityToolkitApi(client));

  Future<String?> getRefreshToken(String idToken) async {
    print("asdsasdsad");
    return await getResponse((api) async => (await api.accounts.signInWithIdp(
            GoogleCloudIdentitytoolkitV1SignInWithIdpRequest(
                idToken: idToken, returnRefreshToken: true)))
        .refreshToken);
  }
}
