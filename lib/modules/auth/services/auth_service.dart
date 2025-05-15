// lib/modules/auth/services/auth_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:famradar/interfaces/storage_service_interface.dart';
import 'package:famradar/models/user_model.dart';
import 'package:famradar/providers/app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../interfaces/auth_service_interface.dart';

class AuthService implements AuthServiceInterface {
  final AppProvider _appProvider;
  final StorageServiceInterface _storageService;
  final PermissionServiceInterface _permissionService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthService({
    required AppProvider appProvider,
    required StorageServiceInterface storageService,
    required PermissionServiceInterface permissionService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _appProvider = appProvider,
       _storageService = storageService,
       _permissionService = permissionService,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _getUserModel(credential.user!.uid);
    } catch (e) {
      _appProvider.showError('Error signing in: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> signInWithPhone(String phone, String password) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();
      if (snapshot.docs.isNotEmpty) {
        final email = snapshot.docs.first.data()['email'] as String;
        return await signInWithEmail(email, password);
      }
      _appProvider.showError('Phone number not found');
      return null;
    } catch (e) {
      _appProvider.showError('Error signing in with phone: $e');
      return null;
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? photoPath,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = credential.user!.uid;
      final randomId = const Uuid().v4();

      String? photoUrl;
      if (photoPath != null) {
        final ref = _storage.ref().child('user_photos/$userId.jpg');
        await ref.putFile(File(photoPath));
        photoUrl = await ref.getDownloadURL();
      }

      final userModel = UserModel(
        id: randomId,
        name: name,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );

      await _firestore.collection('users').doc(userId).set(userModel.toMap());
      await _firestore.collection('users').doc(userId).set({
        'isFirstSignup': true,
      }, SetOptions(merge: true));
      await _storageService.saveUserData(userModel.toMap());
      _appProvider.setCurrentUser(userModel);

      final permissionsGranted =
          await _permissionService.requestInitialPermissions();
      if (permissionsGranted) {
        await _firestore.collection('users').doc(userId).set({
          'isFirstSignup': false,
        }, SetOptions(merge: true));
      } else {
        _appProvider.showError(
          'Permissions are required to use FamRadar features.',
        );
      }

      return userModel;
    } catch (e) {
      _appProvider.showError('Error signing up: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _appProvider.clearUser();
    } catch (e) {
      _appProvider.showError('Error signing out: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _getUserModel(user.uid);
      }
      return null;
    } catch (e) {
      _appProvider.showError('Error fetching current user: $e');
      return null;
    }
  }

  Future<UserModel?> _getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final userModel = UserModel.fromMap(doc.data()!);
      _appProvider.setCurrentUser(userModel);
      await _storageService.saveUserData(userModel.toMap());
      return userModel;
    }
    return null;
  }
}
