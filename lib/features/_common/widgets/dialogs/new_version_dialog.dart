import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:urban_cafe/core/utils/web_reloader.dart';

class NewVersionDialog extends StatefulWidget {
  const NewVersionDialog({super.key});

  @override
  State<NewVersionDialog> createState() => _NewVersionDialogState();
}

class _NewVersionDialogState extends State<NewVersionDialog> {
  bool _reloading = false;

  void _refresh() {
    if (_reloading) return;
    setState(() => _reloading = true);
    reloadWebPage(); // navigates away — widget will die, spinner is just UX polish
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text('update_available'.tr()),
        ],
      ),
      content: const Text('A new version of the app is available. Please refresh to get the latest features and improvements.'),
      actions: [
        TextButton(onPressed: _reloading ? null : () => Navigator.of(context).pop(), child: Text('later'.tr())),
        FilledButton.icon(
          onPressed: _reloading ? null : _refresh,
          icon: _reloading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh),
          label: Text('refresh_now'.tr()),
        ),
      ],
    );
  }
}
