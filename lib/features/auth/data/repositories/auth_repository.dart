import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/mock_config.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirestoreService _firestoreService;

  AuthRepository(this._firestoreService);

  FirebaseAuth get _auth {
    if (MockConfig.useMockMode) {
      throw UnsupportedError('Firebase Auth is not available in mock mode');
    }
    return FirebaseAuth.instance;
  }

  GoogleSignIn get _googleSignIn => GoogleSignIn();

  // ─── Mock in-memory state ─────────────────────────────────────────────────
  final List<UserModel> _mockUsers = [
    UserModel(
      uid: 'mock-user-123',
      email: 'creator@reeliq.ai',
      displayName: 'Creator Premium',
      creatorLevel: 5,
      creatorXp: 340,
      creatorStreak: 12,
      analysesPerformed: 2,
    ),
  ];
  UserModel? _currentMockUser;

  // ─── Auth State Stream ────────────────────────────────────────────────────

  /// Emits the current [UserModel] whenever auth state changes (live mode only).
  /// In mock mode, returns an empty stream.
  Stream<UserModel?> get authStateChanges {
    if (MockConfig.useMockMode) return const Stream.empty();
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      // Try to load extended profile from Firestore
      final stored = await _firestoreService.getUser(firebaseUser.uid);
      return stored ??
          UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'ReelIQ Creator',
            photoUrl: firebaseUser.photoURL,
          );
    });
  }

  // ─── Current User ─────────────────────────────────────────────────────────

  UserModel? get currentUser {
    if (MockConfig.useMockMode) return _currentMockUser;
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'ReelIQ Creator',
        photoUrl: firebaseUser.photoURL,
      );
    }
    return null;
  }

  bool get isLoggedIn => currentUser != null;

  // ─── Email / Password Auth ────────────────────────────────────────────────

  Future<UserModel> loginWithEmail(String email, String password) async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final index = _mockUsers.indexWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase());
      if (index != -1) {
        _currentMockUser = _mockUsers[index];
        return _currentMockUser!;
      }
      final newUser = UserModel(
        uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@')[0],
      );
      _mockUsers.add(newUser);
      _currentMockUser = newUser;
      return newUser;
    } else {
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = credentials.user!;
      // Load extended profile from Firestore
      final stored = await _firestoreService.getUser(u.uid);
      return stored ??
          UserModel(
            uid: u.uid,
            email: u.email ?? '',
            displayName: u.displayName ?? email.split('@')[0],
            photoUrl: u.photoURL,
          );
    }
  }

  Future<UserModel> signUpWithEmail(
      String email, String password, String displayName) async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final exists = _mockUsers
          .any((u) => u.email.toLowerCase() == email.toLowerCase());
      if (exists) {
        throw Exception('An account with this email already exists.');
      }
      final newUser = UserModel(
        uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
      );
      _mockUsers.add(newUser);
      _currentMockUser = newUser;
      return newUser;
    } else {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = credentials.user!;
      await u.updateDisplayName(displayName);
      final newUser = UserModel(
        uid: u.uid,
        email: u.email ?? '',
        displayName: displayName,
        photoUrl: u.photoURL,
        createdAt: DateTime.now(),
      );
      // Persist new user profile to Firestore
      await _firestoreService.saveUser(newUser);
      return newUser;
    }
  }

  // ─── Google Sign In ───────────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final googleMockUser = UserModel(
        uid: 'google-mock-user-456',
        email: 'google.creator@reeliq.ai',
        displayName: 'Google Partner Creator',
        photoUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        creatorLevel: 5,
        creatorXp: 340,
        creatorStreak: 12,
      );
      if (!_mockUsers.any((u) => u.uid == googleMockUser.uid)) {
        _mockUsers.add(googleMockUser);
      }
      _currentMockUser = googleMockUser;
      return googleMockUser;
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In canceled by user.');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final u = userCredential.user!;
      // Try to load existing profile; create if first time
      final stored = await _firestoreService.getUser(u.uid);
      if (stored != null) return stored;
      final newUser = UserModel(
        uid: u.uid,
        email: u.email ?? '',
        displayName: u.displayName ?? 'Google User',
        photoUrl: u.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestoreService.saveUser(newUser);
      return newUser;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      _currentMockUser = null;
    } else {
      await _auth.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }
}
