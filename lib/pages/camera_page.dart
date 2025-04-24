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
  late MobileScannerController controller;
  bool _busy = false;

  void _initScanner() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    controller.start();
  }

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_busy) return;
              _busy = true;
              
              try {
                await controller.stop();

                final barcode = capture.barcodes.first.rawValue;
                if (barcode == null) return;

                if (!context.mounted) return;
                final appState = context.read<MyAppState>();   // ← Provider
                await appState.fetchBarcodeData(barcode);

                if (!appState.barcodeNotFound) {
                  if (!context.mounted) return;
                  _busy = true;
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
                          onPressed: () => {Navigator.pop(_, false), controller.start(), _busy = false}, // “No”
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => {Navigator.pop(_, true), _busy = false},  // “Yes”
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  ) ??
                  false; // returns null if dialog is dismissed some other way
                  _busy = false;
                  if (!mounted) return;

                  if (confirmed) {
                    if (!context.mounted) return;
                    // open the feed dialog and wait until it closes
                    await showFeedDialog(
                      context,
                      appState.selectedPet,
                      selectedProductBarcode: barcode,
                    );
                  }
                }
                else{
                  if (!context.mounted) return;
                  final shouldOpenCamera = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
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
                            Navigator.of(dialogCtx).pop(true);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ) ?? false;
                  if (shouldOpenCamera) {
                    if (mounted) {
                      widget.goToNormalCamera(barcode);   // push / replace next page
                    }
                  }

                  return;
                }
              } finally {
                _busy = false;
                if (mounted){
                  controller.start();
                }
              }
            }
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
    controller.stop();
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
  bool _isUploading = false;

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
                    onPressed: _isUploading 
                      ? null 
                      : () async {
                        setState(() {
                          _isUploading = true;
                        });
                        try {
                          final scanID = await uploadPackagePictures(widget.barcode, _shots[0], _shots[1]);

                          if (!context.mounted) return;
                          final bool? finished = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScanProgressPage(scanID: scanID, barcode: widget.barcode),
                            ),
                          );
                          if (finished == true) {
                            widget.goBackToScanner();
                          }
                        } catch (e) {
                          // show error dialog / retry
                          debugPrint('Upload failed: $e');
                        }
                        finally {
                          if (mounted) setState(() => _isUploading = false); // 🔓 unlock
                        }
                      },
                      icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                      label: Text(_isUploading ? 'Uploading…' : 'Use these'),
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
                          : 'Take GUARANTEED ANALYSIS and CALORIE CONTENT(BACK of package)',
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

class ScanProgressPage extends StatefulWidget {
  final String scanID;
  final String barcode;
  const ScanProgressPage({super.key, required this.scanID, required this.barcode});

  @override
  State<ScanProgressPage> createState() => _ScanProgressPageState();
}

class _ScanProgressPageState extends State<ScanProgressPage> {
  final _formKey = GlobalKey<_ReviewFormState>();
  String _status = "pending";

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance
        .collection('packageScans')
        .doc(widget.scanID);

    return PopScope<void>(
      canPop: _status != "done",
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // If we blocked the automatic pop (didPop == false) and the review
        // form is showing, run the same clean-up as the “Cancel” button.
        if (!didPop && _status == 'done') {
          await _formKey.currentState?.cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing…'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_status == 'done') {
                await _formKey.currentState?.cancel();
              } else {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: doc.snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
      
            final newStatus = (snap.data!.data()?['status'] ?? 'pending') as String;          
            if (newStatus != _status) {                                      
              WidgetsBinding.instance.addPostFrameCallback((_) {                 
                if (mounted) setState(() => _status = newStatus);             
              });                                                       
            }                                                                

            if (newStatus == 'error') {
              return Center(
                child: Text('❌ ${(snap.data!.data()?['message']) ?? 'Unknown error'}'),
              );
            }

            if (newStatus == 'done') {
              return _ReviewForm(
                key: _formKey,                
                scanID: widget.scanID,
                barcode: widget.barcode,
              );
            }
      
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
        ),
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget{
  final String scanID;
  final String barcode;

  const _ReviewForm({super.key, required this.scanID, required this.barcode,});
  @override
  
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  Map<String, TextEditingController>? _topCtrls;   // productName, brandName, caloriesPer100g
  Map<String, TextEditingController>? _gaCtrls;    // guaranteed‑analysis inputs
  Set<String> _missing = {};
  String? _imageUrl;


  void _initControllers(Map<String, dynamic> food) {
    _missing =
        ((food['missing'] as List<dynamic>? ?? []).cast<String>()).toSet();

    _topCtrls = {
      'productName':
          TextEditingController(text: food['productName']?.toString() ?? ''),
      'brandName':
          TextEditingController(text: food['brandName']?.toString() ?? ''),
      'caloriesPer100g': TextEditingController(
          text: food['caloriesPer100g']?.toString() ?? ''),
    };

    final ga =
        (food['guaranteedAnalysis'] as Map<String, dynamic>? ?? <String, dynamic>{});

    final allGaKeys = {...ga.keys, ..._missing}
      ..removeWhere(_topCtrls!.containsKey); // keep GA‑only keys

    _gaCtrls = {
      for (final k in allGaKeys)
        k: TextEditingController(text: ga[k]?.toString() ?? ''),
    };

    final path = food['frontImage'] as String?;
    if (path != null && path.isNotEmpty) {
      FirebaseStorage.instance.ref(path).getDownloadURL().then((url) {
        if (mounted) setState(() => _imageUrl = url);
      });
    }
  }

  @override
  void dispose() {
    _topCtrls?.values.forEach((c) => c.dispose());
    _gaCtrls?.values.forEach((c) => c.dispose());
    super.dispose();
  }

  /* ─────────────────── Firestore helpers ─────────────────── */

  Future<void> _deleteScanDoc() => FirebaseFirestore.instance
      .collection('packageScans')
      .doc(widget.scanID)
      .delete();

  Future<void> _deleteFoodDoc() => FirebaseFirestore.instance
      .collection("foods")
      .doc(widget.barcode)
      .delete();

  Future<void> _onCancel() async {
    if (mounted) Navigator.of(context).pop(true);

    final bucket = FirebaseStorage.instance;
    await Future.wait([
      bucket.ref('package-scans/${widget.scanID}/front.jpg').delete(),
    ]);

    await _deleteScanDoc();
    await _deleteFoodDoc();
  }

  Future<void> _onVerify() async {
    if (mounted) Navigator.of(context).pop(true);
    final topUpdates = <String, dynamic>{};
    final gaUpdates = <String, dynamic>{};
    final providedKeys = <String>{};

    _topCtrls!.forEach((k, c) {
      final txt = c.text.trim();
      if (txt.isNotEmpty) {
        topUpdates[k] = num.tryParse(txt) ?? txt;
        providedKeys.add(k);
      }
    });

    _gaCtrls!.forEach((k, c) {
      final txt = c.text.trim();
      if (txt.isNotEmpty) {
        gaUpdates[k] = num.tryParse(txt) ?? txt;
        providedKeys.add(k);
      }
    });

    final newMissing = _missing.difference(providedKeys);

    final updates = <String, dynamic>{
      ...topUpdates,
      if (gaUpdates.isNotEmpty) 'guaranteedAnalysis': gaUpdates,
      if (newMissing.isEmpty)
        'missing': FieldValue.delete()
      else
        'missing': newMissing.toList(),
    };

    final doc = FirebaseFirestore.instance
      .collection('foods')
      .doc(widget.barcode);

    await doc.set(updates, SetOptions(merge: true));

    await _deleteScanDoc();
  }

  /* ─────────────────── UI builders ─────────────────── */

  Widget _buildForm() {
    final missingStyle = TextStyle(color: Colors.orange.shade700);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // ---------- picture ----------
          if (_imageUrl != null)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_imageUrl!, fit: BoxFit.cover),
              ),
            )
          else
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),

          // ---------- basic info ----------
          const Text('Basic info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final k in _topCtrls!.keys) ...[
            Row(
              children: [
                Expanded(child: Text(k)),
                if (_missing.contains(k))
                  Text('(missing)', style: missingStyle),
              ],
            ),
            TextField(controller: _topCtrls![k]),
            const SizedBox(height: 12),
          ],

          // ---------- guaranteed analysis ----------
          if (_gaCtrls!.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Guaranteed analysis (per 100 g)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final k in _gaCtrls!.keys) ...[
              Row(
                children: [
                  Expanded(child: Text(k)),
                  if (_missing.contains(k))
                    Text('(missing)', style: missingStyle),
                ],
              ),
              TextField(
                controller: _gaCtrls![k],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(suffixText: 'g'),
              ),
              const SizedBox(height: 12),
            ],
          ],

          // ---------- buttons ----------
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                onPressed: _onCancel,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Verify'),
                onPressed: _onVerify,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ─────────────────── main build ─────────────────── */

  @override
  Widget build(BuildContext context) {
    final foodDoc =
        FirebaseFirestore.instance.collection('foods').doc(widget.barcode);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: foodDoc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docSnap = snap.data!;

        if (!docSnap.exists && !docSnap.metadata.isFromCache) {
          return Center(
            child: Text('No food record found for barcode ${widget.barcode}.'),
          );
        }

        if (!docSnap.exists) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final food = docSnap.data();
        
        if (_topCtrls == null) _initControllers(food!);

        return _buildForm();
      },
    );
  }

  Future<void> cancel() => _onCancel();
}

