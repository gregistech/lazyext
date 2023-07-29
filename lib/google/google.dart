import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart';

class Google extends ChangeNotifier {
  late final GoogleSignIn _api = GoogleSignIn(scopes: _scopes);
  List<String> _scopes = [];
  GoogleSignInAccount? account;

  Future<void> signIn() async {
    _api.onCurrentUserChanged.listen((GoogleSignInAccount? newAccount) {
      account = newAccount;
      if (account != null) {
        notifyListeners();
      }
    });
    account = await _api.signInSilently();
    account ??= await _api.signIn();
  }

  Future<bool> requestScopes(List<String> scopes) async {
    if (account == null) {
      _scopes += scopes;
      return true;
    } else {
      try {
        if (await _api.canAccessScopes(scopes)) {
          return true;
        } else {
          return await _api.requestScopes(scopes);
        }
      } on UnimplementedError {
        return await _api.requestScopes(scopes);
      }
    }
  }

  void onUserChange(Function(GoogleSignInAccount?) callback) {
    _api.onCurrentUserChanged.listen(callback);
  }

  Future<Client?> getAuthenticatedClient() async {
    return await _api.authenticatedClient();
  }
}
