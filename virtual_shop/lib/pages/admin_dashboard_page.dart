import 'package:flutter/material.dart';
import 'package:virtual_shop/utils/admin_api.dart';

// Drawer panel kinds for the admin end drawer
enum _PanelKind { filter, product, story }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _pendingProducts = [];
  List<Map<String, dynamic>> _pendingStories = [];
  late TabController _tabs;
  String _productStatus = 'pending';
  String _storyStatus = 'pending';
  int _prodCount = 0;
  int _storyCount = 0;
  Map<String, dynamic> _me = const {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _PanelKind _panelKind = _PanelKind.filter;
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedStory;
  List<Map<String, dynamic>> _productComments = [];
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  String _commentVisibility = 'uploader';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isAdmin = await AdminApi.isAdmin();
    if (!isAdmin) {
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
      return;
    }
    try {
      final me = await AdminApi.adminMe();
      final prods = await AdminApi.fetchPendingProducts(status: _productStatus);
      final stories = await AdminApi.fetchPendingStories(status: _storyStatus);
      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _me = me;
        _pendingProducts = prods;
        _pendingStories = stories;
        _prodCount = prods.length;
        _storyCount = stories.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('Admin', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            if (_isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_me['auth_id'] ?? '') is String
                      ? (_me['auth_id'] as String).substring(0, 8)
                      : 'me',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () {
              setState(() => _panelKind = _PanelKind.filter);
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.tune, color: Colors.white),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: const Color(0x1AADFF2F),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: const Color(0xFFADFF2F),
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Stories'),
              ],
            ),
          ),
        ),
      ),
      endDrawer: _buildEndDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (!_isAdmin
                ? _buildNotAdmin()
                : TabBarView(
                    controller: _tabs,

                    children: [_buildProductList(), _buildStoryList()],
                  )),
    );
  }

  Widget _buildEndDrawer() {
    switch (_panelKind) {
      case _PanelKind.filter:
        return _buildFilterDrawer();
      case _PanelKind.product:
        return _buildProductDetailDrawer();
      case _PanelKind.story:
        return _buildStoryDetailDrawer();
    }
  }

  Widget _buildFilterDrawer() {
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
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Products', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _statusChip(
                    'pending',
                    _productStatus == 'pending',
                    () => _changeStatus(products: 'pending'),
                  ),
                  _statusChip(
                    'approved',
                    _productStatus == 'approved',
                    () => _changeStatus(products: 'approved'),
                  ),
                  _statusChip(
                    'rejected',
                    _productStatus == 'rejected',
                    () => _changeStatus(products: 'rejected'),
                  ),
                  _statusChip(
                    'all',
                    _productStatus == 'all',
                    () => _changeStatus(products: 'all'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Stories', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _statusChip(
                    'pending',
                    _storyStatus == 'pending',
                    () => _changeStatus(stories: 'pending'),
                  ),
                  _statusChip(
                    'approved',
                    _storyStatus == 'approved',
                    () => _changeStatus(stories: 'approved'),
                  ),
                  _statusChip(
                    'rejected',
                    _storyStatus == 'rejected',
                    () => _changeStatus(stories: 'rejected'),
                  ),
                  _statusChip(
                    'all',
                    _storyStatus == 'all',
                    () => _changeStatus(stories: 'all'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _metricCard('Products', _prodCount)),
                  const SizedBox(width: 8),
                  Expanded(child: _metricCard('Stories', _storyCount)),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _load,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFADFF2F),
                  backgroundColor: const Color(0x1AADFF2F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Apply & Refresh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  void _changeStatus({String? products, String? stories}) async {
    if (products != null) _productStatus = products;
    if (stories != null) _storyStatus = stories;
    setState(() => _loading = true);
    try {
      final prods = await AdminApi.fetchPendingProducts(status: _productStatus);
      final sts = await AdminApi.fetchPendingStories(status: _storyStatus);
      if (!mounted) return;
      setState(() {
        _pendingProducts = prods;
        _pendingStories = sts;
        _prodCount = prods.length;
        _storyCount = sts.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _metricCard(String title, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinyPill(String status) {
    final s = status.toLowerCase();
    Color c;
    switch (s) {
      case 'approved':
        c = Colors.greenAccent;
        break;
      case 'rejected':
        c = Colors.redAccent;
        break;
      case 'pending':
        c = Colors.amberAccent;
        break;
      default:
        c = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        s,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNotAdmin() {
    return Center(
      child: Container(
        width: 320,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'You do not have admin access.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_pendingProducts.isEmpty) {
      return const Center(
        child: Text(
          'No pending products',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      itemCount: _pendingProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _pendingProducts[i];
        final image = (p['image_url'] as String?) ?? '';
        final name = (p['name'] as String?) ?? 'Unnamed';
        final uploader = (p['uploader'] as Map?) ?? const {};
        final uploaderName = (uploader['name'] as String?) ?? '';
        final uploaderEmail = (uploader['email'] as String?) ?? '';
        return InkWell(
          onTap: () {
            setState(() {
              _selectedProduct = p;
              _panelKind = _PanelKind.product;
            });
            _loadProductComments(p['id']?.toString());
            _scaffoldKey.currentState?.openEndDrawer();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (image.startsWith('http')) {
                            _openImageViewer(image);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: image.startsWith('http')
                              ? Image.network(
                                  image,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white24,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Approve',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFADFF2F),
                                  ),
                                  onPressed: () async {
                                    await AdminApi.approveProduct(
                                      p['id'].toString(),
                                    );
                                    _load();
                                  },
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Reject',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await _promptReject(
                                      reasonHandler: (reason) async {
                                        await AdminApi.rejectProduct(
                                          p['id'].toString(),
                                          reason: reason,
                                        );
                                      },
                                    );
                                    _load();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    uploaderName.isNotEmpty
                                        ? '$uploaderName · $uploaderEmail'
                                        : uploaderEmail,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _tinyPill(_productStatus),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (p['created_at'] != null)
                              Text(
                                'Created: ${p['created_at'].toString().replaceFirst('T', ' ').substring(0, 19)}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryList() {
    if (_pendingStories.isEmpty) {
      return const Center(
        child: Text(
          'No pending stories',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = _pendingStories[i];
        final image = (s['media_url'] as String?) ?? '';
        final caption = (s['caption'] as String?) ?? '';
        final uploader = (s['uploader'] as Map?) ?? const {};
        final uploaderName = (uploader['name'] as String?) ?? '';
        final uploaderEmail = (uploader['email'] as String?) ?? '';
        return InkWell(
          onTap: () {
            setState(() {
              _selectedStory = s;
              _panelKind = _PanelKind.story;
            });
            _scaffoldKey.currentState?.openEndDrawer();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (image.startsWith('http')) {
                            _openImageViewer(image);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: image.startsWith('http')
                              ? Image.network(
                                  image,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white24,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    caption.isEmpty ? 'Story' : caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Approve',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFADFF2F),
                                  ),
                                  onPressed: () async {
                                    await AdminApi.approveStory(
                                      s['id'].toString(),
                                    );
                                    _load();
                                  },
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Reject',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await _promptReject(
                                      reasonHandler: (reason) async {
                                        await AdminApi.rejectStory(
                                          s['id'].toString(),
                                          reason: reason,
                                        );
                                      },
                                    );
                                    _load();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    uploaderName.isNotEmpty
                                        ? '$uploaderName · $uploaderEmail'
                                        : uploaderEmail,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _tinyPill(_storyStatus),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (s['created_at'] != null)
                              Text(
                                'Created: ${s['created_at'].toString().replaceFirst('T', ' ').substring(0, 19)}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptReject({
    required Future<void> Function(String) reasonHandler,
  }) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Reject Reason',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Optional reason',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    await reasonHandler(reason);
  }

  // Drawer: Product details
  Widget _buildProductDetailDrawer() {
    final p = _selectedProduct ?? const <String, dynamic>{};
    final image = (p['image_url'] as String?) ?? '';
    final name = (p['name'] as String?) ?? 'Product';
    final desc = (p['description'] as String?) ?? '';
    final uploader = (p['uploader'] as Map?) ?? const {};
    final uploaderName = (uploader['name'] as String?) ?? '';
    final uploaderEmail = (uploader['email'] as String?) ?? '';
    final price = p['price']?.toString();
    final category = p['category']?.toString();
    final brand = p['brand']?.toString();
    final stock = p['stock']?.toString();
    final condition = p['condition']?.toString();
    final rating = p['rating']?.toString();
    final status = (p['approval_status']?.toString() ?? _productStatus);
    final reason = (p['rejected_reason'] as String?) ?? '';
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Product Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _tinyPill(status),
                IconButton(
                  tooltip: 'Approve',
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFFADFF2F),
                  ),
                  onPressed: () async {
                    final id = p['id']?.toString();
                    if (id == null) return;
                    await AdminApi.approveProduct(id);
                    if (mounted) Navigator.of(context).maybePop();
                    _load();
                  },
                ),
                IconButton(
                  tooltip: 'Reject',
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () async {
                    final id = p['id']?.toString();
                    if (id == null) return;
                    await _promptReject(
                      reasonHandler: (reason) async {
                        await AdminApi.rejectProduct(id, reason: reason);
                      },
                    );
                    if (mounted) Navigator.of(context).maybePop();
                    _load();
                  },
                ),
              ],
            ),
            if (image.isNotEmpty && image.startsWith('http'))
              GestureDetector(
                onTap: () => _openImageViewer(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white24, size: 48),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _infoRow('Price', price),
                _infoRow('Category', category),
                _infoRow('Brand', brand),
                _infoRow('Stock', stock),
                _infoRow('Condition', condition),
                _infoRow('Rating', rating),
                if (p['created_at'] != null)
                  _infoRow(
                    'Created',
                    p['created_at']
                        .toString()
                        .replaceFirst('T', ' ')
                        .substring(0, 19),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Uploader',
              children: [
                _infoRow('Name', uploaderName.isEmpty ? null : uploaderName),
                _infoRow('Email', uploaderEmail.isEmpty ? null : uploaderEmail),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Moderator Comments',
              children: [
                if (_loadingComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_productComments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ..._productComments
                      .map((c) => _moderationCommentTile(c))
                      .toList(),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Leave a note for the uploader or internal...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _commentVisibility,
                        dropdownColor: const Color(0xFF222222),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'uploader',
                            child: Text('Visible to uploader'),
                          ),
                          DropdownMenuItem(
                            value: 'internal',
                            child: Text('Internal only'),
                          ),
                        ],
                        onChanged: (v) => setState(
                          () => _commentVisibility = v ?? 'uploader',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TextButton.icon(
                            onPressed: () async {
                              final id = p['id']?.toString();
                              final msg = _commentController.text.trim();
                              if (id == null || msg.isEmpty) return;
                              try {
                                await AdminApi.addProductComment(
                                  id,
                                  message: msg,
                                  visibility: _commentVisibility,
                                );
                                _commentController.clear();
                                _loadProductComments(id);
                              } catch (_) {}
                            },
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFFADFF2F),
                            ),
                            label: const Text(
                              'Add Comment',
                              style: TextStyle(color: Color(0xFFADFF2F)),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0x1AADFF2F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Rejection Reason',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      reason,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _moderationCommentTile(Map<String, dynamic> c) {
    final msg = (c['message'] as String?) ?? '';
    final visibility = (c['visibility'] as String?) ?? 'uploader';
    final createdAt = (c['created_at']?.toString() ?? '').replaceFirst(
      'T',
      ' ',
    );
    final admin = (c['admin'] as Map?) ?? const {};
    final adminName = (admin['name'] as String?) ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  (visibility == 'internal'
                          ? Colors.redAccent
                          : const Color(0xFFADFF2F))
                      .withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              visibility == 'internal' ? 'internal' : 'uploader',
              style: TextStyle(
                color: visibility == 'internal'
                    ? Colors.redAccent
                    : const Color(0xFFADFF2F),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (adminName.isNotEmpty)
                  Text(
                    adminName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                Text(msg, style: const TextStyle(color: Colors.white)),
                if (createdAt.isNotEmpty)
                  Text(
                    createdAt.substring(
                      0,
                      createdAt.length >= 19 ? 19 : createdAt.length,
                    ),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProductComments(String? productId) async {
    if (productId == null) return;
    setState(() => _loadingComments = true);
    try {
      final list = await AdminApi.fetchProductComments(productId);
      if (!mounted) return;
      setState(() {
        _productComments = list;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  // Drawer: Story details
  Widget _buildStoryDetailDrawer() {
    final s = _selectedStory ?? const <String, dynamic>{};
    final image = (s['media_url'] as String?) ?? '';
    final caption = (s['caption'] as String?) ?? '';
    final uploader = (s['uploader'] as Map?) ?? const {};
    final uploaderName = (uploader['name'] as String?) ?? '';
    final uploaderEmail = (uploader['email'] as String?) ?? '';
    final status = (s['approval_status']?.toString() ?? _storyStatus);
    final reason = (s['rejected_reason'] as String?) ?? '';
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Story Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _tinyPill(status),
                IconButton(
                  tooltip: 'Approve',
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFFADFF2F),
                  ),
                  onPressed: () async {
                    final id = s['id']?.toString();
                    if (id == null) return;
                    await AdminApi.approveStory(id);
                    if (mounted) Navigator.of(context).maybePop();
                    _load();
                  },
                ),
                IconButton(
                  tooltip: 'Reject',
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () async {
                    final id = s['id']?.toString();
                    if (id == null) return;
                    await _promptReject(
                      reasonHandler: (reason) async {
                        await AdminApi.rejectStory(id, reason: reason);
                      },
                    );
                    if (mounted) Navigator.of(context).maybePop();
                    _load();
                  },
                ),
              ],
            ),
            if (image.isNotEmpty && image.startsWith('http'))
              GestureDetector(
                onTap: () => _openImageViewer(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    image,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white24, size: 48),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              caption.isEmpty ? 'Story' : caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Uploader',
              children: [
                _infoRow('Name', uploaderName.isEmpty ? null : uploaderName),
                _infoRow('Email', uploaderEmail.isEmpty ? null : uploaderEmail),
                if (s['created_at'] != null)
                  _infoRow(
                    'Created',
                    s['created_at']
                        .toString()
                        .replaceFirst('T', ' ')
                        .substring(0, 19),
                  ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Rejection Reason',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      reason,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
