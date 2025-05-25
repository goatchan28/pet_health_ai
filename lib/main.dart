import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  FirebaseFirestore.instance.settings =
    const Settings(persistenceEnabled: true);   // ← NEW
  // Get a list of available cameras
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    print('⚠️ No cameras found on this device.');
  }
  final firstCamera = cameras.isNotEmpty ? cameras.first : null;

  final appState = MyAppState();
  await appState.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ChangeNotifierProvider.value(value: appState),
    ],
    child: MyApp(camera: firstCamera)));
}

class ConnectivityService with ChangeNotifier {
  ConnectivityResult _status = ConnectivityResult.none;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((results) {
      // `results` is a List<ConnectivityResult>
      _status = results.contains(ConnectivityResult.wifi) ||
                results.contains(ConnectivityResult.mobile)
          ? ConnectivityResult.wifi   // any online type → treat as online
          : ConnectivityResult.none;  // otherwise offline

      notifyListeners();
    });
  }

  bool get isOnline => _status != ConnectivityResult.none;
}

class SplashGate extends StatelessWidget {
  final Widget child;
  const SplashGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final online     = context.watch<ConnectivityService>().isOnline;
    final signedIn   = FirebaseAuth.instance.currentUser != null;

    if (!online && !signedIn) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No Internet connection.\nConnect to sign in the first time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return child;
  }
}

class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  const ConnectivityBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    return Stack(
      children: [
        child,
        if (!online)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const Text(
                  '⚠️  Offline - you can navigate, but changes disabled',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class MyApp extends StatelessWidget {
  final CameraDescription? camera;
  const MyApp({super.key, required this.camera});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Pet Health AI',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(152, 171, 218, 1)),
          scaffoldBackgroundColor: Color.fromRGBO(215,215,215,1),
        ),
      home: SplashGate(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return Consumer<MyAppState>(                 // <-- add this
                builder: (_, appState, __) {
                  return appState.needsToEnterName
                      ? const EnterNamePage()
                      : MyHomePage(camera: camera);
                },
              );
            } else {
              return EnterAccountPage();
            }
          }
        ),
      )
    );
  } 
}

class MyHomePage extends StatefulWidget {
  final CameraDescription? camera;
  const MyHomePage({super.key, required this.camera}); 
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
        break;
      case 1:
        page = ProgressTrackerPage(pet: selectedPet);
        break;
      case 2:
        if (widget.camera == null) {
          page = const Center(
            child: Text("No camera found on this device.", style: TextStyle(fontSize: 18)),
          );
        } else {
          page = CameraPage(camera: widget.camera!, 
            initialPage: appState.startWithManualCamera ? 1 : 0, 
            initialBarcode: appState.manualCameraBarcode,
          );
          appState.startWithManualCamera = false;
          appState.manualCameraBarcode   = null;
        }
        break;
      case 3:
        page = const FoodPage();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        throw UnimplementedError('No widget for selectedIndex: ${appState.currentPageIndex}');
    }
    return ConnectivityBanner(
      child: Scaffold(
        body: Container(
          color: Theme.of(context).colorScheme.primary,
          child: page,
        ),
        bottomNavigationBar: NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Image.asset("assets/images/sigmalogo.png", width: 88, height: 88, fit: BoxFit.cover,), 
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
        break;
      case 1:
        page = LoginPage();
        break;
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