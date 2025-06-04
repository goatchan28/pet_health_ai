import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/main.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:provider/provider.dart';

void _showOfflineMsg(BuildContext ctx) =>
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(
      content: Text('Connect to the internet to make changes.'),
    ),
  );

class LoginPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginPage(),
      );
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUserWithEmailAndPassword() async {
    if (!context.read<ConnectivityService>().isOnline) {
      _showOfflineMsg(context);
      return;
    }
    final appState = context.read<MyAppState>();

    await appState.run(
      context, 
      () async {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(), 
        password: passwordController.text.trim()
      );
      final user = userCredential.user;

      if (user == null) {
        print("Error: User not found after login.");
        return;
      }
      
      String thisName = user.displayName ?? "Guest";
      appState.changeIndex(0);
      await appState.setName(thisName);
      if (user.photoURL != null) {
        await appState.setProfilePicture(user.photoURL!);
      }
      if (user.metadata.creationTime != null) {
        await appState.setMemberSince(user.metadata.creationTime!);
      }
      await appState.getPets(false);
      },
      successMsg: 'Signed in successfully!'
    );
  
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final ts = MediaQuery.textScalerOf(context);      // text scaler
    final w  = MediaQuery.sizeOf(context).width;      // screen width
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: ts.scale(42).clamp(26.0, 56.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                ),
                style: TextStyle(fontSize: ts.scale(15).clamp(12.0, 22.0)),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
                obscureText: true,
                style: TextStyle(fontSize: ts.scale(15).clamp(12.0, 22.0)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: w * 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!context.read<ConnectivityService>().isOnline) {
                      _showOfflineMsg(context);
                      return;
                    }
                    await loginUserWithEmailAndPassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      vertical: ts.scale(14).clamp(10.0, 20.0),
                    ),
                  ),
                  child: Text(
                    'SIGN IN',
                    style: TextStyle(
                      fontSize: ts.scale(16).clamp(12.0, 24.0),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  appState.changeEnterAccountIndex(0);
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: TextStyle(fontSize: ts.scale(14).clamp(11.0, 20.0), color: Colors.blueGrey),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(fontSize: ts.scale(14).clamp(11.0, 20.0), color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (!context.read<ConnectivityService>().isOnline) {
                    _showOfflineMsg(context);
                    return;
                  }

                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your email first.')),
                    );
                    return;
                  }

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('If an account exists, a reset link has been sent to your inbox.'),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    // Most errors here are quota/invalid-email; user-not-found may be masked.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Could not send email')),
                    );
                  }
                },
                child: const Text('Forgot password?'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
