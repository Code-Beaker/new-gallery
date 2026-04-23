import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<AssetEntity> _assets = [];
  bool _loading = true;
  String? _error;

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
        await albums.first.getAssetListRange(start: 0, end: 200);

    setState(() {
      _assets
        ..clear()
        ..addAll(recentAssets);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
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
                    return AssetEntityImage(
                      _assets[index],
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(200),
                      fit: BoxFit.cover,
                    );
                  },
                ),
    );
  }
}
