import 'package:dynamic_intl/dynamic_intl.dart';

class TestSetting extends LanguageSetting {
  @override
  Future<String> languageApi(String locale) async {
    return 'https://jomin-web.web.app/language/intl_$locale.arb';
  }

  @override
  String get defaultLocale => 'en';

  @override
  Map<String, LibraryLoader> get deferredLibraries => {
        'zh': () => Future.value(null),
        'en': () => Future.value(null),
      };

}
