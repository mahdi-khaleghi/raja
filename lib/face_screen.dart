import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  XFile? _imageFile;
  List<Face> _faces = [];
  ui.Image? _image;

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      final List<Face> faces = await detectFaces(photo);
      final ui.Image image = await loadImage(File(photo.path));
      print('Faces detected: ${faces.length}'); // Log تعداد صورت‌های شناسایی‌شده
      setState(() {
        _imageFile = photo;
        _faces = faces;
        _image = image;
      });
    }
  }

  Future<List<Face>> detectFaces(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    return faces;
  }

  Future<ui.Image> loadImage(File file) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = FileImage(file).resolve(const ImageConfiguration());
    final ImageStreamListener listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    });
    stream.addListener(listener);
    return completer.future;
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
      ),
      body: Center(
        child: _imageFile == null
            ? const Text('No image selected.')
            : Column(
                children: [
                  Expanded(
                    child: _image == null
                        ? const CircularProgressIndicator()
                        : FittedBox(
                            child: SizedBox(
                              width: _image!.width.toDouble(),
                              height: _image!.height.toDouble(),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(_imageFile!.path)),
                                  CustomPaint(
                                    painter: FacePainter(_faces, _image!.width.toDouble(), _image!.height.toDouble()),
                                    child: Container(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Text('Faces detected: ${_faces.length}'), // نمایش تعداد صورت‌های شناسایی‌شده
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final double originalWidth;
  final double originalHeight;

  FacePainter(this.faces, this.originalWidth, this.originalHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..color = Colors.red;

    final double scaleX = size.width / originalWidth;
    final double scaleY = size.height / originalHeight;

    for (var face in faces) {
      final rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );
      print('Face bounding box: $rect'); // Log اطلاعات مربوط به هر صورت شناسایی‌شده
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
