import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/widgets/ad_banner.dart';
import 'package:habit_me/core/utils/app_log.dart';
import 'package:habit_me/core/utils/date_utils.dart';
import 'package:habit_me/data/services/notification_service.dart';

class LogViewerPage extends ConsumerStatefulWidget {
  const LogViewerPage({super.key});

  @override
  ConsumerState<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends ConsumerState<LogViewerPage> {
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

  Future<void> _copyAll(List<ScheduledReminder> scheduledList) async {
    final buffer = StringBuffer();

    buffer.writeln('=== SCHEDULED NOTIFICATIONS (${scheduledList.length}) ===');
    if (scheduledList.isEmpty) {
      buffer.writeln('None');
    } else {
      for (var i = 0; i < scheduledList.length; i++) {
        final item = scheduledList[i];
        final number = (i + 1).toString().padLeft(2, '0');
        buffer.writeln('$number. ${item.title} - ${AppDateUtils.formatDateTime(item.at)}');
      }
    }

    buffer.writeln();
    buffer.writeln('=== LIVE LOGS (${AppLog.lines.length}) ===');
    buffer.writeln(AppLog.lines.join('\n'));

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs & Schedule copied to clipboard')),
      );
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
    final habits = ref.watch(habitControllerProvider).value ?? const [];
    final scheduler = ref.watch(habitSchedulerProvider);
    final scheduledList = scheduler.computePlan(habits, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs & Notifications'),
        actions: [
          IconButton(
            tooltip: 'Copy all logs & schedule',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => _copyAll(scheduledList),
          ),
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            onPressed: () => setState(AppLog.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Ad Banner
          const AdBanner(),

          // 2. Logs screen to show logs
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.terminal_rounded,
                          size: 16,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Logs',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${lines.length} lines',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildLogList(lines)),
                ],
              ),
            ),
          ),

          // 3. Ad Banner
          const AdBanner(),

          // 4. Full Scheduled notification list
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alarm_on_rounded,
                          size: 16,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scheduled Notifications',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${scheduledList.length} queued',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildScheduledList(scheduledList)),
                ],
              ),
            ),
          ),

          // 5. Ad Banner
          const SafeArea(
            top: false,
            child: AdBanner(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'logs_bottom',
        tooltip: 'Scroll to bottom',
        onPressed: _scrollToEnd,
        child: const Icon(Icons.arrow_downward_rounded),
      ),
    );
  }

  Widget _buildLogList(List<String> lines) {
    if (lines.isEmpty) {
      return const Center(
        child: Text(
          'No logs yet',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, i) => SelectableText(
        lines[i],
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildScheduledList(List<ScheduledReminder> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No notifications currently scheduled.\nEnable reminder on habits to see upcoming schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: list.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final number = (index + 1).toString().padLeft(2, '0');
        final formattedDate = AppDateUtils.formatDateTime(item.at);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
