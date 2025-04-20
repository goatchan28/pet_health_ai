import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late final PageController _pageCtrl;
  late String _pendingBarcode;
  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();              // new
    _pendingBarcode = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,                 // hook it up
        onPageChanged: (index) {
          if (index == 0 && _pendingBarcode.isNotEmpty) {
            // user swiped (or programmatically returned) to the QR page
            setState(() => _pendingBarcode = "");
          }
        },
        children: [
          QRScannerView(
            camera: widget.camera,
            goToNormalCamera: (barcode) {
              setState(() => _pendingBarcode = barcode);      // store it
              _pageCtrl.animateToPage(1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
            },
          ),
          NormalCameraView(
            camera: widget.camera, 
            barcode: _pendingBarcode,
            goBackToScanner: () {
              setState(() => _pendingBarcode = "");      // <‑‑ reset
              _pageCtrl.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }
}

class QRScannerView extends StatefulWidget {
  final CameraDescription camera;
  final void Function(String) goToNormalCamera;          // <‑‑ new
  const QRScannerView({
    super.key,
    required this.camera,
    required this.goToNormalCamera,
  });

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              final barcode = capture.barcodes.first.rawValue;
              if (barcode == null) return;
              controller.stop();
              final appState = context.read<MyAppState>();   // ← Provider
              await appState.fetchBarcodeData(barcode);

              if (!appState.barcodeNotFound) {
                if (!context.mounted) return;
                final bool confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Is this your food?'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(appState.scannedFoodData['productName'], style: TextStyle(
                          fontWeight: FontWeight.w600,   // semibold
                          fontSize: 26,
                          letterSpacing: 0.3,
                        ),),
                        Text(
                          appState.scannedFoodData['brandName'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],       // subtle secondary color
                            fontSize: 22
                          ),
                        )
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => {Navigator.pop(_, false), controller.start()}, // “No”
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => {Navigator.pop(_, true)},  // “Yes”
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                ) ??
                false; // returns null if dialog is dismissed some other way

                if (!mounted) return;

                if (confirmed) {
                  if (!context.mounted) return;
                  // open the feed dialog and wait until it closes
                  await showFeedDialog(
                    context,
                    appState.selectedPet,
                    selectedProductBarcode: barcode,
                  );
                  if (mounted) controller.start();
                }
              }
              else{
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Barcode not found'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("We couldn’t find any data for this barcode."),
                        SizedBox(height: 12),
                        Text(
                          "Please take clear pictures "
                          "of the FRONT and BACK of the package.",
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed:() async {
                          appState.barcodeNotFound = false;
                          controller.start();
                          Navigator.pop(context);
                          widget.goToNormalCamera(barcode);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
              controller.start();
            },
          ),

          // Overlay Scanner Box
          Center(
            child: Container(
              width: 300,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Torch toggle button
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.flashlight_on, color: Colors.white, size: 30),
              onPressed: () {
                controller.toggleTorch();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

enum CaptureStage { front, back, done }

// QR Scanner View
class NormalCameraView extends StatefulWidget {
  final CameraDescription camera;
  final String barcode;
  final VoidCallback goBackToScanner;
  const NormalCameraView({super.key, required this.camera, required this.barcode, required this.goBackToScanner});

  @override
  State<NormalCameraView> createState() => _NormalCameraViewState();
}

class _NormalCameraViewState extends State<NormalCameraView> {
  late final CameraController _controller;
  late final Future<void> _initializeControllerFuture;
  CaptureStage _stage = CaptureStage.front;
  final List<XFile> _shots = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takeShot() async {
    await _initializeControllerFuture;   
    final shot = await _controller.takePicture();
    _shots.add(shot);

    if (_stage == CaptureStage.front) {
      setState(() => _stage = CaptureStage.back);   // ➌ ask for back
    } else {
      await _controller.pausePreview();
      setState(() => _stage = CaptureStage.done);             // ➍ return both pics
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.barcode.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please scan a barcode first.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.goBackToScanner,       // go back to QR page
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to scanner'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_stage == CaptureStage.done) {
            return Column(
              children: [
                Expanded(
                  child: Image.file(
                    File(_shots[0].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Image.file(
                    File(_shots[1].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final scanId = await uploadPackagePictures(widget.barcode, _shots[0], _shots[1]);

                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanProgressPage(scanID: scanId),
                          ),
                        );
                      } catch (e) {
                        // show error dialog / retry
                        debugPrint('Upload failed: $e');
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Use these'),
                  ),
                ),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller),         // full‑screen preview
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(                    // small on‑screen hint
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stage == CaptureStage.front
                          ? 'Take FRONT of package'
                          : 'Take BACK / Nutrition label',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // big circular shutter button
      floatingActionButton: _stage == CaptureStage.done 
        ? null 
        : ClipOval(
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            child: InkWell(
              onTap: _stage == CaptureStage.done ? null : _takeShot,
              child: const SizedBox(
                width: 80,
                height: 80,
                child: Icon(Icons.camera_alt, size: 36, color: Colors.white),
              ),
            ),
          ),
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

Future<String> uploadPackagePictures(String barcode, XFile front, XFile back) async {
  final storage = FirebaseStorage.instance;
  final scanID = const Uuid().v4();

  final folder   = 'package-scans/$scanID';                  // ②
  final frontRef = storage.ref('$folder/front.jpg');
  final backRef  = storage.ref('$folder/back.jpg');

  await frontRef.putFile(File(front.path));                  // ③
  await backRef.putFile(File(back.path));

  await FirebaseFirestore.instance
    .collection('packageScans')
    .doc(scanID)                   // same ID as folder name
    .set({
      'barcode' : barcode,
      'frontPath': '$folder/front.jpg',
      'backPath' : '$folder/back.jpg',
      'status'   : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'user'     : FirebaseAuth.instance.currentUser!.uid,
    }
  );

  return scanID;
}

class ScanProgressPage extends StatelessWidget {
  final String scanID;
  const ScanProgressPage({super.key, required this.scanID});

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance
        .collection('packageScans')
        .doc(scanID);

    return Scaffold(
      appBar: AppBar(title: const Text('Processing…')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doc.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          final status = data?['status'] ?? 'pending';

          if (status == 'done') {
            // ---------- SUCCESS ----------
            return Text("success"); // or whatever you need
          } else if (status == 'error') {
            return Center(
              child: Text('❌ ${data?['message'] ?? 'Unknown error'}'),
            );
          } else {
            // ---------- STILL WORKING ----------
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Extracting nutrition…'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}


