import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../core/localization/app_language.dart';
import '../core/localization/localized_text.dart';
import '../providers/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return PopupMenuButton<String>(
      tooltip: tr(context, 'Language'),
      initialValue: language.languageCode,
      onSelected: language.setLanguage,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: AppLanguage.english,
          child: Text('English'),
        ),
        PopupMenuItem(
          value: AppLanguage.cantonese,
          child: Text('廣東話（繁體中文）'),
        ),
      ],
      child: compact
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                language.isCantonese ? '中' : 'EN',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: Text(
                language.isCantonese ? '廣東話（繁體中文）' : 'English',
              ),
              trailing: const Icon(Icons.expand_more),
            ),
    );
  }
}
