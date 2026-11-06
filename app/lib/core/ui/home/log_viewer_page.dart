import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/utils/app_log.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: AppLog.lines.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Logs copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppLog.version,
      builder: (context, _, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final lines = AppLog.lines;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: _copyAll,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            onPressed: () => setState(AppLog.clear),
          ),
        ],
      ),
      body: lines.isEmpty
          ? const Center(
              child: Text(
                'No logs yet',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: lines.length,
              itemBuilder: (context, i) => SelectableText(
                lines[i],
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'logs_bottom',
        tooltip: 'Latest',
        onPressed: _scrollToEnd,
        child: const Icon(Icons.arrow_downward_rounded),
      ),
    );
  }
}
