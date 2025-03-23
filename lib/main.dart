import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/firebase_options.dart';
import 'package:pet_health_ai/pages/login_page.dart';
import 'package:pet_health_ai/pages/name_page.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appState = MyAppState();
  await appState.init();
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final MyAppState appState;
  const MyApp({super.key, required this.appState});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
          title: 'Pet Health AI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(152, 171, 218, 1)),
            scaffoldBackgroundColor: Color.fromRGBO(215,215,215,1),
          ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              var appState = context.watch<MyAppState>();
              if (appState.needsToEnterName) {
                return const EnterNamePage();
              } else {
                return const MyHomePage();
              }
            } else {
              return EnterAccountPage();
            }
          }
        )
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

    print("🔄 UI Rebuilt - Current SharedPreferences:");
    appState.printSharedPreferences(); 
    print(appState.pets);

    Pet selectedPet = appState.selectedPet;
    Widget page;
    switch(appState.currentPageIndex){
      case 0:
        page = HomePage(pet: selectedPet);
      case 1:
        page = ProgressTrackerPage(pet: selectedPet);
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

class EnterAccountPage extends StatefulWidget{
  const EnterAccountPage({super.key});

  @override
  State<EnterAccountPage> createState() => _EnterAccountPageState();
}

class _EnterAccountPageState extends State<EnterAccountPage>{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    Widget page;
    switch(appState.enterAccountIndex){
      case 0:
        page = SignUpPage();
      case 1:
        page = LoginPage();
      default:
        throw UnimplementedError('No widget for selectedIndex: ${appState.enterAccountIndex}');
    } 
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: page,
      ),
    );
  }
}