import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(title: Text('language'.tr())),
      body: ListView(
        children: [
          _LanguageTile(locale: const Locale('en'), label: 'English', isSelected: currentLocale == const Locale('en'), onTap: () => context.setLocale(const Locale('en'))),
          _LanguageTile(locale: const Locale('my'), label: 'Myanmar', isSelected: currentLocale == const Locale('my'), onTap: () => context.setLocale(const Locale('my'))),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale locale;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({required this.locale, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
    );
  }
}
