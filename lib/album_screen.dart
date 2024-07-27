import 'dart:io';

import 'package:flutter/material.dart';
import 'package:raja/image_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<File> imageFiles = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final directory = Directory('/storage/emulated/0/test');
    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<File> files = entities.whereType<File>().where((file) => file.path.toLowerCase().endsWith('.jpg')).toList();

    setState(() {
      imageFiles = files;
    });
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
      body: imageFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              // addAutomaticKeepAlives: false,
              // addRepaintBoundaries: false,
              // addSemanticIndexes: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
                childAspectRatio: 1 / 1,
              ),
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ImageScreen(imageFile: imageFiles[index])));
                  },
                  child: Image.file(
                    imageFiles[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
