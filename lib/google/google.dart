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
  Client? client;
  Future<A?> get api async {
    client ??= await _google.client;
    Client? current = client;
    if (current != null) {
      return _apiCreator(current);
    }
    return null;
  }

  GoogleApi(this._google, this._apiCreator) {
    _google.addScopes(scopes);
  }

  Future<R?> getResponse<R>(Future<R?>? Function() request) async {
    try {
      return request();
    } catch (_) {
      return null;
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
      result = await getResponse(
          () => request(token: lastToken, pageSize: pageSize));
      elems.addAll(result?.$1 ?? []);
    } while (result?.$2 != lastToken || result?.$1.length == pageSize);
    return elems;
  }
}

class Google extends ChangeNotifier {
  final String clientId;
  Google({required this.clientId});

  final credentialsStorage = AccessCredentialsStorage();
  final _userCredentialsSource = UserCredentialsSource();

  GoogleSignInAccount? get account => _userCredentialsSource.account;

  late final _googleClient = OfflineGoogleClient(clientId,
      additionalSources: [_userCredentialsSource]);
  Future<Client?> get client => _googleClient.client;

  Future<void> logOut() => _userCredentialsSource.logOut();

  void addScopes(List<String> scopes) {
    _userCredentialsSource.scopes += scopes;
  }
}

class OfflineGoogleClient {
  final _credentialsStorage = AccessCredentialsStorage();
  late final _credentialSources = <AccessCredentialsSource>[
    _credentialsStorage,
  ];

  final String clientId;

  OfflineGoogleClient(this.clientId,
      {List<AccessCredentialsSource> additionalSources = const []}) {
    _credentialSources.addAll(additionalSources);
  }

  Future<Client?> get client async {
    AccessCredentials? credentials;
    for (AccessCredentialsSource source in _credentialSources) {
      credentials = await source.credentials;
      if (credentials != null) break;
    }
    if (credentials == null) {
      return null;
    } else {
      if (credentials.accessToken.hasExpired) {
        credentials = await _refreshCredentials(credentials);
      }
      _credentialsStorage.credentials = Future.value(credentials);
      return _credentialsToClient(credentials);
    }
  }

  Client _credentialsToClient(AccessCredentials credentials) {
    return gapis.authenticatedClient(Client(), credentials);
  }

  Future<AccessCredentials> _refreshCredentials(
      AccessCredentials credentials) async {
    return gapis.refreshCredentials(
        ClientId(clientId), credentials, _credentialsToClient(credentials));
  }
}

class AccessCredentialsStorage implements AccessCredentialsSource {
  final dynamic prefs = Preferences();

  set credentials(Future<AccessCredentials?> wrapper) {
    wrapper.then((credentials) {
      if (credentials != null) {
        prefs.accessToken = credentials.accessToken.data;
        prefs.accessType = credentials.accessToken.type;
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
    prefs.accessType = null;
    prefs.expiryToken = null;
    prefs.idToken = null;
    prefs.refreshToken = null;
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

  UserCredentialsSource() {
    _googleSignIn.onCurrentUserChanged.listen((event) =>
        _googleLock.protect(() => _googleSignIn.requestScopes(scopes)));
  }

  @override
  Future<AccessCredentials?> get credentials async {
    return _googleLock.protect<AccessCredentials?>(() async {
      if (await _googleSignIn.signInSilently() == null) {
        await _googleSignIn.signIn();
      }
      return (await _googleSignIn.authenticatedClient())?.credentials;
    });
  }

  Future<void> logOut() async {
    await _googleLock.protect(() => _googleSignIn.disconnect());
  }

  List<String> scopes = [];
}

abstract class AccessCredentialsSource {
  Future<AccessCredentials?> get credentials;
}
