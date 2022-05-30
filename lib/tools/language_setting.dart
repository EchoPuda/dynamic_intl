import 'package:intl/message_lookup_by_library.dart';

import '../messages_manage.dart';
import 'arb_translation.dart';
export 'package:intl/message_lookup_by_library.dart';

/// 语言包配置
abstract class LanguageSetting {
  /// 根据locale决定的资源下载地址，arb格式!
  Future<String> languageApi(String locale);

  /// 语言包缓存目录
  String kDicName = 'language_l10n';

  /// 语言包文件名
  /// 以这种格式存储 ${kFileName}_$localeName.arb
  String kFileName = "language_intl";

  /// 是否使用本地的配置的Key，用来配合远程开关
  String kIntlLocaled = "language_intl_use_local";

  /// 默认的语言
  String defaultLocale = "en";

  /// 支持的语言列表，() => 后不为null即可
  /// intl官方的格式，就不调了
  Map<String, LibraryLoader> deferredLibraries = {
    'en': () => Future.value(null),
  };

  /// arb 转译器，有需要可重写
  ArbTranslation arbTranslation = ArbTranslation();

  /// 当无法取得网络资源时，本地的语言包，参考官方生成的格式
  ///     switch (localeName) {
  ///       case 'de':
  ///         return messages_de.messages;
  ///       case 'en':
  ///         return messages_en.messages;
  ///       case 'it':
  ///         return messages_it.messages;
  ///       default:
  ///         return null;
  ///     }
  MessageLookupByLibrary? defaultLocaleMessages(String localeName) {
    switch (localeName) {
      default:
        return null;
    }
  }

  /// 是否开启arb增量更新
  bool get arbMergeEnable => false;
}
