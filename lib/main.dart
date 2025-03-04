import 'package:flutter/material.dart';
import 'package:pet_health_ai/pages/signup_page.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/pages/home_page.dart';
import 'package:pet_health_ai/pages/progress_page.dart';
import 'package:pet_health_ai/pages/camera_page.dart';
import 'package:pet_health_ai/pages/food_page.dart';
import 'package:pet_health_ai/pages/profile_page.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
          title: 'Pet Health AI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(152, 171, 218, 1)),
            scaffoldBackgroundColor: Color.fromRGBO(215,215,215,1),
          ),
        home: Consumer<MyAppState>(
          builder: (context, appState, _) {
            print("isLoggedIn: ${appState.isLoggedIn}");  // Debug print
            return appState.isLoggedIn ? MyHomePage() : SignupPage();
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key}); 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    Pet selectedPet = appState.selectedPet;
    Widget page;
    switch(appState.currentPageIndex){
      case 0:
        page = HomePage(pet: selectedPet);
      case 1:
        page = const ProgressTrackerPage();
      case 2:
        page = const CameraPage();
      case 3:
        page = const FoodPage();
      case 4:
        page = const ProfilePage();
      default:
        throw UnimplementedError('No widget for selectedIndex: ${appState.currentPageIndex}');
    }
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: page,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Image.asset("assets/sigmalogo.png", width: 88, height: 88, fit: BoxFit.cover,), 
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes), 
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera), 
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.rice_bowl), 
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.person), 
            label: 'Profile',
          ),
        ],
        selectedIndex: appState.currentPageIndex, 
        onDestinationSelected: (value){
            appState.changeIndex(value);
        },
      ),
    );
  }
}