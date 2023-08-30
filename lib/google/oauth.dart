import 'package:flutter/material.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:http/http.dart';

import 'google.dart';

class OAuth extends GoogleApi<Oauth2Api> with ChangeNotifier {
  OAuth(Google google) : super(google, (Client client) => Oauth2Api(client));

  // NOTE: pass a client to avoid a loop of asking for an account, and then needing an account for that...
  Future<Userinfo?> getUserInfo(String idToken, {Client? client}) async {
    Future<Userinfo?> request(Oauth2Api api) async => api.userinfo.get();
    if (client == null) {
      return await getResponse(request);
    } else {
      return await request(Oauth2Api(client));
    }
  }
}
