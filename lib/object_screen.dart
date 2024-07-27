import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'helper/image_classification_helper.dart';

class ObjectScreen extends StatefulWidget {
  final File imageFile;

  const ObjectScreen({super.key, required this.imageFile});

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

class _ObjectScreenState extends State<ObjectScreen> {
  late ImageClassificationHelper imageClassificationHelper;
  img.Image? image;
  Map<String, double>? classification;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper.initHelper().then((_) {
      processImage();
    });
  }

  Future<void> processImage() async {
    final imagePath = widget.imageFile.path;
    final imageData = await File(imagePath).readAsBytes();
    image = img.decodeImage(imageData);
    classification = await imageClassificationHelper.inferenceImage(image!);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    imageClassificationHelper.close();
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
                        const Text('No face found in the image! Possible classification:', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: Colors.grey.shade900.withOpacity(0.5),
                          child: (isLoading)
                              ? const SizedBox(height: 125, child: Center(child: CircularProgressIndicator(color: Colors.white)))
                              : Column(
                                  children: [
                                    if (classification != null)
                                      ...(classification!.entries.toList()
                                            ..sort(
                                              (a, b) => b.value.compareTo(a.value),
                                            ))
                                          .take(3)
                                          .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Row(
                                                children: [
                                                  Text(e.key, style: const TextStyle(color: Colors.white)),
                                                  const Spacer(),
                                                  Text('${(e.value * 100).toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white))
                                                ],
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
