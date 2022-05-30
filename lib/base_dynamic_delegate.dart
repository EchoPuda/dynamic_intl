import 'package:dynamic_intl/messages_manage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 动态多语言 delegate
/// 使用[BaseLocalizationsDynamicDelegate]替换原来的，不要和官方那个同时使用
/// [T] 为自己项目中生成的类，默认是S
abstract class BaseLocalizationsDynamicDelegate<T>
    extends LocalizationsDelegate<T> {
  const BaseLocalizationsDynamicDelegate();

  // static const AppLocalizationDynamicDelegate delegate =
  //     AppLocalizationDynamicDelegate();

  List<Locale> get supportedLocales {
    return supportedLocalesLibraries;
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<T> load(Locale locale) => _load(locale);
  @override
  bool shouldReload(BaseLocalizationsDynamicDelegate<T> old) => true;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  Future<T> _load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeDynamicMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;

      return loadS();
    });
  }

  Future<T> loadS();
}
