import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/message_lookup_by_library.dart';

import '../messages_manage.dart';

/// 对 arb 文件内容的解析 使intl能够使用
/// arb 规则说明：https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification
/// 目前仅使用了简单的无@描述形式，也无ICU语法，所以仅解析了message规则的，可重写对应规则增加需要的
/// @author jm
class ArbTranslation {
  final RegExp _regExp = RegExp(r"{\w*}");

  /// arb文件解析
  /// message(String messageText,
  ///           {String desc = '',
  ///           Map<String, Object> examples,
  ///           String locale,
  ///           String name,
  ///           List<Object> args,
  ///           String meaning,
  ///           bool skip})
  ArbMessage? parseFile(
      {File? file, String? contentJson, required String locale}) {
    assert(file != null || contentJson != null);
    String content;
    if (contentJson != null) {
      content = contentJson;
    } else {
      content = file!.readAsStringSync();
    }
    if (content.isEmpty) {
      return null;
    }
    try {
      Map<String, dynamic> oriMap = json.decode(content);
      if (oriMap.isEmpty) {
        return null;
      }

      Map<String, dynamic> messages = oriMap.map((key, value) {
        if (key.startsWith("@")) {
          return MapEntry(key, value);
        }
        if (value is String) {
          return MapEntry(key, _decodeMessage(key, value, oriMap['@$key']));
        }

        return MapEntry(
            key, MessageLookupByLibrary.simpleMessage(value.toString()));
      });
      // 移除注释信息
      messages.removeWhere((key, value) => key.startsWith("@"));
      ArbMessage arbMessage = ArbMessage(
        messages: messages,
        lastModified: oriMap['@@version'] ?? "",
        locale: locale,
      );

      _log("** language ** parsing success!");
      return arbMessage;
    } catch (e) {
      _log(e.toString());
    }
    return null;
  }

  /// 解析生成对应的args
  Map<String, List<Object>>? parseFileForArgs(
      {File? file, String? contentJson, required String locale}) {
    assert(file != null || contentJson != null);
    String content;
    if (contentJson != null) {
      content = contentJson;
    } else {
      content = file!.readAsStringSync();
    }
    if (content.isEmpty) {
      return null;
    }
    Map<String, dynamic> oriMap = json.decode(content);

    Map<String, List<Object>> messages = oriMap.map((key, value) {
      List<String> listUrl = [];
      RegExp regExp = _regExp;
      Iterable<Match> matches = regExp.allMatches(value);
      if (matches.isNotEmpty) {
        listUrl = List<String>.from(matches
            .map((e) => e.group(0) == null
                ? ""
                : e.group(0)!.substring(1, e.group(0)!.length - 1))
            .toList());
        listUrl.remove("");
        listUrl = listUrl.toSet().toList();
      }

      return MapEntry(key, listUrl);
    });
    messages.removeWhere((key, value) => value.isEmpty);
    return messages;
  }

  /// 解析Message数据，判断是否有占位符情况
  Function _decodeMessage(String key, String value,
      [Map<String, dynamic>? oriMap]) {
    List<String> listUrl = [];
    List<String> placeholders = [];
    RegExp regExp = _regExp;
    Iterable<Match> matches = regExp.allMatches(value);
    if (matches.isNotEmpty) {
      listUrl =
          List<String>.from(matches.map((e) => e.group(0) ?? "").toList());
      listUrl.remove("");
      listUrl = listUrl.toSet().toList();
      Map<String, dynamic>? placeholdersMap = oriMap?['placeholders'];
      if (placeholdersMap?.isNotEmpty ?? false) {
        placeholders = placeholdersMap!.keys.toList();
      } else {
        placeholders =
            listUrl.map((e) => e.substring(1, e.length - 1)).toList();
      }
    }

    return (
        [value1,
        value2,
        value3,
        value4,
        value5,
        value6,
        value7,
        value8,
        value9,
        value10]) {
      return _delText(key, value, listUrl, placeholders, value1, value2, value3,
          value4, value5, value6, value7, value8, value9, value10);
    };
  }

  /// 替换相应数据
  String _delText(String key, String value, List<String> listUrl,
      [List<String>? placeholders,
      dynamic value1,
      dynamic value2,
      dynamic value3,
      dynamic value4,
      dynamic value5,
      dynamic value6,
      dynamic value7,
      dynamic value8,
      dynamic value9,
      dynamic value10]) {
    String result = value;
    RegExp regExp = _regExp;
    if (listUrl.isNotEmpty) {
      result = result.replaceAllMapped(regExp, (match) {
        var args = getLookupArgs(key);
        if (args.isEmpty) {
          args = placeholders!;
        }
        int index = args.indexWhere((e) =>
            e == match.group(0)!.substring(1, match.group(0)!.length - 1));
        switch (index) {
          case 0:
            return "$value1";
          case 1:
            return "$value2";
          case 2:
            return "$value3";
          case 3:
            return "$value4";
          case 4:
            return "$value5";
          case 5:
            return "$value6";
          case 6:
            return "$value7";
          case 7:
            return "$value8";
          case 8:
            return "$value9";
          case 9:
            return "$value10";
          default:
            return "${match.group(0)}";
        }
      });
    }

    return result;
  }

  /// 日志打印, 仅debug
  void _log(String msg) {
    if (!kDebugMode) {
      return;
    }
    log(msg, name: 'dynamic_intl');
  }
}

class ArbMessage {
  final Map<String, dynamic> messages;
  final String lastModified;
  final String locale;

  const ArbMessage({
    required this.messages,
    this.lastModified = "",
    required this.locale,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messages': messages,
      'last_modified': lastModified,
      'locale': locale,
    };
  }
}
