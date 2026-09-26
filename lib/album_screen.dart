import 'dart:io';
import 'package:flutter/material.dart';
import 'album_service.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({Key? key}) : super(key: key);

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<String> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  void _loadAlbum() async {
    final items = await AlbumService.getUnlockedCards();
    setState(() {
      _cards = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌟 دفترچه افتخارات من'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(
                  child: Text(
                    'هنوز کارتی باز نشده است!\nمراحل پازل را تکمیل کن تا کارت‌های حکمت اینجا جمع شوند.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final path = _cards[index];
                    return GestureDetector(
                      onTap: () => _showFullImage(context, path),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(File(path), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
    );
  }

  void _showFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(File(path)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
