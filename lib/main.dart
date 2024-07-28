import 'package:flutter/material.dart';
import 'package:raja/home/album_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AlbumScreen());
  }
}

/*
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceComparison(),
    );
  }
}

class FaceComparison extends StatefulWidget {
  @override
  _FaceComparisonState createState() => _FaceComparisonState();
}

class _FaceComparisonState extends State<FaceComparison> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector();
  List<Face> _faces1 = [];
  List<Face> _faces2 = [];

  Future<void> _detectFaces() async {
    final XFile? image1 = await _picker.pickImage(source: ImageSource.gallery);
    final XFile? image2 = await _picker.pickImage(source: ImageSource.gallery);

    if (image1 != null && image2 != null) {
      final inputImage1 = InputImage.fromFilePath(image1.path);
      final inputImage2 = InputImage.fromFilePath(image2.path);

      final faces1 = await _faceDetector.processImage(inputImage1);
      final faces2 = await _faceDetector.processImage(inputImage2);

      setState(() {
        _faces1 = faces1;
        _faces2 = faces2;
      });

      _compareFaces();
    }
  }

  void _compareFaces() {
    if (_faces1.isNotEmpty && _faces2.isNotEmpty) {
      for (var face1 in _faces1) {
        for (var face2 in _faces2) {
          // مقایسه ویژگی‌های چهره‌ها (مثلاً با استفاده از نقاط خاص چهره)
          if (_compareFaceFeatures(face1, face2)) {
            print("چهره مشابه پیدا شد");
          } else {
            print("چهره مشابه پیدا نشد");
          }
        }
      }
    }
  }

  bool _compareFaceFeatures(Face face1, Face face2) {
    // مقایسه نقاط خاص چهره‌ها
    // به عنوان مثال:
    final leftEye1 = face1.landmarks[FaceLandmarkType.leftEye];
    final leftEye2 = face2.landmarks[FaceLandmarkType.leftEye];

    if (leftEye1 != null && leftEye2 != null) {
      final dx = leftEye1.position.x - leftEye2.position.x;
      final dy = leftEye1.position.y - leftEye2.position.y;
      final distance = math.sqrt(dx * dx + dy * dy);

      return distance < 10; // تعیین آستانه برای تشخیص مشابهت
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مقایسه چهره‌ها'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _detectFaces,
          child: Text('انتخاب تصاویر و مقایسه'),
        ),
      ),
    );
  }
}
*/
