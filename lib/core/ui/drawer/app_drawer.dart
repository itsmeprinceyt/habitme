import 'package:flutter/material.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _handle(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import'),
              subtitle: const Text(
                'Restore from CSV or SQL',
                style: TextStyle(color: AppColors.muted),
              ),
              onTap: () => _handle(context, 'Import arrives in step 8'),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export'),
              subtitle: const Text(
                'Save a backup as CSV or SQL',
                style: TextStyle(color: AppColors.muted),
              ),
              onTap: () => _handle(context, 'Export arrives in step 8'),
            ),
            const Spacer(),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.favorite_rounded, color: AppColors.orange),
              title: Text(AppConstants.madeByLabel),
              subtitle: Text(
                AppConstants.madeByName,
                style: TextStyle(color: AppColors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
