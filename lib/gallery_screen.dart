import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

enum SortMode { date, name, size }

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<AssetEntity> _assets = [];
  bool _loading = true;
  String? _error;
  SortMode _sortMode = SortMode.date;
  bool _descending = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() {
        _loading = false;
        _error = 'Permission denied. Please allow photo access.';
      });
      return;
    }

    final List<AssetPathEntity> albums =
        await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);

    if (albums.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No images found.';
      });
      return;
    }

    final List<AssetEntity> recentAssets =
        await albums.first.getAssetListRange(start: 0, end: 400);

    setState(() {
      _assets
        ..clear()
        ..addAll(recentAssets);
      _applySort();
      _loading = false;
    });
  }

  void _applySort() {
    _assets.sort((a, b) {
      int comparison = 0;
      switch (_sortMode) {
        case SortMode.date:
          comparison = a.createDateTime.compareTo(b.createDateTime);
          break;
        case SortMode.name:
          comparison = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case SortMode.size:
          comparison = a.size.compareTo(b.size);
          break;
      }
      return _descending ? -comparison : comparison;
    });
  }

  void _updateSort(SortMode mode) {
    setState(() {
      _sortMode = mode;
      _applySort();
    });
  }

  void _toggleOrder() {
    setState(() {
      _descending = !_descending;
      _applySort();
    });
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenViewer(
          assets: _assets,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          PopupMenuButton<SortMode>(
            onSelected: _updateSort,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: SortMode.date,
                child: Text('Sort by date'),
              ),
              PopupMenuItem(
                value: SortMode.name,
                child: Text('Sort by name'),
              ),
              PopupMenuItem(
                value: SortMode.size,
                child: Text('Sort by size'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: _toggleOrder,
            icon: Icon(_descending ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: _descending ? 'Descending' : 'Ascending',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openViewer(index),
                      child: AssetEntityImage(
                        _assets[index],
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(200),
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
    );
  }
}

class FullscreenViewer extends StatefulWidget {
  const FullscreenViewer({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<FullscreenViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.assets[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(current.title ?? 'Image'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.assets.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          return Center(
            child: AssetEntityImage(
              widget.assets[index],
              isOriginal: true,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
