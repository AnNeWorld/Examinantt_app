import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthInitialized = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory fallback database of registered users indexed by clean email
  final Map<String, UserModel> _userDatabase = {};

  String _selectedExam = 'JEE Main 2027';
  String? _profileImage;

  UserModel? get user => _user;
  String? get profileImage => _user?.profileImage ?? _profileImage;
  String get selectedExam => (_user != null && _user!.targetExam.isNotEmpty && _user!.targetExam != 'General')
      ? _user!.targetExam
      : _selectedExam;
  bool get isLoading => _isLoading;
  bool get isAuthInitialized => _isAuthInitialized;
  bool get isLoggedIn => _user != null;

  UserProvider() {
    _initFirebaseUser();
  }

  void _initFirebaseUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('user_uid');
      final savedEmail = prefs.getString('user_email');
      final savedName = prefs.getString('user_name');
      final savedPhone = prefs.getString('user_phone');
      final isExplicitLoggedIn = prefs.getBool('is_logged_in') ?? false;

      final savedTargetExam = prefs.getString('selected_target_exam');
      if (savedTargetExam != null && savedTargetExam.isNotEmpty) {
        _selectedExam = savedTargetExam;
      }

      final savedProfileImage = prefs.getString('user_profile_image');
      if (savedProfileImage != null && savedProfileImage.isNotEmpty) {
        _profileImage = savedProfileImage;
      }

      if (isExplicitLoggedIn && savedUid != null && savedEmail != null && savedEmail.isNotEmpty ) {
        FirestoreService.activeUid = savedUid;
        _user = UserModel(
          uid: savedUid,
          name: savedName ?? _nameFromEmail(savedEmail),
          email: savedEmail,
          phone: savedPhone ?? '',
          targetExam: _selectedExam,
          testsAttempted: 0,
          averageScore: 0.0,
          accuracy: 0.0,
          totalStudyTimeMinutes: 0,
          currentStreak: 1,
          profileImage: savedProfileImage,
        );
      } else {
        _user = null;
        FirestoreService.activeUid = null;
        await _clearSessionFromPrefs();
        try {
          await _auth.signOut();
        } catch (_) {}
      }
      _isAuthInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("SharedPreferences load error: $e");
      _user = null;
      _isAuthInitialized = true;
      notifyListeners();
    }

    _auth.authStateChanges().listen((fbUser) async {
      final prefs = await SharedPreferences.getInstance();
      final isExplicitLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isExplicitLoggedIn) {
        _user = null;
        _isAuthInitialized = true;
        notifyListeners();
        return;
      }

      if (fbUser != null ) {
        try {
          final doc = await _db.collection('users').doc(fbUser.uid).get();
          if (doc.exists && doc.data() != null) {
            _user = UserModel.fromMap(doc.data()!, doc.id);
            if (_user!.targetExam.isNotEmpty && _user!.targetExam != 'General') {
              _selectedExam = _user!.targetExam;
            }
          } else if (_user == null) {
            final email = fbUser.email ?? '';
            _user = UserModel(
              uid: fbUser.uid,
              name: (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
                  ? fbUser.displayName!
                  : _nameFromEmail(email),
              email: email,
              phone: fbUser.phoneNumber ?? '',
              targetExam: _selectedExam,
              testsAttempted: 0,
              averageScore: 0.0,
              accuracy: 0.0,
              totalStudyTimeMinutes: 0,
              currentStreak: 1,
            );
          }
          if (_user != null) {
            await _saveSessionToPrefs(_user!);
          }
        } catch (e) {
          debugPrint("Error fetching firebase user: $e");
        }
      }
      _isAuthInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _saveSessionToPrefs(UserModel user) async {
    try {
      FirestoreService.activeUid = user.uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_phone', user.phone);
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        await prefs.setString('user_profile_image', user.profileImage!);
      }
      await prefs.setString('selected_target_exam', user.targetExam.isNotEmpty && user.targetExam != 'General' ? user.targetExam : _selectedExam);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<void> _clearSessionFromPrefs() async {
    try {
      FirestoreService.activeUid = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_uid');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_profile_image');
      _profileImage = null;
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }
  }

  // Derive human readable name from email address (e.g. rahul.sharma@gmail.com -> Rahul Sharma)
  String _nameFromEmail(String email) {
    if (email.isEmpty) return 'Student User';
    final parts = email.split('@');
    final username = parts[0];
    final words = username
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    final formattedName = words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    return formattedName.isNotEmpty ? formattedName : 'Student User';
  }

  

  Future<String?> login(String identifier, String password, {String? name, String? phone}) async {
    final cleanIdentifier = identifier.trim();
    final cleanPassword = password.trim();

    if (cleanIdentifier.isEmpty || cleanPassword.isEmpty) {
      return 'Please enter both mobile/email and password';
    }

    _isLoading = true;
    notifyListeners();

    final digits = cleanIdentifier.replaceAll(RegExp(r'[^0-9]'), '');
    final isPhone = (digits.length >= 10 && digits.length <= 13 && !cleanIdentifier.contains('@'));
    final phone10 = isPhone ? (digits.length >= 10 ? digits.substring(digits.length - 10) : digits) : '';

    String targetEmail = cleanIdentifier.toLowerCase();
    String? resolvedPhone = isPhone ? phone10 : null;
    String? resolvedName;

    if (isPhone) {
      try {
        final querySnap = await _db
            .collection('users')
            .where('phone', isEqualTo: phone10)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final data = querySnap.docs.first.data();
          targetEmail = (data['email'] ?? '').toString().toLowerCase();
          resolvedName = data['name'];
          resolvedPhone = (data['phone'] ?? '').toString().isNotEmpty ? data['phone'] : phone10;
        } else {
          final querySnap2 = await _db
              .collection('users')
              .where('phone', isEqualTo: '+91 $phone10')
              .limit(1)
              .get();
          if (querySnap2.docs.isNotEmpty) {
            final data = querySnap2.docs.first.data();
            targetEmail = (data['email'] ?? '').toString().toLowerCase();
            resolvedName = data['name'];
            resolvedPhone = data['phone'];
          } else {
            targetEmail = '$phone10@examinantt.com';
          }
        }
      } catch (e) {
        debugPrint("Error looking up user by phone: $e");
        targetEmail = '$phone10@examinantt.com';
      }
    }

    try {
      final authRes = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: cleanPassword,
      );

      final fbUser = authRes.user;
      if (fbUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'Login failed. Please try again.';
      }

      final uid = fbUser.uid;
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _user = UserModel.fromMap(data, doc.id);
          if (_user!.phone.isEmpty && resolvedPhone != null && resolvedPhone.isNotEmpty) {
            _user = UserModel(
              uid: _user!.uid,
              name: _user!.name,
              email: _user!.email,
              phone: resolvedPhone,
              targetExam: _user!.targetExam,
              testsAttempted: _user!.testsAttempted,
              averageScore: _user!.averageScore,
              accuracy: _user!.accuracy,
              totalStudyTimeMinutes: _user!.totalStudyTimeMinutes,
              currentStreak: _user!.currentStreak,
            );
            await _db.collection('users').doc(uid).set({'phone': resolvedPhone}, SetOptions(merge: true));
          }
        } else {
          final derivedName = resolvedName ?? (name != null && name.trim().isNotEmpty
              ? name.trim()
              : (fbUser.displayName ?? _nameFromEmail(targetEmail)));
          _user = UserModel(
            uid: uid,
            name: derivedName,
            email: targetEmail,
            phone: resolvedPhone ?? (phone?.trim() ?? (fbUser.phoneNumber ?? '')),
            targetExam: 'General',
            testsAttempted: 0,
            averageScore: 0.0,
            accuracy: 0.0,
            totalStudyTimeMinutes: 0,
            currentStreak: 1,
          );
          await _db.collection('users').doc(uid).set(_user!.toMap(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Firestore fetch error on login: $e");
        _user = UserModel(
          uid: uid,
          name: resolvedName ?? _nameFromEmail(targetEmail),
          email: targetEmail,
          phone: resolvedPhone ?? '',
          targetExam: 'General',
          testsAttempted: 0,
          averageScore: 0.0,
          accuracy: 0.0,
          totalStudyTimeMinutes: 0,
          currentStreak: 1,
        );
      }

      _userDatabase[targetEmail] = _user!;
      await _saveSessionToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Firebase login error: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        return 'No account found with this ${isPhone ? "mobile number" : "email"}. Please sign up first.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid format. Please enter a valid mobile number or email.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      }
      return e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Login generic error: $e");
      return 'Login failed. Please check your network connection.';
    }
  }

  Future<String?> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return "All required fields must be filled!";
    }

    String uid = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    try {
      final authRes = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      if (authRes.user != null) {
        uid = authRes.user!.uid;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _isLoading = false;
        notifyListeners();
        return 'An account already exists with this email address.';
      } else if (e.code == 'weak-password') {
        _isLoading = false;
        notifyListeners();
        return 'The password provided is too weak (min 6 characters).';
      } else if (e.code == 'invalid-email') {
        _isLoading = false;
        notifyListeners();
        return 'Please provide a valid email address.';
      }
    } catch (e) {
      debugPrint("Firebase signup error: $e");
    }

    _user = UserModel(
      uid: uid,
      name: name.trim().isNotEmpty ? name.trim() : _nameFromEmail(email.trim()),
      email: cleanEmail,
      phone: phone.trim(),
      targetExam: 'Banking',
      testsAttempted: 0,
      averageScore: 0.0,
      accuracy: 0.0,
      totalStudyTimeMinutes: 0,
      currentStreak: 1,
    );

    try {
      await _db.collection('users').doc(uid).set(_user!.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore signup error: $e");
    }

    _userDatabase[cleanEmail] = _user!;
    await _saveSessionToPrefs(_user!);
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearSessionFromPrefs();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email, String phone) async {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        name: name,
        email: email,
        phone: phone,
        targetExam: _user!.targetExam,
        testsAttempted: _user!.testsAttempted,
        averageScore: _user!.averageScore,
        accuracy: _user!.accuracy,
        totalStudyTimeMinutes: _user!.totalStudyTimeMinutes,
        currentStreak: _user!.currentStreak,
        profileImage: _user!.profileImage ?? _profileImage,
      );
      _userDatabase[email.trim().toLowerCase()] = _user!;
      notifyListeners();

      try {
        await _db.collection('users').doc(_user!.uid).set(_user!.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating profile in Firestore: $e");
      }
    }
  }

  Future<void> updateProfileImage(String? imageBase64OrPath) async {
    _profileImage = imageBase64OrPath;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (imageBase64OrPath != null && imageBase64OrPath.isNotEmpty) {
        await prefs.setString('user_profile_image', imageBase64OrPath);
      } else {
        await prefs.remove('user_profile_image');
      }
    } catch (e) {
      debugPrint("Error saving profile image to prefs: $e");
    }

    if (_user != null) {
      _user = _user!.copyWith(
        profileImage: imageBase64OrPath,
        clearProfileImage: imageBase64OrPath == null,
      );
      if (_user!.email.isNotEmpty) {
        _userDatabase[_user!.email.trim().toLowerCase()] = _user!;
      }
      try {
        await _db.collection('users').doc(_user!.uid).set({
          'profileImage': imageBase64OrPath,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating profile image in Firestore: $e");
      }
    }
    notifyListeners();
  }

  Future<void> updateTargetExam(String exam) async {
    _selectedExam = exam;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_target_exam', exam);
    } catch (_) {}

    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        name: _user!.name,
        email: _user!.email,
        phone: _user!.phone,
        targetExam: exam,
        testsAttempted: _user!.testsAttempted,
        averageScore: _user!.averageScore,
        accuracy: _user!.accuracy,
        totalStudyTimeMinutes: _user!.totalStudyTimeMinutes,
        currentStreak: _user!.currentStreak,
      );
      _userDatabase[_user!.email.trim().toLowerCase()] = _user!;

      try {
        await _db.collection('users').doc(_user!.uid).set({'targetExam': exam}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating target exam in Firestore: $e");
      }
    }
    notifyListeners();
  }
}

