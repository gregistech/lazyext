import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:lazyext/app/preferences.dart';

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
    _google.requestScopes(scopes).then((bool resullt) async {
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
    return await request();
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
      result = await getResponse(
          () => request(token: lastToken, pageSize: pageSize));
      elems.addAll(result?.$1 ?? []);
    } while (result?.$2 != lastToken || result?.$1.length == pageSize);
    return elems;
  }
}

/*class Google extends ChangeNotifier {
  final String clientId;
  late final GoogleSignIn _api =
      GoogleSignIn(scopes: _scopes, forceCodeForRefreshToken: true);
  List<String> _scopes = [];
  GoogleSignInAccount? _account;

  Google({required this.clientId});

  GoogleSignInAccount? get account => _account;

  set account(GoogleSignInAccount? account) {
    _account = account;
    dynamic prefs = Preferences();
    account?.authentication.then((GoogleSignInAuthentication auth) {
      prefs.accessToken = auth.accessToken;
      prefs.idToken = auth.idToken;
    });
    prefs.name = account?.displayName;
    prefs.email = account?.email;
    prefs.photo = account?.photoUrl;
    notifyListeners();
  }

  Future<void> invalidateStoredAccount() async {
    dynamic prefs = Preferences();
    prefs.accessToken = null;
    prefs.idToken = null;
    prefs.name = null;
    prefs.email = null;
    prefs.photo = null;
    account = null;
    await logOut();
  }

  Future<void> signIn() async {
    print("asd");
    account ??= await _api.signInSilently();
    account ??= await _api.signIn();
  }

  Future<void> logOut() async {
    await _api.disconnect();
    await invalidateStoredAccount();
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

  Future<AccessCredentials?> _loadStoredCredentials() async {
    dynamic prefs = Preferences();
    String? accessToken = await prefs.accessToken;
    if (accessToken != null) {
      return gapis.AccessCredentials(
        gapis.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(days: 365)),
        ),
        await prefs.idToken,
        _scopes,
      );
    }
    return null;
  }

  Future<AuthClient?> _loadStoredAuthenticatedClient() async {
    AccessCredentials? credentials = await _loadStoredCredentials();
    if (credentials != null) {
      return gapis.autoRefreshingClient(
          ClientId(clientId), credentials, Client());
    } else {
      return null;
    }
  }

  Future<Client?> getAuthenticatedClient() async {
    Client? client = await _loadStoredAuthenticatedClient();
    if (client == null) {
      await signIn();
      client = await _api.authenticatedClient();
    }
    return client;
  }
}*/

class Google extends ChangeNotifier {
  final String clientId;
  List<String> _scopes = [];

  Google({required this.clientId});

  late final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: _scopes, forceCodeForRefreshToken: true);
  GoogleSignInAccount? get account => _googleSignIn.currentUser;

  dynamic prefs = Preferences();

  Future<void> logOut() async {
    prefs.accessToken = null;
    prefs.refreshToken = null;
    prefs.idToken = null;
    try {
      await _googleSignIn.disconnect();
    } on PlatformException {
      return;
    }
  }

  Future<bool> requestScopes(List<String> scopes) async {
    if (await _googleSignIn.isSignedIn()) {
      try {
        if (await _googleSignIn.canAccessScopes(scopes)) {
          return true;
        } else {
          return await _googleSignIn.requestScopes(scopes);
        }
      } on UnimplementedError {
        return await _googleSignIn.requestScopes(scopes);
      }
    } else {
      _scopes += scopes;
      return true;
    }
  }

  Future<Client?> getAuthenticatedClient({Client? client}) async {
    String? accessToken = await prefs.accessToken;
    String? refreshToken = await prefs.refreshToken;
    String? idToken = await prefs.idToken;
    AccessCredentials? credentials;
    if (accessToken != null && refreshToken != null && idToken != null) {
      credentials = AccessCredentials(
          AccessToken("Bearer", accessToken,
              DateTime.now().toUtc().add(const Duration(hours: 1))),
          refreshToken,
          _scopes,
          idToken: idToken);
    } else {
      if (await _googleSignIn.signInSilently() == null) {
        await _googleSignIn.signIn();
      }
      credentials = (await _googleSignIn.authenticatedClient())?.credentials;
    }
    if (credentials != null) {
      prefs.accessToken = credentials.accessToken.data;
      prefs.idToken = credentials.idToken;
      if (credentials.refreshToken == null) {
        credentials = AccessCredentials(
            credentials.accessToken, await prefs.refreshToken, _scopes,
            idToken: credentials.idToken);
      } else {
        prefs.refreshToken = credentials.refreshToken;
      }
      if (credentials.refreshToken == null) {
        return gapis.authenticatedClient(client ?? Client(), credentials);
      } else {
        return gapis.autoRefreshingClient(
            ClientId(clientId), credentials, client ?? Client());
      }
    }
    return null;
  }
}
