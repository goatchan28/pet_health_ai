import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextRecognitionView(imageFile: _selectedImage!),
          ),
        );

        // ✅ Reset image reference after returning
        if (result == "reset" && mounted) {
          setState(() {
            _selectedImage = null; // ✅ Clears old image
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload an Image")),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload),
          label: const Text("Upload Image"),
        ),
      ),
    );
  }
}

/// Text Recognition View - Extracts Text from Passed Image
class TextRecognitionView extends StatefulWidget {
  final File imageFile;

  const TextRecognitionView({super.key, required this.imageFile});

  @override
  State<TextRecognitionView> createState() => _TextRecognitionViewState();
}

class _TextRecognitionViewState extends State<TextRecognitionView> {
  String _recognizedText = "Extracting text...";
  Map<String, Map<String, double>> extractedNutrients = {};

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    final inputImage = InputImage.fromFile(widget.imageFile);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text.isNotEmpty
            ? recognizedText.text
            : "No text detected.";
      });
    } catch (e) {
      setState(() {
        _recognizedText = "Error recognizing text.";
      });
    }

    textRecognizer.close();
  }

  Future<void> _analyzeText(String text) async {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text Recognition")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.file(widget.imageFile, height: 300),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _recognizedText,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ElevatedButton(
                onPressed: (){_analyzeText(_recognizedText);}, 
                child: Text("Analyze Text")
              )
            ],
          ),
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