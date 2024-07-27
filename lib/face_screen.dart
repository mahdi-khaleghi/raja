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
  _FaceScreenState createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  late XFile _imageFile;
  List<Face> _faces = [];
  List<ui.Image> _faceImages = [];
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
    final List<ui.Image> faceImages = await _extractFaces(image, faces);

    print('Faces detected: ${faces.length}');
    setState(() {
      _imageFile = photo;
      _faces = faces;
      _faceImages = faceImages;
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
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, // نمایش افقی لیست چهره‌ها
                            itemCount: _faceImages.length,
                            itemBuilder: (context, index) {
                              final faceImage = _faceImages[index];
                              return Container(
                                margin: EdgeInsets.all(8.0),
                                width: 100,
                                height: 100,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: faceImage.width.toDouble(),
                                    height: faceImage.height.toDouble(),
                                    child: RawImage(image: faceImage),
                                  ),
                                ),
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
