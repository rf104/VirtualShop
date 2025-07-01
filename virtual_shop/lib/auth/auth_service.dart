import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authServices = ValueNotifier<AuthService>(AuthService());

class AuthService{

  final FirebaseAuth auth = FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async{
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }


}