import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:lazyext/app/preferences.dart';
import 'package:mutex/mutex.dart';

// See https://github.com/dart-lang/sdk/issues/30074, come on...
typedef ApiCreator<A> = A Function(Client);

class GoogleApi<A> {
  List<String> get scopes {
    return [];
  }

  final Google _google;
  final ApiCreator<A> _apiCreator;
  Future<A?> get api async {
    Client? client = await _google.client;
    if (client != null) {
      return _apiCreator(client);
    }
    return null;
  }

  int pageSize;

  GoogleApi(this._google, this._apiCreator, {this.pageSize = 20}) {
    _google.addScopes(scopes);
  }

  Future<R?>? getResponse<R>(Future<R?>? Function(A api) request) async {
    try {
      A? current = await api;
      if (current != null) {
        return await request(current);
      }
    } on AccessDeniedException catch (e) {
      if (e.message.contains("invalid_token")) {
        await _google.refreshCredentials();
        return await getResponse(request);
      } else if (e.message.contains("insufficient_scope")) {
        if (await _google.requestScopes()) {
          return await getResponse(request);
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
    return null;
  }

  Future<R?> list<R>(dynamic Function(A api) request,
      {List<dynamic>? positional,
      Map<Symbol, dynamic>? additional,
      String? pageToken}) async {
    Map<Symbol, dynamic> named = {};
    named[const Symbol("pageToken")] = pageToken;
    named[const Symbol("pageSize")] = pageToken;
    if (additional != null) named.addAll(additional);
    return getResponse(
        (A api) => Function.apply(request(api), positional, named));
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
  final String clientId;
  final String clientSecret;

  Google({required this.clientId, required this.clientSecret});

  final _userCredentialsSource = UserCredentialsSource();

  GoogleSignInAccount? get account => _userCredentialsSource.account;

  late final _googleClient = OfflineGoogleClient(
      ClientId(clientId, clientSecret),
      additionalSources: [_userCredentialsSource]);
  Future<Client?> get client => _googleClient.client;

  Future<void> logOut() async {
    _googleClient._credentialsStorage.invalidate();
    try {
      await _userCredentialsSource.logOut();
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshCredentials() async {
    AccessCredentials? credentials = await _googleClient.credentials;
    if (credentials != null) {
      credentials = await _googleClient.refreshCredentials(credentials);
      if (credentials == null) {
        await logOut();
      }
    }
  }

  Future<bool> requestScopes() async {
    AccessCredentials? credentials =
        await _userCredentialsSource.requestScopes();
    if (credentials != null) {
      _googleClient._credentialsStorage.invalidate();
      _googleClient._credentialsStorage.credentials = Future.value(credentials);
      return true;
    }
    return false;
  }

  void addScopes(List<String> scopes) {
    _userCredentialsSource.scopes += scopes;
  }
}

class OfflineGoogleClient {
  final _credentialsStorage = AccessCredentialsStorage();
  late final _credentialSources = <AccessCredentialsSource>[
    _credentialsStorage,
  ];

  final ClientId clientId;

  OfflineGoogleClient(this.clientId,
      {List<AccessCredentialsSource> additionalSources = const []}) {
    _credentialSources.addAll(additionalSources);
  }

  Future<AccessCredentials?> get credentials async {
    for (AccessCredentialsSource source in _credentialSources) {
      AccessCredentials? current = await source.credentials;
      if (current != null) {
        return current;
      }
    }
    return null;
  }

  Future<Client?> get client async {
    AccessCredentials? current = await credentials;
    if (current == null) {
      return null;
    } else {
      if (current.accessToken.hasExpired) {
        current = await refreshCredentials(current);
        if (current == null) {
          _credentialsStorage.invalidate();
          return null;
        }
        _credentialsStorage.credentials = Future.value(current);
      }
      return _credentialsToClient(current);
    }
  }

  Client _credentialsToClient(AccessCredentials credentials) {
    return gapis.authenticatedClient(Client(), credentials);
  }

  Future<AccessCredentials?> refreshCredentials(
      AccessCredentials credentials) async {
    if (credentials.refreshToken == null) {
      return null;
    } else {
      return gapis.refreshCredentials(
          clientId, credentials, _credentialsToClient(credentials));
    }
  }
}

class AccessCredentialsStorage implements AccessCredentialsSource {
  final dynamic prefs = Preferences();

  set credentials(Future<AccessCredentials?> wrapper) {
    wrapper.then((credentials) {
      if (credentials != null) {
        prefs.accessToken = credentials.accessToken.data;
        prefs.accessTokenType = credentials.accessToken.type;
        prefs.expiryToken = credentials.accessToken.expiry.toIso8601String();
        prefs.idToken = credentials.idToken;
        prefs.scopesToken = credentials.scopes.join(",");
        if (credentials.refreshToken != null) {
          prefs.refreshToken = credentials.refreshToken;
        }
      }
    });
  }

  void invalidate() {
    prefs.accessToken = null;
    prefs.accessTokenType = null;
    prefs.expiryToken = null;
    prefs.idToken = null;
    prefs.refreshToken = null;
    prefs.expiryToken = null;
    prefs.scopesToken = null;
  }

  @override
  Future<AccessCredentials?> get credentials async {
    String? accessToken = await prefs.accessToken;
    accessToken = accessToken?.isEmpty ?? true ? null : accessToken;
    String? accessTokenType = await prefs.accessTokenType;
    accessTokenType = accessTokenType?.isEmpty ?? true ? null : accessTokenType;
    String? refreshToken = await prefs.refreshToken;
    refreshToken = refreshToken?.isEmpty ?? true ? null : refreshToken;
    String? idToken = await prefs.idToken;
    idToken = idToken?.isEmpty ?? true ? null : idToken;
    String? expiryToken = await prefs.expiryToken;
    DateTime? expiry;
    if (expiryToken != null) {
      expiry = DateTime.tryParse(expiryToken);
    }
    expiry ??= DateTime.now().toUtc().add(const Duration(hours: 1));
    String? scopesToken = await prefs.scopesToken;
    List<String> scopes = [];
    if (scopesToken != null) {
      scopes = scopesToken.split(",");
    }
    if (accessToken != null && accessTokenType != null) {
      return AccessCredentials(
          AccessToken(accessTokenType, accessToken, expiry),
          refreshToken,
          scopes,
          idToken: idToken);
    } else {
      return null;
    }
  }
}

class UserCredentialsSource implements AccessCredentialsSource {
  final Mutex _googleLock = Mutex();
  late final GoogleSignIn _googleSignIn =
      GoogleSignIn(forceCodeForRefreshToken: true);
  GoogleSignInAccount? get account => _googleSignIn.currentUser;

  Future<void> _signIn() async {
    if (!await _googleSignIn.isSignedIn()) {
      print("in2");
      if (await _googleSignIn.signInSilently() == null) {
        await _googleSignIn.signIn();
      }
    }
  }

  @override
  Future<AccessCredentials?> get credentials async {
    return _googleLock.protect<AccessCredentials?>(() async {
      await _signIn();
      print(
          "asd: ${(await _googleSignIn.authenticatedClient())?.credentials.accessToken}");
      return (await _googleSignIn.authenticatedClient())?.credentials;
    });
  }

  Future<void> logOut() async {
    await _googleLock.protect(() => _googleSignIn.disconnect());
  }

  Future<AccessCredentials?> requestScopes() async {
    return await _googleLock.protect(() async {
      if (await _googleSignIn.isSignedIn()) {
        if (await _googleSignIn.requestScopes(scopes)) {
          return (await _googleSignIn.authenticatedClient())?.credentials;
        }
      }
      return null;
    });
  }

  List<String> scopes = [];
}

abstract class AccessCredentialsSource {
  Future<AccessCredentials?> get credentials;
}
