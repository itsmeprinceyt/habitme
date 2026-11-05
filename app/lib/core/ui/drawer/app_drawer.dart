import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/drawer/manage_labels_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    Future<void> exportBackup() async {
      navigator.pop();
      try {
        await service.exportSql();
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    }

    Future<void> importBackup() async {
      navigator.pop();
      try {
        final summary = await service.importSql();
        if (summary == null) return;
        await ref.read(labelControllerProvider.notifier).build();
        await ref.read(habitControllerProvider.notifier).reconcile();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${summary.habits} habits, ${summary.labels} labels and '
              '${summary.completions} completions',
            ),
          ),
        );
      } on FormatException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Import failed. Invalid backup file.')),
        );
      }
    }

    Future<void> openWebsite() async {
      final opened = await launchUrl(
        Uri.parse(AppConstants.madeByUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the website')),
        );
      }
    }

    void openManageLabels() {
      navigator.pop();
      ManageLabelsSheet.show(context);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DrawerHeader(),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.label_outline_rounded),
              title: const Text('Manage Labels'),
              subtitle: const Text(
                'Create and organize your habit labels',
                style: TextStyle(color: AppColors.muted),
              ),
              onTap: openManageLabels,
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import'),
              subtitle: const Text(
                'Restore habits and labels from a SQL backup',
                style: TextStyle(color: AppColors.muted),
              ),
              onTap: importBackup,
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export'),
              subtitle: const Text(
                'Save habits and labels as a SQL file',
                style: TextStyle(color: AppColors.muted),
              ),
              onTap: exportBackup,
            ),
            const Spacer(),
            _MadeByCard(onTap: openWebsite),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              child: Image.asset(
                AppConstants.logoAsset,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MadeByCard extends StatelessWidget {
  const _MadeByCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.madeByLabel,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        AppConstants.madeByName,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
