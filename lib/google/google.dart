import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:lazyext/app/preferences.dart';
import 'package:lazyext/google/oauth.dart';

// See https://github.com/dart-lang/sdk/issues/30074, come on...
typedef ApiCreator<A> = A Function(Client);

class GoogleApi<A> {
  Set<String> get scopes => {};

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

  GoogleApi(this._google, this._apiCreator, {this.pageSize = 20});
  Future<R?>? getResponse<R>(Future<R?>? Function(A api) request) async {
    A? current = await api;
    if (current != null) {
      try {
        print("startin' request for response");
        return await request(current);
      } on AccessDeniedException catch (e) {
        print(e.message);
        if (e.message.contains("invalid_token")) {
          print("invalid_token");
          await _google.refreshCredentials();
          return await getResponse(request);
        } else if (e.message.contains("insufficient_scope")) {
          print("should call higher requestScopes");
          if (await _google.requestScopes(scopes)) {
            print("if higher requestScopes was true");
            return await getResponse(request);
          } else {
            print("shudda rethrow depth");
            rethrow;
          }
        } else {
          print("shudda rethrow surface");
          rethrow;
        }
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
    print("list: $request");
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

class GoogleAccount {
  late String name;
  late String photoUrl;
  late String email;
  final AccessCredentials credentials;

  GoogleAccount(this.name, this.photoUrl, this.email, this.credentials);
  GoogleAccount.fromRemote(Userinfo info, this.credentials) {
    String? displayName = info.name;
    String? photoUrl = info.picture;
    String? email = info.email;
    if (displayName != null && photoUrl != null && email != null) {
      name = displayName;
      this.photoUrl = photoUrl;
      this.email = email;
    }
  }
}

class Google extends ChangeNotifier {
  final String clientId;

  Future<GoogleAccount?> get account => _googleClient.account;

  final Set<String> scopes;

  Google({required this.clientId, this.scopes = const {}}) {
    _userCredentialsSource.scopes.addAll(scopes);
  }

  late final _userCredentialsSource = UserGoogleAccountSource(clientId, this);

  late final _googleClient = OfflineGoogleClient(ClientId(clientId),
      additionalSources: [_userCredentialsSource]);
  Future<Client?> get client => _googleClient.client;

  Future<void> logOut() async {
    await _googleClient.logOut();
    notifyListeners();
  }

  Future<void> refreshCredentials() async {
    await _googleClient.refreshAccount();
    notifyListeners();
  }

  Future<bool> requestScopes(Set<String> scopes) async {
    print("requestScopes higher");
    bool result = (await _googleClient.requestScope(scopes)) != null;
    notifyListeners();
    return result;
  }
}

class OfflineGoogleClient {
  final _credentialsStorage = StoredGoogleAccountStorage();
  late final _credentialSources = <GoogleAccountSource>[
    _credentialsStorage,
  ];

  final ClientId clientId;

  OfflineGoogleClient(this.clientId,
      {List<GoogleAccountSource> additionalSources = const []}) {
    _credentialSources.addAll(additionalSources);
  }

  Future<GoogleAccount?> get account async {
    int i = 0;
    for (GoogleAccountSource source in _credentialSources) {
      GoogleAccount? current = await source.account;
      print("account $i. try: ${current?.credentials.accessToken}");
      i++;
      if (current != null) {
        if (source != _credentialSources.first &&
            current.credentials.accessToken.data !=
                (await _credentialSources.first.account)
                    ?.credentials
                    .accessToken
                    .data) {
          _credentialsStorage.account = Future.value(current);
        }
        return current;
      }
    }
    return null;
  }

  Future<GoogleAccount?> refreshAccount() async {
    GoogleAccount? current;
    for (GoogleAccountSource source in _credentialSources) {
      GoogleAccount? old = await source.account;
      if (old != null) {
        try {
          current = await source.refreshAccount(old);
          if (current != null) {
            return current;
          }
        } on UnimplementedError {
          continue;
        }
      }
    }
    _credentialsStorage.account = Future.value(current);
    return current;
  }

  Future<void> logOut() async {
    for (GoogleAccountSource source in _credentialSources) {
      await source.logOut();
    }
  }

  Future<Client?> get client async {
    GoogleAccount? current = await account;
    if (current == null) {
      return null;
    } else {
      if (current.credentials.accessToken.hasExpired) {
        current = await refreshAccount();
      }
      if (current == null) {
        return null;
      } else {
        return current.credentials.toClient();
      }
    }
  }

  Future<GoogleAccount?> requestScope(Set<String> scopes) async {
    print("requestScope googleClient");
    GoogleAccount? current;
    int i = 0;
    for (GoogleAccountSource source in _credentialSources) {
      try {
        print("request $i.: start");
        current = await source.requestScope(scopes);
        print("request $i.: ${current?.credentials.accessToken}");
      } on UnimplementedError {
        print("request $i.: unimplemented");
        continue;
      } finally {
        i++;
      }
    }
    _credentialsStorage.account = Future.value(current);
    return current;
  }
}

class StoredGoogleAccountStorage implements GoogleAccountSource {
  final dynamic prefs = Preferences();

  set _credentials(Future<AccessCredentials?> wrapper) {
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

  void _invalidate() {
    prefs.name = null;
    prefs.photoUrl = null;
    prefs.email = null;
    prefs.accessToken = null;
    prefs.accessTokenType = null;
    prefs.expiryToken = null;
    prefs.idToken = null;
    prefs.refreshToken = null;
    prefs.expiryToken = null;
    prefs.scopesToken = null;
  }

  Future<AccessCredentials?> get _credentials async {
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
    print("stored: $accessToken");
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

  @override
  Future<GoogleAccount?> refreshAccount(GoogleAccount account) {
    throw UnimplementedError();
  }

  @override
  Future<GoogleAccount?> requestScope(Set<String> scopes) {
    throw UnimplementedError();
  }

  @override
  Future<void> logOut() async => _invalidate();

  @override
  Future<GoogleAccount?> get account async {
    AccessCredentials? credentials = await _credentials;
    if (credentials != null) {
      String? name = await prefs.name;
      String? photoUrl = await prefs.photoUrl;
      String? email = await prefs.email;
      if (name != null && photoUrl != null && email != null) {
        return GoogleAccount(name, photoUrl, email, credentials);
      }
    }
    return null;
  }

  set account(Future<GoogleAccount?> current) {
    current.then((GoogleAccount? current) {
      if (current != null) {
        print("storing: ${current.credentials.accessToken}");
        prefs.name = current.name;
        prefs.photoUrl = current.photoUrl;
        prefs.email = current.email;
        _credentials = Future.value(current.credentials);
      }
    });
  }
}

class UserGoogleAccountSource implements GoogleAccountSource {
  static const FlutterAppAuth _auth = FlutterAppAuth();
  static const googleIssuer = 'https://accounts.google.com';

  late final Google _google;
  late final OAuth _oauth = OAuth(_google);

  final String clientId;

  final Set<String> scopes = {
    "email",
    "profile",
  };

  UserGoogleAccountSource(this.clientId, this._google);

  static Future<AuthorizationTokenResponse?> _signIn(
      String clientId, Set<String> scopes) async {
    AuthorizationTokenRequest request = AuthorizationTokenRequest(
        clientId, "com.example.lazyext:/oauthredirect",
        scopes: scopes.toList(), issuer: googleIssuer);
    return (await _auth.authorizeAndExchangeCode(request));
  }

  Future<AccessCredentials?> get _credentials async =>
      _responseToCredentials(await _signIn(clientId, scopes));

  AccessCredentials? _responseToCredentials(dynamic response) {
    String? accessToken = response?.accessToken;
    if (response != null && accessToken != null) {
      return AccessCredentials(
          AccessToken(
              "Bearer",
              accessToken,
              response.accessTokenExpirationDateTime.toUtc() ??
                  DateTime.now().toUtc().add(const Duration(hours: 1))),
          response.refreshToken,
          scopes.toList(),
          idToken: response.idToken);
    } else {
      return null;
    }
  }

  @override
  Future<void> logOut() async {
    _auth.endSession(EndSessionRequest(
        idTokenHint: (await account)?.credentials.idToken,
        issuer: googleIssuer));
  }

  @override
  Future<GoogleAccount?> refreshAccount(GoogleAccount account,
      {Set<String>? scopes}) async {
    TokenRequest request = TokenRequest(clientId, "$clientId:/oauthredirect",
        refreshToken: account.credentials.refreshToken,
        scopes: scopes?.toList(),
        issuer: googleIssuer);
    TokenResponse? response = await _auth.token(request);
    if (response != null) {
      AccessCredentials? credentials = _responseToCredentials(response);
      if (credentials != null) {
        String? idToken = response.idToken;
        if (idToken != null) {
          Userinfo? info =
              await _oauth.getUserInfo(idToken, client: credentials.toClient());
          if (info != null) {
            print("refreshAccount: ${credentials.accessToken}");
            return GoogleAccount.fromRemote(info, credentials);
          }
        }
      }
    }
    return null;
  }

  @override
  Future<GoogleAccount?> requestScope(Set<String> newScopes) async {
    scopes.addAll(newScopes);
    return await account;
  }

  @override
  Future<GoogleAccount?> get account async {
    AccessCredentials? credentials = await _credentials;
    String? idToken = credentials?.idToken;
    if (credentials != null && idToken != null) {
      Userinfo? info =
          await _oauth.getUserInfo(idToken, client: credentials.toClient());
      if (info != null) {
        print("remote: ${credentials.accessToken}");
        return GoogleAccount.fromRemote(info, credentials);
      }
    }
    return null;
  }
}

abstract class GoogleAccountSource {
  Future<GoogleAccount?> get account;
  Future<GoogleAccount?> refreshAccount(GoogleAccount account);
  Future<GoogleAccount?> requestScope(Set<String> scopes);
  Future<void> logOut();
}

extension CredentialsToClient on AccessCredentials {
  Client toClient() =>
      gapis.authenticatedClient(Client(), this, closeUnderlyingClient: true);
}
