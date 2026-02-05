import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:urban_cafe/core/services/version_check_service.dart';
import 'package:urban_cafe/features/_common/widgets/dialogs/new_version_dialog.dart';

class UpgradeListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const UpgradeListener({super.key, required this.child, this.navigatorKey});

  @override
  State<UpgradeListener> createState() => _UpgradeListenerState();
}

class _UpgradeListenerState extends State<UpgradeListener> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    if (_hasChecked || !kIsWeb) return;
    _hasChecked = true;

    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final service = VersionCheckService();
    final hasUpdate = await service.checkUpdateAvailable();

    if (hasUpdate && mounted) {
      // Use the navigator context if available, otherwise fall back to local context
      // (though local context likely won't work if this is above the Navigator)
      final ctx = widget.navigatorKey?.currentContext ?? context;

      if (ctx.mounted) {
        showDialog(context: ctx, barrierDismissible: false, builder: (context) => const NewVersionDialog());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
