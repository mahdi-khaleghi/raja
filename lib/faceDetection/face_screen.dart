import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raja/find/find_screen.dart';

class FaceScreen extends StatefulWidget {
  final File imageFile;

  const FaceScreen({super.key, required this.imageFile});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  List<Face> _faces = [];
  List<ui.Image> _faceImages = [];

  @override
  void initState() {
    super.initState();
    detectFaces();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: widget.imageFile.path,
                child: Image.file(widget.imageFile),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Text('Faces detected:', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: List.generate(
                        _faceImages.length,
                        (int index) {
                          final faceImage = _faceImages[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FindScreen(faceImage: faceImage),
                                  ));
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ClipOval(
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: faceImage.width.toDouble(),
                                          height: faceImage.height.toDouble(),
                                          child: RawImage(image: faceImage),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('?', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> detectFaces() async {
    final XFile photo = XFile(widget.imageFile.path);
    final inputImage = InputImage.fromFilePath(widget.imageFile.path);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    final ui.Image image = await loadImage(File(photo.path));
    final List<ui.Image> faceImages = await _extractFaces(image, faces);

    setState(() {
      _faces = faces;
      _faceImages = faceImages;
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

  Future<List<ui.Image>> _extractFaces(ui.Image image, List<Face> faces) async {
    final List<ui.Image> faceImages = [];
    for (var face in faces) {
      final ui.Image faceImage = await _cropImage(image, face.boundingBox);
      faceImages.add(faceImage);
    }
    return faceImages;
  }

  Future<ui.Image> _cropImage(ui.Image image, Rect rect) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    canvas.drawImageRect(image, rect, Rect.fromLTWH(0, 0, rect.width, rect.height), paint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(rect.width.toInt(), rect.height.toInt());
    return img;
  }
}
