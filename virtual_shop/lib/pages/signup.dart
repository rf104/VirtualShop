import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:virtual_shop/auth/auth_service.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  bool isPasswordVisible = false;
  String errorMessage = '';

  void register() async {
    try {
      bool isValid = EmailValidator.validate(email);
      if (!isValid) {
        setState(() {
          errorMessage = 'Please enter a valid email address';
        });
        return;
      }
      // Sign up user
      UserCredential userCredential = await authServices.value.signUp(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Verify your email'),
            content: Text(
              'A verification link has been sent to your email. Please verify before logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'There is an error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 2, 2, 2),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 8, 8, 8),
              const Color.fromARGB(255, 32, 32, 32),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ready to dive in? Create your account now!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 244, 246, 245),
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 252, 251, 251),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          SizedBox(height: 40),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 62, 201, 136),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your name'
                                : null,
                            onSaved: (value) => name = value ?? '',
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your email'
                                : null,
                            onSaved: (value) => email = value ?? '',
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !isPasswordVisible,
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                            onSaved: (value) => password = value ?? '',
                          ),

                          Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                          SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();

                                register();

                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(content: Text('Signing up...')),
                                // );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                64,
                                202,
                                149,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: SignInButton(
                                Buttons.Google,
                                onPressed: () async {
                                  // Google Sign-In logic here
                                  bool isloggedIn = await login();
                                  if (isloggedIn) {
                                    Navigator.pop(
                                      context,
                                    ); // Close the sign-up page
                                  } else {
                                    setState(() {
                                      errorMessage = 'Google Sign-In failed';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              // Navigate to login page
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Already have an account? Log in',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 58, 183, 164),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> login() async {
  // final GoogleSignIn googleSignIn = GoogleSignIn();
  // final GoogleSignInAccount? user = await googleSignIn.signIn();

  // You can handle the signed-in user here
  final user = await GoogleSignIn().signIn();

  GoogleSignInAuthentication userAuth = await user!.authentication;

  var credential = GoogleAuthProvider.credential(
    accessToken: userAuth.accessToken,
    idToken: userAuth.idToken,
  );

  await FirebaseAuth.instance.signInWithCredential(credential);

  return FirebaseAuth.instance.currentUser != null;
}
