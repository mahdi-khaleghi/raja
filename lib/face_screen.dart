import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class FaceScreen extends StatefulWidget {
  final File imageFile;

  const FaceScreen({super.key, required this.imageFile});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  late XFile _imageFile;
  List<Face> _faces = [];
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    detectFaces();
  }

  Future<void> detectFaces() async {
    final XFile photo = XFile(widget.imageFile.path);
    final inputImage = InputImage.fromFilePath(widget.imageFile.path);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    final ui.Image image = await loadImage(File(photo.path));
    print('Faces detected: ${faces.length}');
    setState(() {
      _imageFile = photo;
      _faces = faces;
      _image = image;
    });
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: widget.imageFile.path,
                    child: Image.file(widget.imageFile),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 8,
                    right: 8,
                    child: Column(
                      children: [
                        Text('Faces detected: ${_faces.length}', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 125,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: Colors.grey.shade900.withOpacity(0.5),
                          child:  ListView.builder(
                            itemCount: _faces.length,
                            itemBuilder: (context, index) {
                              final face = _faces[index];
                              return ListTile(
                                title: Text('Face ${index + 1}'),
                                subtitle: Text('Bounding Box: ${face.boundingBox.toString()}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  /* FittedBox(
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
                  ),*/
                ],
              ),
            ),
          ],
        ),
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
      ..strokeWidth = 5.0
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
      print('Face bounding box: $rect');
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
