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


class SignUpPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const SignUpPage(),
      );
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (!context.read<ConnectivityService>().isOnline) {
      _showOfflineMsg(context);
      return;
    }
    final appState = context.read<MyAppState>();
    await appState.run(
      context, 
      () async {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(), 
          password: passwordController.text.trim()
        );
        appState.setNeedsToEnterName(true);  
      },
      successMsg: 'Account created -- please enter username'
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final ts      = MediaQuery.textScalerOf(context);   // new
    final double w = MediaQuery.sizeOf(context).width;  // we’ll re-use

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign Up',
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
                style: TextStyle(fontSize: ts.scale(15).clamp(12.0, 22.0)),
                obscureText: true,
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
                    await createUserWithEmailAndPassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    padding: EdgeInsets.symmetric(
                      vertical: ts.scale(14).clamp(10.0, 20.0),
                    ),
                  ),
                  child: Text(
                    'SIGN UP',
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
                  appState.changeEnterAccountIndex(1);
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(fontSize: ts.scale(14).clamp(11.0, 20.0), color: Colors.blueGrey),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(fontSize: ts.scale(14).clamp(11.0, 20.0), color: Colors.black)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}