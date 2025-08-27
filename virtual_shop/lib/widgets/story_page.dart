import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:async';

import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// No product model needed in story media view

// removed unused product detail import; story shows media only
// import 'package:virtual_shop/widgets/glass_container.dart';

Future<List<Color>> _generatePalette(ImageProvider imageProvider) async {
  final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
    imageProvider,
  );
  if (generator.dominantColor?.color != null) {
    return [generator.dominantColor!.color, const Color(0xFFFFFFFF)];
  } else {
    return [Colors.blue, Colors.white];
  }
}

class StoryMedia {
  final String url;
  final String? caption;
  final String? productId;
  const StoryMedia({required this.url, this.caption, this.productId});
}

class Person {
  final String name;
  final String profileImage;
  final List<StoryMedia> stories;
  const Person({
    required this.name,
    required this.profileImage,
    required this.stories,
  });
}

class Story extends StatefulWidget {
  const Story({super.key});

  @override
  State<Story> createState() => _StoryState();
}

class _StoryState extends State<Story> {
  final Map<String, List<Color>> _colorCache = {};
  List<Color> _allColors = [Colors.blue, Colors.white];
  List<Color> _textColors = [Colors.blue, Colors.white];
  List<Person> people = [];
  bool _loading = true;
  String? _error;
  final Map<String, String> _productNames = {}; // product_id -> name

  int selectedPersonIndex = 0;
  int selectedStoryIndex = 0;
  late String selectedImage;
  late String
  selectedName; // Displays under the story: product name > caption > user name
  late PageController _pageController;
  late PageController _personPageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _personPageController = PageController(viewportFraction: 0.25);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _personPageController.dispose();
    super.dispose();
  }

  Future<void> _precachePalettes() async {
    for (final person in people) {
      for (final s in person.stories) {
        if (!_colorCache.containsKey(s.url)) {
          final imageProvider = _netImageProvider(s.url);
          final colors = await _generatePalette(imageProvider);
          _colorCache[s.url] = colors;
        }
      }
    }
    if (mounted && selectedImage.isNotEmpty) {
      setState(() {
        final initialColors =
            _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
        _allColors = initialColors;
        _textColors = initialColors;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final stories = await _StoriesApi.fetchStories(limit: 100);
      // Group by user_auth_id preserving recency order
      final Map<String, List<Map<String, dynamic>>> byUser = {};
      for (final s in stories) {
        final uid = s['user_auth_id']?.toString() ?? '';
        if (uid.isEmpty) continue;
        byUser.putIfAbsent(uid, () => []).add(s);
      }
      final List<Person> persons = [];
      final Set<String> pids = {};
      for (final entry in byUser.entries) {
        final list = entry.value;
        // Keep order by created_at descending as returned by API
        final name = (list.first['user_name']?.toString() ?? '');
        final avatar = (list.first['user_avatar']?.toString() ?? '');
        final List<StoryMedia> mlist = [];
        for (final s in list) {
          final url = s['media_url']?.toString() ?? '';
          if (url.isEmpty) continue;
          final pid = s['product_id']?.toString();
          if (pid != null && pid.isNotEmpty) pids.add(pid);
          mlist.add(
            StoryMedia(
              url: url,
              caption: s['caption']?.toString(),
              productId: pid,
            ),
          );
        }
        if (mlist.isNotEmpty) {
          persons.add(
            Person(
              name: name.isNotEmpty ? name : '@user',
              profileImage: avatar,
              stories: mlist,
            ),
          );
        }
      }

      if (persons.isEmpty) {
        setState(() {
          _loading = false;
          people = [];
          selectedImage = '';
          selectedName = '';
        });
        return;
      }

      // Fetch product names for associated product_ids (once)
      if (pids.isNotEmpty) {
        try {
          final products = await _ProductsApi.fetchByIds(pids.toList());
          _productNames.clear();
          for (final p in products) {
            final id = p['id']?.toString();
            final name = p['name']?.toString();
            if (id != null &&
                name != null &&
                id.isNotEmpty &&
                name.isNotEmpty) {
              _productNames[id] = name;
            }
          }
        } catch (_) {
          // Ignore product fetch errors; we'll fallback to caption/user name
        }
      }

      selectedImage = persons[0].stories[0].url;
      selectedName = _labelFor(0, 0, persons);
      setState(() {
        people = persons;
        _loading = false;
      });
      await _precachePalettes();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _labelFor(int personIdx, int storyIdx, List<Person>? src) {
    final list = src ?? people;
    if (list.isEmpty || personIdx < 0 || personIdx >= list.length) {
      return '';
    }
    final person = list[personIdx];
    if (person.stories.isEmpty ||
        storyIdx < 0 ||
        storyIdx >= person.stories.length) {
      return person.name;
    }
    final s = person.stories[storyIdx];
    final pid = s.productId;
    if (pid != null && pid.isNotEmpty) {
      final name = _productNames[pid];
      if (name != null && name.isNotEmpty) return name;
    }
    if ((s.caption ?? '').isNotEmpty) return s.caption!;
    return person.name;
  }

  void updatePerson(int index) {
    setState(() {
      selectedPersonIndex = index;
      selectedStoryIndex = 0;
      selectedImage = people[index].stories[0].url;
      selectedName = _labelFor(index, 0, null);
      final newColors =
          _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
      _allColors = newColors;
      _textColors = newColors;
    });
    _pageController.jumpToPage(0);
  }

  void updateProduct(int index) {
    setState(() {
      selectedStoryIndex = index;
      selectedImage = people[selectedPersonIndex].stories[index].url;
      selectedName = _labelFor(selectedPersonIndex, index, null);
      final newColors =
          _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
      _allColors = newColors;
      _textColors = newColors;
    });
  }

  Future<void> _openProductForCurrent() async {
    final s = people[selectedPersonIndex].stories[selectedStoryIndex];
    final pid = s.productId;
    if (pid == null || pid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No product linked to this story')),
        );
      }
      return;
    }
    try {
      final data = await _ProductsApi.fetchOne(pid);
      final product = Product.fromJson(data);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: product),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Failed to load stories',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (people.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'No stories yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final Gradient titleGradient = LinearGradient(
      colors: _textColors.isNotEmpty
          ? _textColors
          : [Colors.blue, Colors.white],
    );
    final person = people[selectedPersonIndex];
    final stories = person.stories;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: _allColors.isNotEmpty
                    ? _allColors
                    : [Colors.blue, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds);
            },
            blendMode: BlendMode.modulate,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.network(
                selectedImage,
                key: ValueKey(selectedImage),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                headers: _headersForUrl(selectedImage),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: stories.length,
                    onPageChanged: (index) {
                      updateProduct(index);
                    },
                    itemBuilder: (context, index) {
                      final s = stories[index];
                      final heroTag = 'story_image_${s.url}';
                      return Hero(
                        tag: heroTag,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: _openProductForCurrent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                s.url,
                                fit: BoxFit.cover,
                                width: 180,
                                height: 180,
                                headers: _headersForUrl(s.url),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  selectedName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.04,
                    fontFamily: 'Poppins',
                    foreground: Paint()
                      ..shader = titleGradient.createShader(
                        const Rect.fromLTWH(0, 0, 200, 70),
                      ),
                  ),
                ),
                SizedBox(
                  height: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: List.generate(stories.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selectedStoryIndex == index ? 32 : 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _Avatar(url: person.profileImage, size: 40),
                  ),
                ),
                const SizedBox(height: 15),
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: PersonSelector(
              people: people,
              selectedIndex: selectedPersonIndex,
              onPersonSelected: updatePerson,
            ),
          ),
          Positioned(
            left: 10,
            right: 0,
            top: 30,
            child: Row(
              children: [
                _Avatar(url: person.profileImage, size: 40, radius: 20),
                const SizedBox(width: 20),
                Text(
                  person.name,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersonSelector extends StatelessWidget {
  final List<Person> people;
  final int selectedIndex;
  final void Function(int) onPersonSelected;

  const PersonSelector({
    super.key,
    required this.people,
    required this.selectedIndex,
    required this.onPersonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final person = people[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onPersonSelected(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: _Avatar(
                    url: person.profileImage,
                    size: (isSelected ? 54 : 50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final double size;
  final double? radius;
  const _Avatar({required this.url, required this.size, this.radius});

  @override
  Widget build(BuildContext context) {
    final isNet = url.startsWith('http://') || url.startsWith('https://');
    final headers = _headersForUrl(url);
    final w = size;
    final h = size;
    final child = isNet
        ? Image.network(
            url,
            width: w,
            height: h,
            fit: BoxFit.cover,
            headers: headers,
            errorBuilder: (context, error, stack) => const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile2.jpg'),
            ),
          )
        : Image.asset(
            url.isNotEmpty ? url : 'assets/images/profile2.jpg',
            width: w,
            height: h,
            fit: BoxFit.cover,
          );
    if (radius != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(child: child),
      );
    }
    return ClipOval(child: child);
  }
}

ImageProvider _netImageProvider(String src) {
  if (src.startsWith('http://') || src.startsWith('https://')) {
    // ImageProvider cannot directly take headers; acceptable for palette purposes
    return NetworkImage(src);
  }
  return AssetImage(src);
}

Map<String, String>? _headersForUrl(String url) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;
  if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }
  return null;
}

class _ApiBase {
  static String get baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          url = uri
              .replace(host: dotenv.env['hostIp'] ?? '192.168.0.154')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}

class _StoriesApi {
  static Future<List<Map<String, dynamic>>> fetchStories({
    int limit = 50,
  }) async {
    final resp = await http.get(_ApiBase.uri('/stories?limit=$limit'));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch stories: ${resp.statusCode} ${resp.body}',
      );
    }
    final List<dynamic> decoded = (() {
      try {
        return jsonDecode(resp.body) as List<dynamic>;
      } catch (_) {
        return <dynamic>[];
      }
    })();
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

// No products API needed for story media
class _ProductsApi {
  static Future<List<Map<String, dynamic>>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // dedupe while preserving order
    final seen = <String>{};
    final order = <String>[];
    for (final id in ids) {
      if (id.isEmpty) continue;
      if (seen.add(id)) order.add(id);
    }
    if (order.isEmpty) return [];
    final query = order.join(',');
    final uri = _ApiBase.uri('/products/by_ids?ids=$query');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch products: ${resp.statusCode} ${resp.body}',
      );
    }
    final List<dynamic> decoded = (() {
      try {
        return jsonDecode(resp.body) as List<dynamic>;
      } catch (_) {
        return <dynamic>[];
      }
    })();
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> fetchOne(String id) async {
    final resp = await http.get(_ApiBase.uri('/products/$id'));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch product: ${resp.statusCode} ${resp.body}',
      );
    }
    final dynamic decoded = (() {
      try {
        return jsonDecode(resp.body);
      } catch (_) {
        return {};
      }
    })();
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}
