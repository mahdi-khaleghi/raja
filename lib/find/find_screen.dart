import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FindScreen extends StatefulWidget {
  final ui.Image faceImage;

  const FindScreen({super.key, required this.faceImage});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 64),
              SizedBox(
                width: 64,
                height: 64,
                child: ClipOval(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: widget.faceImage.width.toDouble(),
                        height: widget.faceImage.height.toDouble(),
                        child: RawImage(image: widget.faceImage),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      TextEditingController nameController = TextEditingController();

                      return AlertDialog(
                        title: const Text('Enter name'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(hintText: "Name"),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              setState(() {
                                _name = nameController.text;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text((_name == '') ? 'Add Name' : _name, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 4),
              const Text('Specify a name to include in all photos!', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
