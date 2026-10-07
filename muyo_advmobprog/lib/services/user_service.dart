import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const _userKey = 'user';
  static const _tokenKey = 'accessToken';
  static const _loginTypeKey = 'loginType';

  firebase_auth.FirebaseAuth get firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  firebase_auth.User get _authenticatedUser =>
      currentUser ?? (throw StateError('No Firebase user is signed in.'));

  Future<User> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid username or password');
    }

    final loginData = jsonDecode(response.body) as Map<String, dynamic>;
    final loginUser = User.fromJson(loginData);

    try {
      final profileResponse = await http.get(
        Uri.parse('$host/users/${loginUser.id}'),
        headers: {
          if (loginUser.accessToken.isNotEmpty)
            'Authorization': 'Bearer ${loginUser.accessToken}',
        },
      );
      if (profileResponse.statusCode == 200) {
        final profileData =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        return User.fromJson({
          ...loginData,
          ...profileData,
          'accessToken': loginUser.accessToken,
          'loginType': LoginType.dummyJson.name,
        });
      }
    } catch (_) {
      // Login succeeded; retain the data returned by the authentication endpoint.
    }

    return loginUser;
  }

  Future<void> saveUserData(User user) async {
    if (user.loginType == LoginType.firebase) {
      final firebaseUser = _authenticatedUser;
      final profile = user.toJson()
        ..remove('accessToken')
        ..['uid'] = firebaseUser.uid;
      await _firestore.collection('users').doc(firebaseUser.uid).set(profile);
    }

    final prefs = await SharedPreferences.getInstance();
    final storedUser = user.loginType == LoginType.firebase
        ? user.copyWith(accessToken: '')
        : user;
    await prefs.setString(_userKey, jsonEncode(storedUser.toJson()));
    await prefs.setString(_loginTypeKey, user.loginType.name);
    if (user.loginType == LoginType.dummyJson) {
      await prefs.setString(_tokenKey, user.accessToken);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (await _getLoginType(prefs) == LoginType.firebase) {
      final firebaseUser = currentUser;
      if (firebaseUser == null) return null;

      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      final profile = snapshot.data() ?? <String, dynamic>{};
      final user = User.fromJson({
        ...profile,
        'username': profile['username'] ?? firebaseUser.displayName ?? '',
        'email': profile['email'] ?? firebaseUser.email ?? '',
        'loginType': LoginType.firebase.name,
        'accessToken': '',
      });
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return user;
    }

    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null || encodedUser.isEmpty) return null;

    try {
      return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
    } on FormatException {
      await logout();
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (await _getLoginType(prefs) == LoginType.firebase) {
      return currentUser != null;
    }
    return (prefs.getString(_tokenKey) ?? '').isNotEmpty &&
        (prefs.getString(_userKey) ?? '').isNotEmpty;
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return _getLoginType(prefs);
  }

  Future<LoginType> _getLoginType(SharedPreferences prefs) async {
    final value = prefs.getString(_loginTypeKey);
    return LoginType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LoginType.dummyJson,
    );
  }

  Future<String> getFirebaseIdToken({bool forceRefresh = false}) async {
    final token = await _authenticatedUser.getIdToken(forceRefresh);
    if (token == null) throw StateError('Firebase did not return an ID token.');
    return token;
  }

  Future<void> logout() => signOut();

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_loginTypeKey);
  }

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTypeKey, LoginType.firebase.name);
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTypeKey, LoginType.firebase.name);
    return credential;
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } finally {
      await _clearLocalSession();
    }
  }

  Future<User> updateUsername({required String username}) async {
    final user = await getUserData();
    if (user == null) throw StateError('No signed-in profile was found.');

    final updatedUser = user.copyWith(username: username);
    if (user.loginType == LoginType.firebase) {
      await _authenticatedUser.updateDisplayName(username);
      await _firestore.collection('users').doc(_authenticatedUser.uid).set({
        'username': username,
      }, SetOptions(merge: true));
    } else {
      final response = await http.put(
        Uri.parse('$host/users/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (user.accessToken.isNotEmpty)
            'Authorization': 'Bearer ${user.accessToken}',
        },
        body: jsonEncode({'username': username}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not update username.');
      }
    }

    await _saveLocalUser(updatedUser);
    return updatedUser;
  }

  Future<void> deleteAccount({String? email, String? password}) async {
    final profile = await getUserData();
    if (profile == null) throw StateError('No signed-in profile was found.');

    if (profile.loginType == LoginType.firebase) {
      if (email == null || password == null) {
        throw ArgumentError(
          'Email and password are required to delete a Firebase account.',
        );
      }
      final user = _authenticatedUser;
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } else {
      final response = await http.delete(
        Uri.parse('$host/users/${profile.id}'),
        headers: {
          if (profile.accessToken.isNotEmpty)
            'Authorization': 'Bearer ${profile.accessToken}',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not delete the DummyJSON account.');
      }
    }
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = _authenticatedUser;
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> resetPasswordForCurrentUser({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) {
    return resetPasswordFromCurrentPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      email: email,
    );
  }

  Future<void> _saveLocalUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
