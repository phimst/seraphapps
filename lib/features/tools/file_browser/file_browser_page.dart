import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/storage_service.dart';

class _FileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int sizeBytes;
  final DateTime modified;
  _FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    required this.modified,
  });
}

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  List<_FileEntry> _entries = [];
  String _currentPath = '';
  String _rootPath = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final root = await StorageService.rootPath;
      setState(() {
        _rootPath = root;
        _currentPath = root;
      });
      await _load(root);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dir = Directory(path);
      final list = await dir.list().toList();
      final entries = <_FileEntry>[];
      for (final item in list) {
        final stat = await item.stat();
        entries.add(_FileEntry(
          name: item.path.split('/').last,
          path: item.path,
          isDirectory: item is Directory,
          sizeBytes: stat.size,
          modified: stat.modified,
        ));
      }
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return b.modified.compareTo(a.modified);
      });
      setState(() {
        _entries = entries;
        _currentPath = path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(_FileEntry entry) async {
    try {
      if (entry.isDirectory) {
        await Directory(entry.path).delete(recursive: true);
      } else {
        await File(entry.path).delete();
      }
      await _load(_currentPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _canGoUp => _currentPath != _rootPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SeraphHeader(
            title: 'File',
            accent: 'Browser',
            subtitle: _currentPath.replaceFirst(_rootPath, 'seraphapps'),
            padding: const EdgeInsets.only(bottom: 6),
          ),
        ),
        if (_canGoUp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _load(Directory(_currentPath).parent.path),
                icon: const Icon(Icons.arrow_upward, size: 16, color: AppColors.cyan),
                label: const Text('Naik satu folder', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)))
                  : _entries.isEmpty
                      ? const Center(child: Text('Folder kosong', style: TextStyle(color: AppColors.gray, fontSize: 12)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) => _entryTile(_entries[i]),
                        ),
        ),
      ],
    );
  }

  Widget _entryTile(_FileEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: entry.isDirectory ? AppColors.cyan : AppColors.gray),
        title: Text(entry.name,
            style: const TextStyle(color: AppColors.ink, fontSize: 12.5), overflow: TextOverflow.ellipsis),
        subtitle: entry.isDirectory
            ? null
            : Text(_formatSize(entry.sizeBytes), style: const TextStyle(color: AppColors.gray, fontSize: 10)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.magenta, size: 18),
          onPressed: () => _confirmDelete(entry),
        ),
        onTap: () {
          if (entry.isDirectory) {
            _load(entry.path);
          } else {
            OpenFilex.open(entry.path);
          }
        },
      ),
    );
  }

  void _confirmDelete(_FileEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Hapus?', style: TextStyle(color: AppColors.ink)),
        content: Text('Hapus "${entry.name}"? Gak bisa dibalikin lagi.',
            style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(entry);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
  }
}
