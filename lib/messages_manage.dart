// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names, unnecessary_new
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'message_lookup_change.dart';
import 'messages_library.dart' as messages_messages;
import 'tools/language_util.dart';

typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> get _deferredLibraries =>
    LanguageUtil.instance.languageSetting.deferredLibraries;

List<Locale> supportedLocalesLibraries = [
  const Locale.fromSubtags(languageCode: 'en'),
  const Locale.fromSubtags(languageCode: 'zh'),
];

/// 更新语言library
updateLanguageLibrary(List<Locale> languages) {
  List<Locale> tem = List.from(languages);
  tem.removeWhere(
      (element) => _deferredLibraries.containsKey(element.languageCode));
  for (var element in tem) {
    _deferredLibraries[element.languageCode] =
        () => Future<dynamic>.value(null);
  }
  supportedLocalesLibraries
      .addAll(tem.map((e) => Locale.fromSubtags(languageCode: e.languageCode)));
}

MessageLookupByLibrary? _findExact(String localeName) {
  Map<String, dynamic>? messages =
      LanguageUtil.instance.generateMapFromArb(localeName);
  if (messages == null || LanguageUtil.instance.localLanguage) {
    // 无法成功读取，使用本地语言包
    return LanguageUtil.instance.languageSetting
        .defaultLocaleMessages(localeName);
  }
  return messages_messages.MessageLookup(messages, localeName);
}

Map<String, List<Object>>? _findArgs(localeName, {String? contentJson}) {
  var args = LanguageUtil.instance
      .saveArgsFromArb(localeName, contentJson: contentJson);
  return args;
}

void updateLookupMessage(String localeName) {
  if (messageLookup is MessageLookupChange) {
    (messageLookup as MessageLookupChange)
        .clearAndAddLocale(localeName, _findGeneratedMessagesFor);
  }
}

List<Object> getLookupArgs(String name) {
  if (messageLookup is MessageLookupChange) {
    // 默认 en，根据en的规则拿到args
    return (messageLookup as MessageLookupChange).getArgs(name);
  }
  return [];
}

Future initializeDefaultArgs({String? contentJson}) async {
  if (messageLookup is MessageLookupChange) {
    // 默认 en，根据en的规则拿到args
    return (messageLookup as MessageLookupChange)
        .saveDefaultMessage('en', _findArgs, contentJson: contentJson);
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeDynamicMessages(String localeName) async {
  var availableLocale = Intl.verifiedLocale(
      localeName, (locale) => _deferredLibraries[locale] != null,
      onFailure: (_) => null);
  if (availableLocale == null) {
    return new Future.value(false);
  }
  initializeInternalMessageLookup(() => MessageLookupChange());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  return Future.value(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(
  String locale,
) {
  var actualLocale =
      Intl.verifiedLocale(locale, _messagesExistFor, onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(locale);
}
