import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'export_settings_screen.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> picked = await _picker.pickMultiImage();
        if (picked.isNotEmpty) {
          setState(() {
            _images.addAll(picked.map((x) => File(x.path)));
          });
        }
      } else {
        final XFile? picked = await _picker.pickImage(source: source);
        if (picked != null) {
          setState(() {
            _images.add(File(picked.path));
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _cropImage(int index) async {
    final appColors = Theme.of(context).appColors;
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _images[index].path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: appColors.primary!,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _images[index] = File(croppedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // String _formatBytes(int bytes) {
  //   if (bytes < 1024) return '$bytes B';
  //   if (bytes < 1024 * 1024) {
  //     return '${(bytes / 1024).toStringAsFixed(1)} KB';
  //   }
  //   return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  // }

  // int _getTotalBytes() {
  //   int total = 0;
  //   for (final file in _images) {
  //     try {
  //       total += file.lengthSync();
  //     } catch (_) {}
  //   }
  //   return total;
  // }

  void _continueToExport() async {
    if (_images.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExportSettingsScreen(images: _images)),
    );
  }

  void _showImagePickerOptions() {
    final appColors = Theme.of(context).appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Images From',
                style: TextStyle(
                  color: appColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      color: appColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Select multiple photos from gallery',
                    style: TextStyle(color: appColors.subtitle, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.gallery);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      color: appColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Capture new photo using camera',
                    style: TextStyle(color: appColors.subtitle, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.camera);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSection(AppColors appColors) {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _showImagePickerOptions,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Images to Convert',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to choose from gallery or capture photos',
                style: TextStyle(color: appColors.subtitle, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }

    // final totalBytes = _getTotalBytes();
    // final sizeStr = _formatBytes(totalBytes);

    // return Container(
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: appColors.surface,
    //     borderRadius: BorderRadius.circular(20),
    //     border: Border.all(color: appColors.divider ?? Colors.grey.shade200),
    //   ),
    //   child: Row(
    //     children: [
    //       Container(
    //         padding: const EdgeInsets.all(12),
    //         decoration: BoxDecoration(
    //           color: Colors.blueAccent.withValues(alpha: 0.1),
    //           borderRadius: BorderRadius.circular(14),
    //         ),
    //         child: const Icon(
    //           Icons.collections_rounded,
    //           color: Colors.blueAccent,
    //           size: 28,
    //         ),
    //       ),
    //       const SizedBox(width: 14),
    //       Expanded(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Text(
    //               '${_images.length} ${_images.length == 1 ? "Image" : "Images"} Selected',
    //               style: TextStyle(
    //                 color: appColors.text,
    //                 fontWeight: FontWeight.bold,
    //                 fontSize: 15,
    //               ),
    //               maxLines: 1,
    //               overflow: TextOverflow.ellipsis,
    //             ),
    //             const SizedBox(height: 4),
    //             Text(
    //               'Total: $sizeStr',
    //               style: TextStyle(color: appColors.subtitle, fontSize: 13),
    //             ),
    //           ],
    //         ),
    //       ),
    //       TextButton.icon(
    //         onPressed: _showImagePickerOptions,
    //         icon: const Icon(Icons.add, size: 18),
    //         label: const Text('Add More'),
    //         style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
    //       ),
    //     ],
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        title: Text(
          'Image to PDF',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: appColors.text),
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Add Images',
              onPressed: _showImagePickerOptions,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 6.0),
              child: _buildFileSection(appColors),
            ),
            if (_images.isEmpty)
              //ad here
              SizedBox.shrink()
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reorder & Edit (${_images.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: appColors.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 13,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'HOLD TO REORDER',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ReorderableGridView.builder(
                    itemCount: _images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final element = _images.removeAt(oldIndex);
                        _images.insert(newIndex, element);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Stack(
                        key: ValueKey(_images[index].path),
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => _cropImage(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                              radius: 14,
                              child: const Icon(
                                Icons.drag_indicator,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                                radius: 14,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Image ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border.all(
                    color: appColors.divider ?? Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_images.length} Images Selected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: appColors.text,
                              ),
                            ),
                            Text(
                              'Ready to convert',
                              style: TextStyle(
                                color: appColors.subtitle,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _continueToExport,
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Convert to PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
