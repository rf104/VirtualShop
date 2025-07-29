import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/designs/frosted_glass/frosted_glass.dart';

class ShopScreenshotsWidget extends StatefulWidget {
  const ShopScreenshotsWidget({super.key});

  @override
  State<ShopScreenshotsWidget> createState() => _ShopScreenshotsWidgetState();
}

class _ShopScreenshotsWidgetState extends State<ShopScreenshotsWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndEditImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final Uint8List imageBytes = await pickedFile.readAsBytes();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          imageBytes,

          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              String base64Image = base64Encode(editedBytes);
              print('Base64 image: ' + base64Image.substring(0, 100) + '...');
              Navigator.pop(context);
            },
          ),
          configs: ProImageEditorConfigs(
            designMode: platformDesignMode,
            theme: Theme.of(context).copyWith(
              iconTheme: Theme.of(
                context,
              ).iconTheme.copyWith(color: Colors.white),
            ),
            mainEditor: MainEditorConfigs(
              widgets: MainEditorWidgets(
                closeWarningDialog: (editor) async {
                  if (!context.mounted) return false;
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) =>
                            FrostedGlassCloseDialog(editor: editor),
                      ) ??
                      false;
                },
                appBar: (editor, rebuildStream) => null,
                bottomBar: (editor, rebuildStream, key) => null,
                bodyItems: _buildMainBodyWidgets,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStickerEditor(ProImageEditorState editor) async {
    Layer? layer = await editor.openPage(
      FrostedGlassStickerPage(
        configs: editor.configs,
        callbacks: editor.callbacks,
      ),
    );

    if (layer == null || !mounted) return;

    if (layer.runtimeType != WidgetLayer) {
      layer.scale = editor.configs.emojiEditor.initScale;
    }

    editor.addLayer(layer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: [
          const Text(
            'Shop Your Screenshots',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'UPLOAD YOUR PHOTOS TO FIND A STYLE MATCH',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndEditImage(ImageSource.camera),
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndEditImage(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Photos',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ReactiveWidget> _buildMainBodyWidgets(
    ProImageEditorState editor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      if (editor.selectedLayerIndex < 0)
        ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => FrostedGlassActionBar(
            editor: editor,
            openStickerEditor: () => _openStickerEditor(editor),
          ),
        ),
    ];
  }
}
