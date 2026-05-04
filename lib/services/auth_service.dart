import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔑 LOGIN WITH EMAIL & PASSWORD
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      return {
        'user': user,
        'role': doc.data()?['role'],
      };
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  /// 🆕 SIGNUP WITHOUT ROLE — role is assigned later from RoleSelectionScreen
  Future<Map<String, dynamic>> signUpWithoutRole(String email, String password) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = res.user;

      if (user != null) {
        // Create Firestore doc without role — role selection screen will save it
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return {'user': user, 'error': null};
    } on FirebaseAuthException catch (e) {
      print("Signup FirebaseAuthException: ${e.code}");
      if (e.code == 'email-already-in-use') {
        return {'user': null, 'error': 'email-already-in-use'};
      }
      return {'user': null, 'error': e.message ?? 'Signup failed'};
    } catch (e) {
      print("Signup Error: $e");
      return {'user': null, 'error': 'Signup failed. Please try again.'};
    }
  }

  /// 🆕 SIGNUP WITH ROLE (legacy — kept for compatibility)
  Future<Map<String, dynamic>> signUp(String email, String password, String role) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = res.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return {'user': user, 'error': null};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {'user': null, 'error': 'email-already-in-use'};
      }
      return {'user': null, 'error': e.message ?? 'Signup failed'};
    } catch (e) {
      return {'user': null, 'error': 'Signup failed. Please try again.'};
    }
  }

  /// 🔵 GOOGLE SIGN IN — returns isNewUser flag
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      final user = userCred.user;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // New Google user — create doc without role
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'user': user, 'role': null, 'isNewUser': true};
      }

      final role = doc.data()?['role'] as String?;

      // If doc exists but no role — treat as new user
      if (role == null || role.isEmpty) {
        return {'user': user, 'role': null, 'isNewUser': true};
      }

      return {'user': user, 'role': role, 'isNewUser': false};
    } catch (e) {
      print("Google Error: $e");
      return null;
    }
  }

  /// 📱 PHONE AUTH — Send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification (Android only)
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Phone Auth Error: ${e.code} - ${e.message}");
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Please enter a valid phone number.';
              break;
            case 'too-many-requests':
              message = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              message = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              message = e.message ?? 'Phone verification failed.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          print("✅ OTP sent to: $phoneNumber");
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout — user will enter OTP manually
        },
      );
    } catch (e) {
      print("Phone verify error: $e");
      onError('Something went wrong. Please try again.');
    }
  }

  /// 📱 PHONE AUTH — Verify OTP and sign in
  Future<Map<String, dynamic>?> signInWithOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      return await _signInWithPhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      print("OTP Verify Error: ${e.code}");
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          message = 'OTP expired. Please request a new one.';
          break;
        default:
          message = e.message ?? 'Verification failed.';
      }
      return {'error': message};
    } catch (e) {
      print("OTP Sign-in Error: $e");
      return {'error': 'Verification failed. Please try again.'};
    }
  }

  /// 📱 PHONE AUTH — Sign in with auto-verified credential
  Future<Map<String, dynamic>?> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    return await _signInWithPhoneCredential(credential);
  }

  /// Internal phone sign-in handler
  Future<Map<String, dynamic>?> _signInWithPhoneCredential(
      AuthCredential credential) async {
    try {
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return {'error': 'Sign-in failed.'};

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // New phone user — create doc without role
        await _firestore.collection('users').doc(user.uid).set({
          'phone': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'user': user, 'role': null, 'isNewUser': true};
      }

      final role = doc.data()?['role'] as String?;

      if (role == null || role.isEmpty) {
        return {'user': user, 'role': null, 'isNewUser': true};
      }

      return {'user': user, 'role': role, 'isNewUser': false};
    } catch (e) {
      print("Phone credential sign-in error: $e");
      return {'error': 'Sign-in failed. Please try again.'};
    }
  }

  /// 🔑 FORGOT PASSWORD — Send reset email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      print('🔑 Sending reset email to: $trimmedEmail');
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      print('✅ Reset email sent successfully to: $trimmedEmail');
      return {'success': true, 'error': null};
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: code=${e.code}, message=${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Something went wrong. Try again.';
      }
      return {'success': false, 'error': message};
    } catch (e) {
      print('❌ Reset Password Error: $e');
      return {'success': false, 'error': 'Something went wrong. Try again.'};
    }
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    await NotificationService().deleteToken();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// 🗑️ DELETE ACCOUNT — full data cleanup across all collections
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final uid = user.uid;
    final batch = _firestore.batch();

    // 1. Delete FCM token first
    await NotificationService().deleteToken();

    // 2. Delete user's favorites subcollection
    final favSnap = await _firestore
        .collection('users').doc(uid)
        .collection('favorites').get();
    for (final doc in favSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete user's bookings (as user)
    final userBookings = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: uid).get();
    for (final doc in userBookings.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete user's bookings (as provider)
    final providerBookings = await _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: uid).get();
    for (final doc in providerBookings.docs) {
      batch.delete(doc.reference);
    }

    // 5. Delete user's reviews
    final reviews = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: uid).get();
    for (final doc in reviews.docs) {
      batch.delete(doc.reference);
    }

    // 6. Delete user's services (provider)
    final services = await _firestore
        .collection('services')
        .where('providerId', isEqualTo: uid).get();
    for (final doc in services.docs) {
      batch.delete(doc.reference);
    }

    // 7. Delete user's messages (sent)
    final sentMsgs = await _firestore
        .collection('messages')
        .where('senderId', isEqualTo: uid).get();
    for (final doc in sentMsgs.docs) {
      batch.delete(doc.reference);
    }

    // 8. Delete user's messages (received)
    final rcvdMsgs = await _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: uid).get();
    for (final doc in rcvdMsgs.docs) {
      batch.delete(doc.reference);
    }

    // 9. Delete user's notifications
    final notifs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid).get();
    for (final doc in notifs.docs) {
      batch.delete(doc.reference);
    }

    // 10. Delete user document
    batch.delete(_firestore.collection('users').doc(uid));

    // Commit all deletions
    await batch.commit();

    // 11. Delete Firebase Auth account
    await user.delete();
  }

  User? get currentUser => _auth.currentUser;
}
