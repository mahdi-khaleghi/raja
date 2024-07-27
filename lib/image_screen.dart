import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'helper/image_classification_helper.dart';

class ImageScreen extends StatefulWidget {
  final int index;

  const ImageScreen({super.key, required this.index});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  ImageClassificationHelper? imageClassificationHelper;
  List<File> imageFiles = [];
  int currentImageIndex = 0;
  img.Image? image;
  Map<String, double>? classification;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final directory = Directory('/storage/emulated/0/test');
    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<File> files = entities.whereType<File>().where((file) => file.path.toLowerCase().endsWith('.jpg')).toList();

    setState(() {
      imageFiles = files;
      currentImageIndex = widget.index;
    });

    // Process the first image if available
    if (imageFiles.isNotEmpty) {
      processImage();
    }
  }

  Future<void> processImage() async {
    if (imageFiles.isNotEmpty && currentImageIndex < imageFiles.length) {
      setState(() {
        isLoading = true;
      });

      final imagePath = imageFiles[currentImageIndex].path;
      final imageData = File(imagePath).readAsBytesSync();
      image = img.decodeImage(imageData);
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    imageClassificationHelper?.close();
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
                  if (imageFiles.isNotEmpty && currentImageIndex < imageFiles.length) Image.file(imageFiles[currentImageIndex]),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 56,
                        child: AppBar(
                          backgroundColor: Colors.grey.shade900.withOpacity(0.5),
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (image == null || isLoading) const CircularProgressIndicator(color: Colors.white),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
                          child: Column(
                            children: [
                              if (classification != null && !isLoading)
                                ...(classification!.entries.toList()
                                  ..sort(
                                        (a, b) => a.value.compareTo(b.value),
                                  ))
                                    .reversed
                                    .take(3)
                                    .map(
                                      (e) => Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.grey.shade900.withOpacity(0.5),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (currentImageIndex > 0)
                            TextButton(
                              onPressed: () {
                                currentImageIndex--;
                                processImage();
                              },
                              child: const Text("<< Previous", style: TextStyle(color: Colors.white)),
                            ),
                          const Spacer(),
                          if (currentImageIndex < imageFiles.length - 1)
                            TextButton(
                              onPressed: () {
                                currentImageIndex++;
                                processImage();
                              },
                              child: const Text("Next >>", style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    ],
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
