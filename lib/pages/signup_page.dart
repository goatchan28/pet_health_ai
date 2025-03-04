import 'package:flutter/material.dart';
import 'package:pet_health_ai/pages/login_page.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
 const SignupPage({super.key});


 @override
 State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
 final emailController = TextEditingController();
 final passwordController = TextEditingController();
 final formKey = GlobalKey<FormState>();

 @override
 void dispose() {
   emailController.dispose();
   passwordController.dispose();
   super.dispose();
 }

 @override
 Widget build(BuildContext context) {
   var appstate = context.read<MyAppState>();
   return Scaffold(
     body: Padding(
       padding: const EdgeInsets.all(15.0),
       child: Form(
         key: formKey,
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text(
               'Sign Up.',
               style: TextStyle(
                 fontSize: 50,
                 fontWeight: FontWeight.bold,
               ),
             ),
             const SizedBox(height: 10),
             const SizedBox(height: 20),
             TextFormField(
               controller: emailController,
               decoration: const InputDecoration(
                 hintText: 'Email',
               ),
             ),
             const SizedBox(height: 15),
             TextFormField(
               controller: passwordController,
               decoration: const InputDecoration(
                 hintText: 'Password',
               ),
               obscureText: true,
             ),
             const SizedBox(height: 20),
             ElevatedButton(
               onPressed: () {},
               style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(200, 255, 0, 0)),
               child: const Text(
                 'SIGN UP',
                 style: TextStyle(
                   fontSize: 16,
                   color: Colors.white,
                 ),
               ),
             ),
             const SizedBox(height: 20),
             GestureDetector(
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
               },
               child: RichText(
                 text: TextSpan(
                   text: 'Already have an account? ',
                   style: Theme.of(context).textTheme.titleMedium,
                   children: [
                     TextSpan(
                       text: 'Sign In',
                       style:
                           Theme.of(context).textTheme.titleMedium?.copyWith(
                                 fontWeight: FontWeight.bold,
                               ),
                     ),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 100,),
             ElevatedButton(
               onPressed: (){appstate.logIn();},
               child: const Text('Skip Sign Up', style: TextStyle(fontSize: 16),)
             )
           ],
         ),
       ),
     ),
   );
 }
}
