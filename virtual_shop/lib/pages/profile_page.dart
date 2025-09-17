import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:palette_generator/palette_generator.dart';
// Removed virtual closet feature; replaced with liked products list
import 'package:virtual_shop/pages/liked_products_page.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/utils/like_service.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'edit_profile_final.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:virtual_shop/utils/story_like_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Color> _gradientColors = [const Color(0xFF8E9EAB), Colors.black];
  String? _profileImageUrl;
  ImageProvider? _profileImageProvider;
  PaletteGenerator? _cachedPalette;
  String? _lastPaletteKey;
  String _profileName = 'User';
  int? _age;
  int _storyLikers = 0;
  double _purchaseTotal = 0.0;
  int _purchaseCount = 0;
  List<Map<String, dynamic>> _myStories = [];
  bool _loadingStories = false;
  String? _storiesError;

  Map<String, String>? _headersForUrl(String url) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    // Add auth header for Supabase Storage private buckets
    if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
      return {'Authorization': 'Bearer ${session.accessToken}'};
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata ?? {};
        final dynamic candidate =
            meta['avatar_url_custom'] ?? meta['picture'] ?? meta['avatarUrl'];
        final dynamic nameCandidate = meta['name'] ?? meta['fullName'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          final url = candidate.trim();
          final provider = CachedNetworkImageProvider(
            url,
            maxHeight: 150,
            cacheKey: url,
            headers: _headersForUrl(url),
          );
          if (mounted) {
            setState(() {
              _profileImageUrl = url;
              _profileImageProvider = provider;
              _profileName = nameCandidate is String
                  ? nameCandidate.trim()
                  : 'User';
            });
          }
          precacheImage(provider, context).catchError((_) {});
        }
      }
    } catch (_) {
    } finally {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updatePalette();
          _fetchBackendProfile();
        }
      });
    }
  }

  String? _serverBase() {
    final envServer = dotenv.env['SERVER_URL'] ?? '';
    if (envServer.isEmpty) return null;
    var b = envServer.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  Future<void> _fetchBackendProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final base = _serverBase();
    if (base == null) return;
    // starting backend fetch
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final resp = await http.get(
        Uri.parse('$base/users/${user.id}'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (resp.statusCode >= 400) return;
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      setState(() {
        _age = map['age'] is int ? map['age'] as int : null;
        _storyLikers = (map['story_likes_total'] is int)
            ? map['story_likes_total'] as int
            : 0;
        if (map['purchase_total'] is num) {
          _purchaseTotal = (map['purchase_total'] as num).toDouble();
        }
        if (map['purchase_count'] is num) {
          _purchaseCount = (map['purchase_count'] as num).toInt();
        }
      });
      await _loadMyStories(user.id);
    } catch (_) {
    } finally {
      // no-op finalize
    }
  }

  Future<void> _loadMyStories(String userAuthId) async {
    setState(() {
      _loadingStories = true;
      _storiesError = null;
    });
    try {
      final stories = await StoryLikeService.userStories(userAuthId, limit: 24);
      if (mounted)
        setState(() {
          _myStories = stories;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _storiesError = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _loadingStories = false;
        });
    }
  }

  Future<void> _updatePalette() async {
    final currentKey = _profileImageUrl ?? 'asset:assets/images/profile2.jpg';
    if (_cachedPalette != null && _lastPaletteKey == currentKey) return;

    final ImageProvider provider =
        _profileImageProvider ??
        (_profileImageUrl != null
            ? CachedNetworkImageProvider(
                _profileImageUrl!,
                maxWidth: 150,
                maxHeight: 150,
                cacheKey: _profileImageUrl!,
                headers: _headersForUrl(_profileImageUrl!),
              )
            : const AssetImage('assets/images/profile2.jpg'));
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(200, 200),
        maximumColorCount: 8,
      );
      if (paletteGenerator.colors.length >= 2) {
        if (mounted) {
          setState(() {
            _gradientColors = [
              paletteGenerator.colors.elementAt(0),
              paletteGenerator.colors.elementAt(1),
            ];
            _cachedPalette = paletteGenerator;
            _lastPaletteKey = currentKey;
          });
        }
      } else if (paletteGenerator.colors.isNotEmpty) {
        if (mounted) {
          setState(() {
            _gradientColors = [paletteGenerator.colors.first, Colors.black];
            _cachedPalette = paletteGenerator;
            _lastPaletteKey = currentKey;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Frosted glass effect (clip for performance)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileInfo(context),
                const SizedBox(height: 30),
                _buildThreadsSection(),
                const SizedBox(height: 30),
                _buildLikedProductsSection(),
                const SizedBox(height: 30),
                _buildMyPostsSection(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Closet model

  // --- Liked products preview ---
  bool _loadingLikes = false;
  List<Product> _likedPreview = [];
  String? _likedError;

  Future<void> _loadLikedPreview() async {
    setState(() {
      _loadingLikes = true;
      _likedError = null;
    });
    try {
      final items = await LikeService.fetchLikedProducts();
      if (mounted)
        setState(() {
          _likedPreview = items.take(10).toList();
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _likedError = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _loadingLikes = false;
        });
    }
  }

  Widget _buildLikedProductsSection() {
    // Load lazily after first frame to avoid jank
    if (_likedPreview.isEmpty && !_loadingLikes && _likedError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLikedPreview();
      });
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Liked Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LikedProductsPage(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: _loadingLikes
                ? const Center(child: CircularProgressIndicator())
                : _likedError != null
                ? Center(
                    child: Text(
                      _likedError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _likedPreview.isEmpty
                ? Center(
                    child: Text(
                      'No likes yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _likedPreview.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final p = _likedPreview[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: p),
                          ),
                        ),
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image(
                                  image: p.image.startsWith('http')
                                      ? NetworkImage(p.image) as ImageProvider
                                      : AssetImage(p.image),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '৳${p.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Stories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_loadingStories) const Center(child: CircularProgressIndicator()),
          if (!_loadingStories && _storiesError != null)
            Text(
              _storiesError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          if (!_loadingStories && _storiesError == null && _myStories.isEmpty)
            Text('No stories yet', style: TextStyle(color: Colors.white70)),
          if (_myStories.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _myStories.length,
              itemBuilder: (context, index) {
                final story = _myStories[index];
                final url = (story['media_url'] as String?) ?? '';
                final likeCount = story['like_count'] ?? 0;
                final isNet = url.startsWith('http');
                final img = isNet
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/profile2.jpg',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/profile2.jpg',
                        fit: BoxFit.cover,
                      );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: img,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$likeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: _profileImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: _profileImageUrl!,
                  httpHeaders: _headersForUrl(_profileImageUrl!) ?? const {},
                  imageBuilder: (context, imageProvider) => Image(
                    image: imageProvider,
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                  placeholder: (context, url) => Image.asset(
                    'assets/images/profile2.jpg',
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/profile2.jpg',
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                  fadeInDuration: const Duration(milliseconds: 150),
                  memCacheWidth: 800,
                  memCacheHeight: 800,
                  maxWidthDiskCache: 1024,
                  maxHeightDiskCache: 1024,
                )
              : Image.asset(
                  'assets/images/profile2.jpg',
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(height: 10),
        // const Text('24.978 Followers', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Text(
          _profileName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                // Wait for result from edit dialog
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const EditProfileFinal(),
                  barrierDismissible: false,
                );

                // If edit was successful, reload profile
                if (result == true) {
                  await _loadUserProfile();
                }
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _handleSignOut(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildThreadsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  'Purchases',
                  _purchaseCount == 0 ? '—' : _purchaseCount.toString(),
                ),
                _buildStatCard('Age', _age != null ? '${_age} y.o' : '—'),
                _buildStatCard('Story Likes', _storyLikers.toString()),
                _buildStatCard(
                  'Spent',
                  _purchaseTotal == 0 ? '—' : _purchaseTotal.toStringAsFixed(0),
                ),
                _buildStatCard('Stories', _myStories.length.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return SizedBox(
      width: 120,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      // Return to root so AuthGate renders signedOut UI
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }
}
