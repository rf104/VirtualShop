import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/designs/frosted_glass/frosted_glass.dart';
import 'package:virtual_shop/utils/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_ai/firebase_ai.dart';

// Custom widget for virtual try-on image picking
class VirtualTryOnImagePicker extends StatefulWidget {
  final Function(Uint8List imageBytes) onImagePicked;

  const VirtualTryOnImagePicker({super.key, required this.onImagePicked});

  @override
  State<VirtualTryOnImagePicker> createState() =>
      _VirtualTryOnImagePickerState();
}

class _VirtualTryOnImagePickerState extends State<VirtualTryOnImagePicker> {
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
              widget.onImagePicked(editedBytes);
              Navigator.of(context, rootNavigator: true).pop();
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
            'Virtual Try-On',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'UPLOAD YOUR PHOTO TO TRY ON THIS PRODUCT',
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

class VirtualTryOnPage extends StatefulWidget {
  final String productImage;
  final String productName;
  final String productId;
  const VirtualTryOnPage({
    super.key,
    required this.productImage,
    required this.productName,
    required this.productId,
  });

  @override
  State<VirtualTryOnPage> createState() => _VirtualTryOnPageState();
}

class _VirtualTryOnPageState extends State<VirtualTryOnPage> {
  // Helper to try Segmind IDM VTON API with all keys
  Future<Uint8List?> _trySegmindVTON({
    required Uint8List userImageBytes,
    required Uint8List productImageBytes,
    String garmentDescription = 'Green colour semi Formal Blazer',
  }) async {
    final List<String?> apiKeys = [
      dotenv.env['SEGMIND_API_KEY_1'],
      dotenv.env['SEGMIND_API_KEY_2'],
      dotenv.env['SEGMIND_API_KEY_3'],
    ];
    // Segmind accepts public URLs or inline data URIs; use inline for reliability
    final String userBase64 = base64Encode(userImageBytes);
    final String productBase64 = base64Encode(productImageBytes);
    final String userDataUri = 'data:image/jpeg;base64,$userBase64';
    final String productDataUri = 'data:image/jpeg;base64,$productBase64';

    final Map<String, dynamic> payload = {
      'crop': false,
      'seed': 42,
      'steps': 30,
      'category': 'dresses',
      'force_dc': false,
      'human_img': userDataUri,
      'garm_img': productDataUri,
      'mask_only': false,
      'garment_des': garmentDescription,
    };
    Exception? lastError;
    for (final key in apiKeys) {
      if (key == null || key.isEmpty) continue;
      try {
        final response = await http.post(
          Uri.parse('https://api.segmind.com/v1/idm-vton'),
          headers: {'x-api-key': key, 'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          // Segmind returns image/jpeg directly
          return response.bodyBytes;
        } else {
          lastError = Exception(
            'Segmind error: ${response.statusCode} ${response.body}',
          );
        }
      } catch (e) {
        lastError = Exception('Segmind exception: $e');
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  // Helper to try LightX AI Virtual Try-On API
  Future<Uint8List?> _tryLightXVirtualTryOn({
    required Uint8List userImageBytes,
    required Uint8List productImageBytes,
    required String garmentName,
    required String currentMainImagePath,
  }) async {
    try {
      final String? apiKey = dotenv.env['LIGHTX_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('LightX: API key missing, skipping.');
        return null;
      }

      // Ensure remote URLs (upload to Supabase if local asset)
      Future<String> ensureRemoteUrl(String name, Uint8List bytes) async {
        if (name.startsWith('http://') || name.startsWith('https://'))
          return name;
        return await SupabaseService.uploadProfileImageBytes(
          bytes: bytes,
          filename: name.split('/').isNotEmpty
              ? name.split('/').last
              : 'image.jpg',
          mimeType: 'image/jpeg',
        );
      }

      final garmentUrl = await ensureRemoteUrl(
        currentMainImagePath,
        productImageBytes,
      );
      // Always upload user image (not an asset path but raw bytes)
      final userUrl = await SupabaseService.uploadProfileImageBytes(
        bytes: userImageBytes,
        filename: 'user_vton_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );

      // Submit job
      final submitResp = await http.post(
        Uri.parse(
          'https://api.lightxeditor.com/external/api/v2/aivirtualtryon',
        ),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: jsonEncode({
          'imageUrl': userUrl, // person image
          // LightX expects styleImageUrl to be garment/product image
          'styleImageUrl': garmentUrl,
        }),
      );

      if (submitResp.statusCode != 200) {
        debugPrint(
          'LightX submit failed: ${submitResp.statusCode} ${submitResp.body}',
        );
        return null;
      }
      Map<String, dynamic> submitJson;
      try {
        submitJson = jsonDecode(submitResp.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('LightX submit decode failed: $e');
        return null;
      }
      final body = submitJson['body'] as Map<String, dynamic>?;
      final orderId = body != null ? body['orderId']?.toString() : null;
      if (orderId == null || orderId.isEmpty) {
        debugPrint('LightX: No orderId returned.');
        return null;
      }
      final int maxRetriesAllowed = (body?['maxRetriesAllowed'] is int)
          ? body!['maxRetriesAllowed'] as int
          : 8;
      final int avgResponseTimeInSec = (body?['avgResponseTimeInSec'] is int)
          ? body!['avgResponseTimeInSec'] as int
          : 20;

      // Poll order status
      final Uri statusUri = Uri.parse(
        'https://api.lightxeditor.com/external/api/v2/order-status',
      );
      Uint8List? finalBytes;
      for (int attempt = 0; attempt < maxRetriesAllowed; attempt++) {
        await Future.delayed(
          Duration(
            seconds: attempt == 0 ? 2 : math.min(avgResponseTimeInSec, 25),
          ),
        );
        final statusResp = await http.post(
          statusUri,
          headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
          body: jsonEncode({'orderId': orderId}),
        );
        if (statusResp.statusCode != 200) {
          debugPrint(
            'LightX status check failed: ${statusResp.statusCode} ${statusResp.body}',
          );
          continue;
        }
        Map<String, dynamic> statusJson;
        try {
          statusJson = jsonDecode(statusResp.body) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('LightX status decode failed: $e');
          continue;
        }
        final sBody = statusJson['body'] as Map<String, dynamic>?;
        final status = sBody != null ? sBody['status']?.toString() : null;
        if (status == null) continue;
        debugPrint('LightX order $orderId status: $status');
        if (status.toLowerCase() == 'active') {
          final outputUrl = sBody?['output']?.toString();
          if (outputUrl != null && outputUrl.startsWith('http')) {
            final outResp = await http.get(Uri.parse(outputUrl));
            if (outResp.statusCode == 200 && outResp.bodyBytes.isNotEmpty) {
              finalBytes = outResp.bodyBytes;
              break;
            }
          }
          break;
        } else if (status.toLowerCase() == 'failed' ||
            status.toLowerCase() == 'error') {
          debugPrint('LightX order failed.');
          break;
        }
      }
      return finalBytes;
    } catch (e) {
      debugPrint('LightX try-on exception: $e');
      return null;
    }
  }

  late final List<Map<String, String>> _productViewsWithSizes;
  late String _currentMainImage;
  int _selectedThumbnailIndex = 0;
  bool _isLoadingImages = false;
  String? _imagesError;

  Uint8List? _userImage;
  Uint8List? _virtualTryOnImage;
  String? _error;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _productViewsWithSizes = [];
    _currentMainImage = widget.productImage;
    _fetchProductImages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTryOnHint());
  }

  Future<void> _fetchProductImages() async {
    setState(() {
      _isLoadingImages = true;
      _imagesError = null;
    });
    try {
      final rows = await supabase
          .from('product_images')
          .select('image_url, Tag, created_at')
          .eq('product_id', widget.productId)
          .order('created_at', ascending: true);
      final List<Map<String, String>> items = [];
      for (final r in rows) {
        final url = (r['image_url'] ?? '').toString();
        if (url.isEmpty) continue;
        final tag = (r['Tag'] ?? '').toString();
        items.add({'image': url, 'size': tag});
      }
      if (mounted) {
        setState(() {
          _productViewsWithSizes
            ..clear()
            ..addAll(items);
          // If current image isn't among fetched, prefer first fetched
          if (_productViewsWithSizes.isNotEmpty) {
            final idx = _productViewsWithSizes.indexWhere(
              (e) => e['image'] == _currentMainImage,
            );
            if (idx >= 0) {
              _selectedThumbnailIndex = idx;
            } else {
              _selectedThumbnailIndex = 0;
              _currentMainImage = _productViewsWithSizes[0]['image']!;
            }
          }
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imagesError = e.toString();
          _isLoadingImages = false;
        });
      }
    }
  }

  void _cycleMainImage() {
    debugPrint(_productViewsWithSizes.length.toString());
    if (_productViewsWithSizes.length < 2) return;
    setState(() {
      _selectedThumbnailIndex =
          (_selectedThumbnailIndex + 1) % _productViewsWithSizes.length;
      _currentMainImage =
          _productViewsWithSizes[_selectedThumbnailIndex]['image']!;
    });
  }

  void _onThumbnailTapped(int index) {
    setState(() {
      _selectedThumbnailIndex = index;
      _currentMainImage = _productViewsWithSizes[index]['image']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Try-On with AI (Gemini) — tap to start',
              child: TextButton.icon(
                onPressed: _onGeminiPressed,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 36),
                ),
                icon: Icon(Symbols.auto_awesome, color: Colors.amberAccent),
                label: const Text(
                  'Try-On AI',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isGenerating) const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 20),
          if (_userImage != null &&
              (_isGenerating || _virtualTryOnImage != null || _error != null))
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.98,
                          end: 1.0,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                  child: _isGenerating
                      ? GlowingBorderImage(
                          key: ValueKey('loading_${_userImage?.hashCode ?? 0}'),
                          imageBytes: _userImage!,
                        )
                      : _error != null
                      ? Column(
                          key: const ValueKey('error'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (_userImage != null) {
                                  _generateVirtualTryOn(_userImage!);
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : _virtualTryOnImage != null
                      ? Builder(
                          builder: (context) {
                            final double logicalW = MediaQuery.of(
                              context,
                            ).size.width;
                            final int cacheW =
                                (logicalW *
                                        MediaQuery.of(context).devicePixelRatio)
                                    .round();
                            return Image.memory(
                              _virtualTryOnImage!,
                              key: ValueKey(
                                'done_${_virtualTryOnImage!.hashCode}',
                              ),
                              fit: BoxFit.contain,
                              cacheWidth: cacheW,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            )
          else
            Expanded(flex: 5, child: Center(child: _buildMainProductImage())),
          const SizedBox(height: 20),
          if (_userImage == null)
            GestureDetector(
              onTap: _cycleMainImage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: const Icon(Icons.threesixty, color: Colors.black),
              ),
            ),
          if (_userImage == null) ...[
            const SizedBox(height: 20),
            if (_isLoadingImages)
              const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_imagesError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _imagesError!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_productViewsWithSizes.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productViewsWithSizes.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedThumbnailIndex == index;
                    final sizeLabel =
                        _productViewsWithSizes[index]['size'] ?? '';
                    final imageUrl = _productViewsWithSizes[index]['image']!;
                    return GestureDetector(
                      onTap: () => _onThumbnailTapped(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildThumb(imageUrl),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sizeLabel.isNotEmpty
                                  ? 'Size: $sizeLabel'
                                  : 'Variant ${index + 1}',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.yellow
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Future<void> _maybeShowTryOnHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'vton_tryon_hint_shown';
      if (prefs.getBool(key) == true) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tip: Tap "Try-On AI" to upload your photo'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Try-On', onPressed: _onGeminiPressed),
        ),
      );
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  Widget _buildThumb(String src) {
    final isNet = src.startsWith('http://') || src.startsWith('https://');
    if (isNet) {
      final double logicalSize = 70; // matches container size
      final double px = logicalSize * MediaQuery.of(context).devicePixelRatio;
      final int? cacheW = (px.isFinite && px > 0) ? px.round() : null;
      return CachedNetworkImage(
        imageUrl: src,
        fit: BoxFit.cover,
        memCacheWidth: cacheW,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      cacheWidth: (() {
        final px = 70 * MediaQuery.of(context).devicePixelRatio;
        return (px.isFinite && px > 0) ? px.round() : null;
      })(),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  Widget _buildMainProductImage() {
    final src = _currentMainImage;
    final isNet = src.startsWith('http://') || src.startsWith('https://');
    if (isNet) {
      final double logicalW = MediaQuery.of(context).size.width;
      final double px = logicalW * MediaQuery.of(context).devicePixelRatio;
      final int? cacheW = (px.isFinite && px > 0) ? px.round() : null;
      return CachedNetworkImage(
        imageUrl: src,
        fit: BoxFit.contain,
        memCacheWidth: cacheW,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => const Text(
          'Could not load image',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.contain,
      cacheWidth: (() {
        final px =
            MediaQuery.of(context).size.width *
            MediaQuery.of(context).devicePixelRatio;
        return (px.isFinite && px > 0) ? px.round() : null;
      })(),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const Text(
        'Could not load image asset',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  void _onGeminiPressed() async {
    // Immediate feedback that the try-on flow is starting
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Try-On: upload or capture a photo to begin'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: VirtualTryOnImagePicker(
                onImagePicked: (Uint8List imageBytes) {
                  setState(() {
                    _userImage = imageBytes;
                    _virtualTryOnImage = null;
                    _error = null;
                  });
                  _generateVirtualTryOn(imageBytes);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateVirtualTryOn(Uint8List userImageBytes) async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _virtualTryOnImage = null;
    });
    // Brief status cue while contacting providers
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compositing with AI… This can take ~20 seconds'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
    try {
      // Load selected product image (asset or network) as bytes
      final Uint8List productImageBytes = await _loadImageBytes(
        _currentMainImage,
      );
      // Try Gemini first
      try {
        final String productBase64 = base64Encode(productImageBytes);
        final String userBase64 = base64Encode(userImageBytes);

        // System instruction: drive the model towards a single composite image output.
        final Map<String, dynamic> payload = {
          "systemInstruction": {
            "parts": [
              {
                "text":
                    "You are a virtual try-on compositor. Your task is to make the person in the user image wear the garment from the product image. Requirements:\n"
                    "- Output exactly one image. No text or captions.\n"
                    "- Keep the person's identity, skin tone, pose, body shape, and original background intact unless occluded by the garment.\n"
                    "- Align and fit the garment naturally to the body, respecting perspective, wrinkles, and lighting; preserve garment colors, logos, and textures.\n"
                    "- Avoid adding or removing unrelated accessories. Avoid artifacts and hallucinations.\n"
                    "- If parts are occluded, blend realistically. If needed, slightly adjust garment to fit but do not change its design.",
              },
            ],
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "Here is the product image:"},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": productBase64,
                  },
                },
              ],
            },
            {
              "role": "model",
              "parts": [
                {"text": "Understood, I have the product image."},
              ],
            },
            {
              "role": "user",
              "parts": [
                {"text": "Here is the person image:"},
                {
                  "inlineData": {"mimeType": "image/jpeg", "data": userBase64},
                },
              ],
            },
            {
              "role": "model",
              "parts": [
                {"text": "Understood, I have the person image."},
              ],
            },
            {
              "role": "user",
              "parts": [
                {
                  "text":
                      "Detailed instructions: Compose a single, realistic try-on image showing the person wearing the garment. Respond with the image only. Make sure that the person is wearing the garment correctly.",
                },
              ],
            },
            {
              "role": "model",
              "parts": [
                {"text": "Acknowledged, ready to proceed."},
              ],
            },
            {
              "role": "user",
              "parts": [
                {"text": "Do it then"},
              ],
            },
          ],
          "generationConfig": {
            "responseModalities": ["IMAGE"],
            "temperature": 0.5,
            "topP": 0.9,
            "topK": 32,
            "candidateCount": 1,
          },
        };

        final String? apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('GEMINI_API_KEY not set in environment or .env');
        }
        final response = await http.post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:streamGenerateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (response.statusCode != 200) {
          throw Exception('API error: ${response.statusCode} ${response.body}');
        }
        // More robust parsing: accept image/png and image/jpeg, and both inlineData/inline_data keys.
        String? imageBase64;
        String? _extractImageB64FromParts(dynamic parts) {
          for (final part in parts) {
            final inline = part['inlineData'] ?? part['inline_data'];
            if (inline != null) {
              final mime = (inline['mimeType'] ?? inline['mime_type'])
                  ?.toString();
              if (mime == 'image/png' || mime == 'image/jpeg') {
                final data = inline['data']?.toString();
                if (data != null && data.isNotEmpty) return data;
              }
            }
          }
          return null;
        }

        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('[') && trimmedBody.endsWith(']')) {
          try {
            final List<dynamic> arr = jsonDecode(trimmedBody);
            for (final jsonLine in arr) {
              final candidates = jsonLine['candidates'] ?? [];
              for (final candidate in candidates) {
                final parts = candidate['content']?['parts'] ?? [];
                imageBase64 = _extractImageB64FromParts(parts);
                if (imageBase64 != null) break;
              }
              if (imageBase64 != null) break;
            }
          } catch (e) {
            throw Exception('Failed to parse JSON array response: $e');
          }
        } else {
          final lines = response.body.split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty ||
                !trimmed.startsWith('{') ||
                !trimmed.endsWith('}')) {
              continue;
            }
            try {
              final Map<String, dynamic> jsonLine = jsonDecode(trimmed);
              final candidates = jsonLine['candidates'] ?? [];
              for (final candidate in candidates) {
                final parts = candidate['content']?['parts'] ?? [];
                imageBase64 = _extractImageB64FromParts(parts);
                if (imageBase64 != null) break;
              }
              if (imageBase64 != null) break;
            } catch (_) {
              continue;
            }
          }
        }

        if (imageBase64 == null) {
          throw Exception('No image found in response.');
        }
        final Uint8List resultImage = base64Decode(imageBase64);
        setState(() {
          _virtualTryOnImage = resultImage;
          _isGenerating = false;
          _error = null;
        });
        debugPrint('Gemini generation succeeded.');
        return;
      } catch (e) {
        debugPrint('Gemini generation failed: $e');
      }

      // Next: try server /process_image (Ayna-1.0 via Gradio)
      // Before server fallback, try LightX API
      try {
        final Uint8List? lightXResult = await _tryLightXVirtualTryOn(
          userImageBytes: userImageBytes,
          productImageBytes: productImageBytes,
          garmentName: widget.productName,
          currentMainImagePath: _currentMainImage,
        );
        if (lightXResult != null) {
          setState(() {
            _virtualTryOnImage = lightXResult;
            _isGenerating = false;
            _error = null;
          });
          debugPrint('LightX generation succeeded.');
          return;
        }
      } catch (e) {
        debugPrint('LightX generation failed: $e');
      }

      // Next fallback: server /process_image (Ayna-1.0 via Gradio)
      try {
        final String baseUrl = (() {
          final s = dotenv.env['SERVER_URL']?.trim();
          final b = dotenv.env['BACKEND_URL']?.trim();
          String raw = (s != null && s.isNotEmpty)
              ? s
              : ((b != null && b.isNotEmpty) ? b : 'http://127.0.0.1:8000');
          raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
          String url = raw.endsWith('/')
              ? raw.substring(0, raw.length - 1)
              : raw;
          try {
            if (!kIsWeb && Platform.isAndroid) {
              final uri = Uri.parse(url);
              if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
                url = uri
                    .replace(host: dotenv.env['hostIp'] ?? '10.103.137.37')
                    .toString();
              }
            }
          } catch (_) {}
          return url;
        })();

        Future<String> _ensureUrl(String name, Uint8List bytes) async {
          if (name.startsWith('http://') || name.startsWith('https://'))
            return name;
          final url = await SupabaseService.uploadProfileImageBytes(
            bytes: bytes,
            filename: name.split('/').isNotEmpty
                ? name.split('/').last
                : 'image.jpg',
            mimeType: 'image/jpeg',
          );
          return url;
        }

        final garmentUrl = await _ensureUrl(
          _currentMainImage,
          productImageBytes,
        );
        final personUrl = await _ensureUrl('user-photo.jpg', userImageBytes);
        final uri = Uri.parse('$baseUrl/process_image');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            // Updated parameters per new /process_image API
            'garment_img_url': garmentUrl,
            'person_img_url': personUrl,
            // Short textual description used by model; fall back to product name
            'garment_des': widget.productName.isNotEmpty
                ? widget.productName
                : 'garment',
            // Keep defaults explicit for clarity / future tuning
            'is_checked': true,
            'is_checked_crop': false,
            'denoise_steps': 30,
            'seed': 42,
          }),
        );
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          String? url = data['url'] as String?;
          String? dataUri = data['data_uri'] as String?;
          if (url != null && url.isNotEmpty) {
            final got = await http.get(Uri.parse(url));
            if (got.statusCode == 200 && got.bodyBytes.isNotEmpty) {
              setState(() {
                _virtualTryOnImage = got.bodyBytes;
                _isGenerating = false;
                _error = null;
              });
              return;
            }
          } else if (dataUri != null && dataUri.startsWith('data:')) {
            try {
              final b64 = dataUri.split(',').last;
              final img = base64Decode(b64);
              setState(() {
                _virtualTryOnImage = img;
                _isGenerating = false;
                _error = null;
              });
              return;
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Server /process_image failed: $e');
      }

      // Finally: Segmind
      try {
        final Uint8List? segmindResult = await _trySegmindVTON(
          userImageBytes: userImageBytes,
          productImageBytes: productImageBytes,
          garmentDescription: widget.productName,
        );
        if (segmindResult != null) {
          setState(() {
            _virtualTryOnImage = segmindResult;
            _isGenerating = false;
            _error = null;
          });
          return;
        }
      } catch (e) {
        debugPrint('Segmind failed: $e');
      }

      // If we reach here, all providers failed
      setState(() {
        _error =
            'Failed to generate virtual try-on image using Gemini, server, and Segmind.';
        _isGenerating = false;
      });
      return;
    } catch (e) {
      setState(() {
        _error = 'Failed to generate virtual try-on image. ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  Future<Uint8List> _loadImageBytes(String src) async {
    try {
      if (src.startsWith('http://') || src.startsWith('https://')) {
        final resp = await http.get(Uri.parse(src));
        if (resp.statusCode == 200) return resp.bodyBytes;
        throw Exception('HTTP ${resp.statusCode}');
      }
      final data = await rootBundle.load(src);
      return data.buffer.asUint8List();
    } catch (e) {
      throw Exception('Load image failed: $e');
    }
  }
}

/// Displays a square image with an animated glowing gradient border while loading.
class GlowingBorderImage extends StatefulWidget {
  final Uint8List imageBytes;
  final double borderWidth;
  final double borderRadius;
  final double maxSize;

  const GlowingBorderImage({
    super.key,
    required this.imageBytes,
    this.borderWidth = 6,
    this.borderRadius = 20,
    this.maxSize = 420,
  });

  @override
  State<GlowingBorderImage> createState() => _GlowingBorderImageState();
}

class _GlowingBorderImageState extends State<GlowingBorderImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxSize,
          maxHeight: widget.maxSize,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final angle = _controller.value * 2 * math.pi;
              final glowT =
                  (math.sin(_controller.value * 2 * math.pi) + 1) / 2; // 0..1
              final borderRadius = BorderRadius.circular(widget.borderRadius);
              final colors = [
                Colors.pinkAccent,
                Colors.amber,
                Colors.cyanAccent,
                Colors.purpleAccent,
                Colors.pinkAccent,
              ];
              return Container(
                decoration: BoxDecoration(
                  // Outer subtle glow
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(
                        0.35 + 0.25 * glowT,
                      ),
                      blurRadius: 24 + 24 * glowT,
                      spreadRadius: 1 + 2 * glowT,
                    ),
                  ],
                  borderRadius: borderRadius,
                  gradient: SweepGradient(
                    colors: colors,
                    transform: GradientRotation(angle),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.borderWidth),
                  child: ClipRRect(
                    borderRadius: borderRadius.subtract(
                      BorderRadius.all(Radius.circular(widget.borderWidth)),
                    ),
                    child: Container(
                      color: Colors.black,
                      child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
