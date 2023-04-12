import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as model;
import 'package:appwrite_app/constants/constants.dart';
import 'package:flutter/widgets.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  Client client = Client();
  late final Account account;
  bool _loading = true;
  AuthStatus _status = AuthStatus.uninitialized;
  late model.Account? _currentUser;

  model.Account? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get loading => _loading;
  String? get username => _currentUser?.name;
  String? get email => _currentUser?.email;
  String? get userid => _currentUser?.$id;

  AuthAPI() {
    init();
    loadUser();
  }

  init() {
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();
    account = Account(client);
  }

  loadUser() async {
    try {
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
    } on AppwriteException catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<model.Account> createUser(
      {required String email, required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final user = await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: 'Simon G');
      return user;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<model.Session> createEmailSession(
      {required String email, required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final session =
          await account.createEmailSession(email: email, password: password);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      return session;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<model.Preferences> getUserPreferences() async {
    return await account.getPrefs();
  }

  updatePreferences({required String bio}) async {
    return account.updatePrefs(prefs: {'bio': bio});
  }

  signInWithProvider({required String provider}) async {
    // appwrite sign in with github
    try {
      final session = await account.createOAuth2Session(provider: provider);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      return session;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
