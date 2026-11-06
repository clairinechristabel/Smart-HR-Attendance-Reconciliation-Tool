import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import 'app_language.dart';

/// Translates labels used by Material widgets that accept a String rather than
/// a child widget (for example, input hints and icon tooltips).
String tr(material.BuildContext context, String value) {
  try {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    return AppLanguage.translate(
      value,
      languageProvider.languageCode,
    );
  } catch (_) {
    return value;
  }
}

/// Formats dates in the active app locale. This keeps month and weekday names
/// in Cantonese after a language switch, rather than only translating labels.
String formatDate(
  material.BuildContext context,
  DateTime value,
  String pattern,
) {
  return DateFormat(
          pattern, material.Localizations.localeOf(context).toString())
      .format(value);
}

/// Drop-in replacement for Material's Text widget.
///
/// It keeps existing screens localizable even when the displayed value is
/// dynamic (status labels, greetings, or field values). The app rebuilds this
/// widget when [LanguageProvider] changes, so switching language is immediate.
class Text extends material.StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    final languageCode = context.select<LanguageProvider, String>(
      (provider) => provider.languageCode,
    );
    return material.Text(
      AppLanguage.translate(data, languageCode),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
