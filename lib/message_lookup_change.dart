// ignore_for_file: implementation_imports

import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

class MessageLookupChange implements MessageLookup {
  /// A map from locale names to the corresponding lookups.
  Map<String, MessageLookupByLibrary> availableMessages = {};
  Map<String, List<Object>> defaultArgsMap = {};

  /// Return true if we have a message lookup for [localeName].
  bool localeExists(localeName) => availableMessages.containsKey(localeName);

  /// The last locale in which we looked up messages.
  ///
  ///  If this locale matches the new one then we can skip looking up the
  ///  messages and assume they will be the same as last time.
  String? _lastLocale;

  /// Caches the last messages that we found
  MessageLookupByLibrary? _lastLookup;

  /// Look up the message with the given [name] and [locale] and return the
  /// translated version with the values in [args] interpolated.  If nothing is
  /// found, return the result of [ifAbsent] or [messageText].
  @override
  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    // If passed null, use the default.
    var knownLocale = locale ?? Intl.getCurrentLocale();
    var messages = (knownLocale == _lastLocale)
        ? _lastLookup
        : _lookupMessageCatalog(knownLocale);
    // If we didn't find any messages for this locale, use the original string,
    // faking interpolations if necessary.
    if (messages == null) {
      return ifAbsent == null ? messageText : ifAbsent(messageText, args);
    }
    return messages.lookupMessage(messageText, locale, name, args, meaning,
        ifAbsent: ifAbsent);
  }

  /// Find the right message lookup for [locale].
  MessageLookupByLibrary? _lookupMessageCatalog(String locale) {
    var verifiedLocale = Intl.verifiedLocale(locale, localeExists,
        onFailure: (locale) => locale);
    _lastLocale = locale;
    _lastLookup = availableMessages[verifiedLocale];
    return _lastLookup;
  }

  /// If we do not already have a locale for [localeName] then
  /// [findLocale] will be called and the result stored as the lookup
  /// mechanism for that locale.
  @override
  void addLocale(String localeName, Function findLocale) {
    if (localeExists(localeName)) return;
    var canonical = Intl.canonicalizedLocale(localeName);
    var newLocale = findLocale(canonical);
    if (newLocale != null) {
      availableMessages[localeName] = newLocale;
      availableMessages[canonical] = newLocale;
      // If there was already a failed lookup for [newLocale], null the cache.
      if (_lastLocale == newLocale) {
        _lastLocale = null;
        _lastLookup = null;
      }
    }
  }

  /// 清空 [availableMessages] 並且重新 [addLocale], [findLocale] 會清空後
  /// 在addLocale中調用
  void clearAndAddLocale(String localeName, Function findLocale) {
    availableMessages.remove(localeName);
    _lastLocale = null;
    _lastLookup = null;
    addLocale(localeName, findLocale);
  }

  /// 报错默认数据
  void saveDefaultMessage(String localeName, Function findLocale,
      {String? contentJson}) {
    var map = findLocale(localeName, contentJson: contentJson);
    if (map != null) {
      defaultArgsMap = map;
    } else {
      log("默认文案localeName 无法成功获取，可能为空", name: 'dynamic_intl');
    }
  }

  /// 根据 [defaultLocale] 和 [name] 拿到对应的args
  /// [defaultLocale] 应该是用来生成[l10n.dart 的那个默认locale
  List<Object> getArgs(String name) {
    if (defaultArgsMap[name] != null) {
      return defaultArgsMap[name]!;
    }
    return [];
  }
}
