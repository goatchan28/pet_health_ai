import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatelessWidget {
  
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          NormalCameraView(),
          QRScannerView(),
        ],
      ),
    );
  }
}

/// Normal Camera View - Handles Image Upload & Navigates to Text Recognition
class NormalCameraView extends StatefulWidget {
  const NormalCameraView({super.key});

  @override
  State<NormalCameraView> createState() => _NormalCameraViewState();
}

class _NormalCameraViewState extends State<NormalCameraView> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // ✅ Save image in memory
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload an Image")),
      body: Center(
        child: _selectedImage != null 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.file(
                  _selectedImage!,
                  height: 300,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null; // Clear the image if user wants
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Remove Image"),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Image"),
            ),
      ),
    );
  }
}

// QR Scanner View
class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  @override
  Widget build(BuildContext context) {
      return Center(child: Text("QR Scanner Mode"));
  }
}