import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:raja/faceDetection/face_screen.dart';
import 'package:raja/home/image_model.dart';
import 'package:raja/objectDetection/object_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  final StreamController<List<ImageModel>> _streamController = StreamController<List<ImageModel>>();

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Future<void> _loadThumbnails() async {
    final directory = Directory('/storage/emulated/0/test');
    if (!await directory.exists()) {
      _streamController.add([]);
      _streamController.close();
      return;
    }

    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<File> files = entities.whereType<File>().where((file) {
      final extension = file.path.toLowerCase();
      return extension.endsWith('.jpg') || extension.endsWith('.jpeg') || extension.endsWith('.png');
    }).toList();

    final tempDir = await getTemporaryDirectory();
    final thumbnailDir = Directory('${tempDir.path}/thumbnails');
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create();
    }

    final List<ImageModel> thumbnails = [];
    for (var file in files.reversed) {
      final thumbnailPath = path.join(thumbnailDir.path, path.basename(file.path));
      final thumbnailFile = File(thumbnailPath);

      if (!await thumbnailFile.exists()) {
        final Uint8List imgData = await compute(_generateThumbnail, file.path);
        await thumbnailFile.writeAsBytes(imgData);
      }

      thumbnails.add(ImageModel(originalFile: file, thumbnailFile: thumbnailFile));
      _streamController.add(thumbnails.toList()); // Add a copy to trigger UI update
    }

    _streamController.close(); // Close the stream after all images are processed
  }

  static Future<Uint8List> _generateThumbnail(String filePath) async {
    final file = File(filePath);
    final originalImage = img.decodeImage(await file.readAsBytes())!;

    // Calculate the aspect ratio of the original image and the target thumbnail
    const aspectRatio = 1.0; // 100 / 100

    // Determine the dimensions for cropping
    int cropWidth, cropHeight;
    if (originalImage.width > originalImage.height) {
      cropHeight = originalImage.height;
      cropWidth = (originalImage.height * aspectRatio).toInt();
    } else {
      cropWidth = originalImage.width;
      cropHeight = (originalImage.width / aspectRatio).toInt();
    }

    // Calculate the crop position (center crop)
    final offsetX = (originalImage.width - cropWidth) ~/ 2;
    final offsetY = (originalImage.height - cropHeight) ~/ 2;

    // Crop the image
    final croppedImage = img.copyCrop(originalImage, x: offsetX, y: offsetY, width: cropWidth, height: cropHeight);

    // Resize the cropped image to the target size with high quality
    final thumbnailImage = img.copyResize(croppedImage, width: 200, height: 200, interpolation: img.Interpolation.cubic);

    // Encode the image as JPEG with high quality
    // return Uint8List.fromList(img.encodeJpg(thumbnailImage, quality: 90)); // Adjust the quality parameter as needed

    // Encode the image as PNG without compression loss
    return Uint8List.fromList(img.encodePng(thumbnailImage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Album',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ImageModel>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading images', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No images found', style: TextStyle(color: Colors.white)));
          }

          final imageDataList = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
              childAspectRatio: 1 / 1,
            ),
            itemCount: imageDataList.length,
            itemBuilder: (context, index) {
              final imageData = imageDataList[index];
              return InkWell(
                onTap: () => isHaveFaces(imageData.originalFile),
                child: Hero(
                  tag: imageData.originalFile.path,
                  child: Image.file(
                    imageData.thumbnailFile,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> isHaveFaces(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    List<Face> faces = await faceDetector.processImage(inputImage);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => (faces.isNotEmpty) ? FaceScreen(imageFile: image) : ObjectScreen(imageFile: image),
        ));
  }
}
