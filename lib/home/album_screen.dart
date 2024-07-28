import 'dart:io';
import 'dart:typed_data';

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
  late Future<List<ImageModel>> _thumbnailFilesFuture;
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();

  @override
  void initState() {
    super.initState();
    _thumbnailFilesFuture = _loadThumbnails();
  }

  Future<List<ImageModel>> _loadThumbnails() async {
    final directory = Directory('/storage/emulated/0/test');
    if (!await directory.exists()) {
      return [];
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
        final originalImage = img.decodeImage(await file.readAsBytes())!;
        final thumbnailImage = img.copyResize(originalImage, width: 200, height: 200);
        await thumbnailFile.writeAsBytes(Uint8List.fromList(img.encodeJpg(thumbnailImage)));
      }

      thumbnails.add(ImageModel(originalFile: file, thumbnailFile: thumbnailFile));
    }

    return thumbnails;
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
      body: FutureBuilder<List<ImageModel>>(
        future: _thumbnailFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                    fit: BoxFit.none,
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
