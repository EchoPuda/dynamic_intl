import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:arb_utils/arb_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../messages_manage.dart';
import 'arb_translation.dart';
import 'language_setting.dart';

/// 多语言 管理
/// @author jm
class LanguageUtil {
  factory LanguageUtil() => _getInstance();
  static LanguageUtil get instance => _getInstance();
  static LanguageUtil? _instance;

  static LanguageUtil _getInstance() {
    _instance ??= LanguageUtil._internal();
    return _instance!;
  }

  LanguageUtil._internal();

  String get _kDicName => languageSetting.kDicName;
  String get _kFileName => languageSetting.kFileName;
  String get _kIntlLocaled => languageSetting.kIntlLocaled;
  String get _defaultLocale => languageSetting.defaultLocale;
  static String _intlVersionKey(String locale) => 'nINTL_VERSION_$locale';

  late LanguageSetting languageSetting;

  ArbTranslation get arbTranslation => languageSetting.arbTranslation;

  /// 语言包地址
  Future<String> _languageApi(String locale) async {
    return languageSetting.languageApi(locale);
  }

  /// 下载完的语言包内容（json）
  String downedJson = "";
  String defaultJson = "";

  Dio dio = Dio();
  late Directory arbDirectory;
  int tryTime = 0;

  static Map<String, ArbMessage?> messages = {};
  static Map<String, List<Object>>? messagesArgs;

  bool needReload = false;
  bool localLanguage = false;

  /// 生成 intl 目录，并设置[LanguageSetting]
  Future init(LanguageSetting setting) async {
    languageSetting = setting;
    var temDic = await getApplicationSupportDirectory();

    arbDirectory = Directory(temDic.path + "/$_kDicName")..create();
  }

  /// 文件地址
  String _getFilePath(String localeName) {
    return arbDirectory.path + "/${_kFileName}_$localeName.arb";
  }

  /// 根据arb文件生成Map, value 为特定的intl message 格式
  Map<String, dynamic>? generateMapFromArb(String localeName) {
    if (messages[localeName] != null) {
      return messages[localeName]!.messages;
    }

    File file = File(_getFilePath(localeName));
    ArbMessage? arbMessage;
    if (!file.existsSync()) {
      if (downedJson.isNotEmpty) {
        arbMessage = arbTranslation.parseFile(
            contentJson: downedJson, locale: localeName);
        messages[localeName] = arbMessage;
        if (localeName == _defaultLocale) {
          initializeDefaultArgs(contentJson: downedJson);
        }
      } else {
        return null;
      }
    } else {
      var content = file.readAsStringSync();
      arbMessage =
          arbTranslation.parseFile(contentJson: content, locale: localeName);
      messages[localeName] = arbMessage;
      if (localeName == _defaultLocale) {
        initializeDefaultArgs(contentJson: content);
      }
    }

    return arbMessage?.messages;
  }

  /// 根据arb文件生成对应args，[args]为每个文案的placeholders
  Map<String, List<Object>>? saveArgsFromArb(String localeName,
      {String? contentJson}) {
    if (messagesArgs != null) {
      return messagesArgs;
    }

    Map<String, List<Object>>? args;
    if (contentJson != null) {
      args = arbTranslation.parseFileForArgs(
          contentJson: contentJson, locale: localeName);
      messagesArgs = args;
      return args;
    }
    File file = File(_getFilePath(localeName));

    if (!file.existsSync()) {
      if (defaultJson.isNotEmpty) {
        args = arbTranslation.parseFileForArgs(
            contentJson: defaultJson, locale: localeName);
        messagesArgs = args;
      } else {
        return null;
      }
      return null;
    } else {
      args = arbTranslation.parseFileForArgs(file: file, locale: localeName);
      messagesArgs = args;
    }

    return args;
  }

  /// 保存版本号
  Future _saveVersion(String? version, String locale) async {
    if (version == null) {
      return;
    }
    var sp = await SharedPreferences.getInstance();
    return sp.setString(_intlVersionKey(locale), version);
  }

  Future _checkAndSaveArgs(String locale, [String? newVersion]) async {
    var sp = await SharedPreferences.getInstance();
    String? version = sp.getString(_intlVersionKey(locale));
    if (newVersion != null) {
      if (version != null && newVersion == version) {
        initializeDefaultArgs();
        return;
      }
    }
    String url = await _languageApi(locale);
    try {
      var res = await Dio().get(
        url,
      );
      if (res.data != null) {
        defaultJson = res.data;
        _saveToFile(defaultJson, version, localeName: locale);
      }
    } catch (e) {
      _log("缓存语言包失败");
    }
    initializeDefaultArgs();
  }

  /// 检查并下载/更新 语言包
  Future checkAndDownload(String locale, [String? newVersion]) async {
    var sp = await SharedPreferences.getInstance();
    String? version = sp.getString(_intlVersionKey(locale));
    // 如果不是en，则缓存一下en的
    if (locale != _defaultLocale) {
      _log("_checkAndSaveArgs");
      _checkAndSaveArgs(_defaultLocale, newVersion);
    }
    if (version != null && version.isNotEmpty) {
      return await _downArbJson(
          locale: locale, version: version, newVersion: newVersion);
    } else {
      return await _downArbJson(locale: locale);
    }
  }

  /// 获取语言包（json）
  Future _downArbJson(
      {required String locale, String? version, String? newVersion}) async {
    if (newVersion != null) {
      if (version != null && newVersion == version) {
        return;
      }
    }
    _log("** language ** version diff, begin download new arb");
    String url = await _languageApi(locale);
    _log("远程翻译文件链接：$url");
    try {
      var res = await Dio().get(
        url,
      );
      if (res.data != null) {
        downedJson = res.data;
        return await _saveToFile(downedJson, newVersion ?? '-1',
            localeName: locale, isAll: true);
      }
    } catch (e) {
      _log("获取语言包失败，使用默认文案 $e");
    }
  }

  /// 保存到文件
  /// isAll 目前都是true，false是差异更新情况
  Future _saveToFile(String contentJson, String? version,
      {required String localeName, bool isAll = true}) async {
    if (isAll) {
      try {
        File file = File(_getFilePath(localeName));
        if (file.existsSync()) {
          await file.delete();
        }
        IOSink slink = file.openWrite(mode: FileMode.append);
        slink.write('$contentJson\n');
        // await fs.writeAsString('$value');
        await slink.close();
        _saveVersion(version, localeName);
        messages.remove(localeName);
        updateLookupMessage(localeName);
      } catch (e) {
        // 写入错误
        _log(e.toString());
      }
    } else {
      Map<String, dynamic> m = json.decode(contentJson);
      m.removeWhere((key, value) => key.startsWith("@"));
      if (m.isEmpty) {
        return;
      }
      try {
        File file = File(_getFilePath(localeName));
        if (!file.existsSync()) {
          return null;
        }
        // 从文件中读取变量作为字符串，一次全部读完存在内存里面
        String contents = file.readAsStringSync();
        String result = _matchJson(contents, contentJson);
        IOSink slink = file.openWrite(mode: FileMode.writeOnly);
        slink.write('$result\n');
        // await fs.writeAsString('$value');

        await slink.close();
        _saveVersion(version, localeName);
        messages.remove(localeName);
        updateLookupMessage(localeName);
      } catch (e) {
        _log(e.toString());
      }
    }
    return;
  }

  /// 给json打补丁 （目前没有差异补丁，直接替换）
  /// 返回打完补丁后的文本显示
  String _matchJson(String oldJson, String newJson) {
    if (languageSetting.arbMergeEnable) {
      String result = mergeARBs(oldJson, newJson);
      return result;
    }
    return newJson;
  }

  /// 设置是否使用本地语言
  void setLocalLanguage(bool useLocal) async {
    var sp = await SharedPreferences.getInstance();
    sp.setBool(_kIntlLocaled, useLocal);
    localLanguage = useLocal;
  }

  /// 检查
  Future<bool> checkLocalLanguage() async {
    if (kReleaseMode) {
      return false;
    }
    var sp = await SharedPreferences.getInstance();
    var useLocal = sp.getBool(_kIntlLocaled);
    localLanguage = useLocal ?? false;
    return localLanguage;
  }

  /// 日志打印, 仅debug
  void _log(String msg) {
    if (!kDebugMode) {
      return;
    }
    log(msg, name: 'dynamic_intl');
  }
}
