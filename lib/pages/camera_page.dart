import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatelessWidget {
  final CameraDescription camera;
  const CameraPage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          NormalCameraView(camera: camera),
          QRScannerView(camera: camera,),
        ],
      ),
    );
  }
}

/// Normal Camera View - Handles Image Upload & Navigates to Text Recognition
class NormalCameraView extends StatefulWidget {
  final CameraDescription camera;
  const NormalCameraView({super.key, required this.camera});

  @override
  State<NormalCameraView> createState() => _NormalCameraViewState();
}

class _NormalCameraViewState extends State<NormalCameraView> {
  File? _selectedImageFront;
  File? _selectedImageBack;

  Future<void> _pickImage(int imageIndex) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (imageIndex == 1){
          _selectedImageFront = File(image.path);
        }
        else{
          _selectedImageBack = File(image.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload an Image")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _selectedImageFront != null 
              ? Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.file(
                          _selectedImageFront!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImageFront = null; // Clear the image if user wants
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Remove Front Image"),
                    ),
                  ],
                )
              : Center(
                child: ElevatedButton.icon(
                    onPressed: () => _pickImage(1),
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload Front of Package"),
                  ),
              ),
          ),
          const Divider(thickness: 2,),
      
          Expanded(
            child: _selectedImageBack != null 
              ? Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Image.file(
                          _selectedImageBack!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImageBack = null; // Clear the image if user wants
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Remove Back Image"),
                    ),
                  ],
                )
              : Center(
                child: ElevatedButton.icon(
                    onPressed: () => _pickImage(2),
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload Back of Package"),
                  ),
              ),
          ),  
        ],
      ),
    );
  }
}

// QR Scanner View
class QRScannerView extends StatefulWidget {
  final CameraDescription camera;
  const QRScannerView({super.key, required this.camera});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return CameraPreview(_controller);
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
