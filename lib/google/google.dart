import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:lazyext/preferences.dart';

// See https://github.com/dart-lang/sdk/issues/30074, come on...
typedef ApiCreator<A> = A Function(Client);

class GoogleApi<A> {
  List<String> get scopes {
    return [];
  }

  final Google _google;
  final ApiCreator<A> _apiCreator;
  A? api;

  GoogleApi(this._google, this._apiCreator) {
    Future<bool> result = _google.requestScopes(scopes);
    result.then((bool resullt) async {
      Client? client = await _google.getAuthenticatedClient();
      if (client != null) {
        api = _apiCreator(client);
      }
    });
  }

  Future<void> waitForApi() async {
    while (api == null) {
      await Future.delayed(const Duration(microseconds: 100));
    }
  }

  Future<R?> getResponse<R>(Future<R?>? Function() request) async {
    await waitForApi();
    try {
      return await request();
    } on AccessDeniedException {
      await _google._signIn();
      return await request();
    }
  }

  Future<List<R>> getAll<R>(
      Future<(List<R>, String?)?> Function({String? token, int pageSize})
          request,
      {int pageSize = 20}) async {
    List<R> elems = [];
    String? lastToken;
    (List<R>, String?)? result;
    do {
      lastToken = result?.$2;
      result = await request(token: lastToken, pageSize: pageSize);
      elems.addAll(result?.$1 ?? []);
    } while (result?.$2 != lastToken || result?.$1.length == pageSize);
    return elems;
  }
}

class Google extends ChangeNotifier {
  late final GoogleSignIn _api = GoogleSignIn(scopes: _scopes);
  List<String> _scopes = [];
  GoogleSignInAccount? _account;
  GoogleSignInAccount? get account {
    return _account;
  }

  set account(GoogleSignInAccount? account) {
    _account = account;
    dynamic prefs = Preferences();
    account?.authentication.then((GoogleSignInAuthentication auth) =>
        prefs.googleToken = auth.accessToken);
  }

  Future<void> _signIn() async {
    _api.onCurrentUserChanged.listen((GoogleSignInAccount? newAccount) {
      account ??= newAccount;
      if (account != null) {
        notifyListeners();
      }
    });
    account ??= await _api.signInSilently();
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

  Future<AuthClient?> _loadStoredAuthenticatedClient() async {
    dynamic prefs = Preferences();
    String? token = await prefs.googleToken;
    if (token != null) {
      final gapis.AccessCredentials credentials = gapis.AccessCredentials(
        gapis.AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(const Duration(days: 365)),
        ),
        null,
        _scopes,
      );

      return gapis.authenticatedClient(Client(), credentials);
    } else {
      return null;
    }
  }

  Future<Client?> getAuthenticatedClient() async {
    Client? client = await _loadStoredAuthenticatedClient();
    if (client == null) {
      await _signIn();
      client = await _api.authenticatedClient();
    }
    return client;
  }
}
