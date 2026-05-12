import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

// Main screen for the Pro Image Editor integration
class ImageEditorScreen extends StatelessWidget {
  final File? file;
  final Uint8List? memoryImage;

  const ImageEditorScreen({super.key, this.file, this.memoryImage}) 
      : assert(file != null || memoryImage != null, 'Must provide either file or memoryImage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: file != null 
          ? ProImageEditor.file(
              file!,
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (bytes) async {
                  // Pass the edited bytes back to previous screen
                  Navigator.pop(context, bytes);
                },
                onCloseEditor: (mode) => Navigator.pop(context),
              ),
            )
          : ProImageEditor.memory(
              memoryImage!,
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (bytes) async {
                  // Pass the edited bytes back to previous screen
                  Navigator.pop(context, bytes);
                },
                onCloseEditor: (mode) => Navigator.pop(context),
              ),
            ),
      ),
    );
  }
}
