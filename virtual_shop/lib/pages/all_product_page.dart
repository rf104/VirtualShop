import 'dart:async';
import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:virtual_shop/utils/product_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllProductPage extends StatefulWidget {
  const AllProductPage({super.key});

  @override
  State<AllProductPage> createState() => _AllProductPageState();
}

class _AllProductPageState extends State<AllProductPage> {
  List<Product> _products = const [];
  String _query = '';
  bool _loading = true;
  String? _error;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  String? _searchError;
  List<Product> _vectorResults = const [];
  String _sort = 'relevance'; // relevance | price_asc | price_desc

  // Cached vocab for suggestions
  Set<String> _knownCategories = {};
  static const List<String> _knownColors = [
    'black',
    'white',
    'red',
    'green',
    'blue',
    'yellow',
    'orange',
    'purple',
    'pink',
    'brown',
    'gray',
    'grey',
    'beige',
    'maroon',
    'navy',
    'teal',
  ];

  // Facet suggestions from backend
  List<Map<String, dynamic>> _facets = const [];
  String? _primaryFacet;

  // Filter chip placeholders removed for now

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ProductRepository.fetchAll();
      setState(() {
        _products = items;
        _loading = false;
        _knownCategories = items.map((e) => e.category.toLowerCase()).toSet();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onQueryChanged(String v) {
    final q = v.trim();
    setState(() {
      _query = q;
      _searchError = null;
    });
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() {
        _vectorResults = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _performVectorSearch);
  }

  Future<void> _performVectorSearch() async {
    if (_query.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final res = await ProductRepository.searchVector(_query, limit: 48);
      setState(() {
        _vectorResults = res;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      endDrawer: _buildEndDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              // const SizedBox(height: 20),
              // _buildFilterChips(),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Shop',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [_buildHeaderButton('Items', _products.length.toString())],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 5),
          Text(
            count,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onQueryChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _performVectorSearch(),
      decoration: InputDecoration(
        hintText: 'Type to search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Suggestions',
          icon: const Icon(Icons.tune),
          onPressed: () async {
            if (_query.isNotEmpty) {
              try {
                final s = await ProductRepository.suggestTokens(_query);
                final rawFacets = (s['facets'] as List?) ?? const [];
                final parsed = <Map<String, dynamic>>[];
                for (final f in rawFacets) {
                  if (f is Map) {
                    final title = f['title']?.toString() ?? '';
                    final optsDyn = f['options'];
                    final opts = <String>[];
                    if (optsDyn is List) {
                      for (final o in optsDyn) {
                        final s = o?.toString().trim();
                        if (s != null && s.isNotEmpty) opts.add(s);
                      }
                    }
                    if (title.isNotEmpty && opts.isNotEmpty) {
                      parsed.add({'title': title, 'options': opts});
                    }
                  }
                }
                setState(() {
                  _primaryFacet = s['primary']?.toString();
                  _facets = parsed;
                  if (_primaryFacet != null && _primaryFacet!.isNotEmpty) {
                    _knownCategories.add(_primaryFacet!.toLowerCase());
                  }
                });
              } catch (_) {
                // Ignore suggestion failures; drawer will fall back
              }
            }
            _scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ),
    );
  }

  // Widget _buildFilterChips() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: [
  //         _buildFilterChip('Weather', _selectedWeather, (newValue) {
  //           setState(() {
  //             _selectedWeather = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Temp', _selectedTemp, (newValue) {
  //           setState(() {
  //             _selectedTemp = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Event', _selectedEvent, (newValue) {
  //           setState(() {
  //             _selectedEvent = newValue;
  //           });
  //         }),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFilterChip(
  //   String label,
  //   String value,
  //   ValueChanged<String> onSelected,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).inputDecorationTheme.fillColor,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       children: [
  //         Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
  //         const SizedBox(width: 4),
  //         const Icon(Icons.close, size: 14),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load products',
              style: TextStyle(color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    // If user typed a query, prefer vector results
    if (_query.isNotEmpty) {
      if (_searching) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_searchError != null) {
        return Center(
          child: Text(
            _searchError!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
      }
      // Apply client-side sorting for price
      final results = _applySorting(_vectorResults);
      if (results.isEmpty) {
        return const Center(
          child: Text(
            'No results. Try refining your query.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return _buildGrid(results);
    }

    final filtered = _applySorting(_products);
    return _buildGrid(filtered);
  }

  List<Product> _applySorting(List<Product> input) {
    if (input.isEmpty) return input;
    if (_sort == 'price_asc') {
      final copy = [...input];
      copy.sort((a, b) => a.price.compareTo(b.price));
      return copy;
    }
    if (_sort == 'price_desc') {
      final copy = [...input];
      copy.sort((a, b) => b.price.compareTo(a.price));
      return copy;
    }
    // relevance: keep as-is (server-provided order or original list order)
    return input;
  }

  Widget _buildGrid(List<Product> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Hero(
            tag: product.image,
            child: ProductCard(product: product),
          ),
        );
      },
    );
  }

  void _applyFacetSelection(String title, String option) {
    final current = _searchCtrl.text;
    final words = current
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .toList();
    // Candidate tokens to replace: options from the same facet; for category also include known categories
    final sameFacet = _facets.firstWhere(
      (f) =>
          (f['title']?.toString().toLowerCase() ?? '') == title.toLowerCase(),
      orElse: () => const {'title': '', 'options': []},
    );
    final List<String> candidates = [
      ...((sameFacet['options'] as List?)?.map(
            (e) => e.toString().toLowerCase(),
          ) ??
          const Iterable.empty()),
      if (title.toLowerCase() == 'category')
        ..._knownCategories.map((e) => e.toLowerCase()),
      if (title.toLowerCase() == 'color')
        ..._knownColors.map((e) => e.toLowerCase()),
    ];
    int idx = -1;
    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase();
      if (candidates.contains(w)) {
        idx = i;
        break;
      }
    }
    if (idx >= 0) {
      words[idx] = option;
    } else {
      words.add(option);
    }
    final updated = words.join(' ');
    _searchCtrl.text = updated;
    _searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: updated.length),
    );
    _onQueryChanged(updated);
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  Widget _buildEndDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suggestions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () =>
                        _scaffoldKey.currentState?.closeEndDrawer(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Sort by', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Relevance'),
                    selected: _sort == 'relevance',
                    onSelected: (_) {
                      setState(() => _sort = 'relevance');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price ↑'),
                    selected: _sort == 'price_asc',
                    onSelected: (_) {
                      setState(() => _sort = 'price_asc');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price ↓'),
                    selected: _sort == 'price_desc',
                    onSelected: (_) {
                      setState(() => _sort = 'price_desc');
                    },
                  ),
                ],
              ),
              if ((_primaryFacet != null && _primaryFacet!.isNotEmpty)) ...[
                const SizedBox(height: 6),
                Text(
                  'Primary: ${_primaryFacet!}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: (_facets.isNotEmpty)
                    ? ListView.builder(
                        itemCount: _facets.length,
                        itemBuilder: (context, idx) {
                          final f = _facets[idx];
                          final title = (f['title']?.toString() ?? '')
                              .toLowerCase();
                          final disp = title.isEmpty
                              ? 'Facet'
                              : title[0].toUpperCase() + title.substring(1);
                          final List options =
                              (f['options'] as List?) ?? const [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disp,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: options
                                      .map((o) {
                                        final val = o.toString();
                                        return ChoiceChip(
                                          label: Text(val),
                                          selected: false,
                                          onSelected: (_) =>
                                              _applyFacetSelection(title, val),
                                        );
                                      })
                                      .toList()
                                      .cast<Widget>(),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : _buildFallbackFacetUI(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackFacetUI() {
    final q = _query.toLowerCase();
    final tokens = q.split(RegExp(r"\s+")).where((t) => t.isNotEmpty).toList();
    String? detectedColor = _knownColors.firstWhere(
      (c) => tokens.contains(c),
      orElse: () => '',
    );
    detectedColor = (detectedColor.isEmpty) ? null : detectedColor;
    String? detectedCategory = _knownCategories.firstWhere(
      (c) => tokens.contains(c),
      orElse: () => '',
    );
    detectedCategory = (detectedCategory.isEmpty) ? null : detectedCategory;

    final colorOptions = _knownColors;
    final categoryOptions = _knownCategories.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detectedColor != null) ...[
            Text(
              'Detected color: $detectedColor',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colorOptions.map((c) {
                final isSel = c.toLowerCase() == detectedColor!.toLowerCase();
                return ChoiceChip(
                  label: Text(c),
                  selected: isSel,
                  onSelected: (_) => _applyFacetSelection('color', c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            detectedCategory != null
                ? 'Detected category: $detectedCategory'
                : 'Pick a category',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryOptions.map((c) {
              final isSel =
                  detectedCategory != null &&
                  c.toLowerCase() == detectedCategory.toLowerCase();
              final label = c.isEmpty
                  ? 'Other'
                  : (c[0].toUpperCase() + c.substring(1));
              return ChoiceChip(
                label: Text(label),
                selected: isSel,
                onSelected: (_) => _applyFacetSelection('category', c),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _AdaptiveImage(image: product.image),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.category,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '৳${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdaptiveImage extends StatelessWidget {
  final String image;
  const _AdaptiveImage({required this.image});

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    // Estimate on-screen width for thumbnail cache sizing
    double screenWidth = MediaQuery.of(context).size.width;
    // Grid: 2 columns, horizontal padding 16*2 and spacing 16
    double itemLogicalWidth = (screenWidth - 32 - 16) / 2;
    final double pxW =
        (itemLogicalWidth) * MediaQuery.of(context).devicePixelRatio;
    final int? cacheWidth = (pxW.isFinite && pxW > 0) ? pxW.round() : null;
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        width: double.infinity,
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[700],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 40),
          ),
        ),
      );
    }
    return Image.asset(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey[700],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
