## Description
基于原[intl](https://github.com/dart-lang/intl)和[flutter_intl](https://plugins.jetbrains.com/plugin/13666-flutter-intl)自动生成插件，使原先固定的arb变为**可动态化更新**的模式。也可以不用`flutter_intl`，默认的只要格式正确也是一样的。

支持通过版本变更来更新，以及arb**增量更新**。并且可以动态增加**支持的语言**并及时应用。

## Installing
```dart
dependencies:
  dynamic_intl: ^0.1.0
```

Import it
```dart
  import 'package:dynamic_intl/dynamic_intl.dart';
```


## 初始化以及配置
继承`LanguageSetting`来配置对应的设置。首要就是设置对应的**资源远程链接**，还可以配置**缓存的目录、文件名**等。
```dart
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
```
`defaultLocale`为默认的语言，最好跟`flutter_intl`中设置的保持一致。会根据这个默认语言来决定各个文案的**占位符**，很重要。
`deferredLibraries`是**支持的语言列表**，格式跟官方`intl`中自动生成的一样，下边的`checkAndDownload`可以放在这里，那么在加载对应语言时就可以触发检查下载。

还可以设置在远程资源**失效或没有正常获得**的时候，备用的**本地语言包**，格式也是跟官方的一致。
```dart
import 'package:lib/generated/intl/messages_zh.dart' as messages_zh;
import 'package:lib/generated/intl/messages_en.dart' as messages_en;

  @override
  MessageLookupByLibrary? defaultLocaleMessages(String localeName) {
    switch (localeName) {
      case 'zh':
        return messages_zh.messages;
      case 'en':
        return messages_en.messages;
      default:
        return null;
    }
  }
```

### 本地语言包示例
`flutter_intl`的配置：
```yaml
flutter_intl:
  enabled: true
```
按照官方的来即可，也可以自己配置路径什么的（example中的配置了language路径下）。
![IMG_2](https://user-images.githubusercontent.com/48596516/170999425-ea81bee0-cac0-4046-9ad2-a9cf8b6251f5.png)
自动生成的文件（`generated`下的）不需要去手动修改，`messages_all`已经不会用到。`messages_en`等，可以作为**本地备用资源**，在远程资源失败时可做备用。`l10n.dart`需要记住其中的类，后续需要注册到`delegate`中，但**不要用**它自己里面的`delegate`。
![IMG_3](https://user-images.githubusercontent.com/48596516/170999487-cbf838d7-6804-4299-b025-123888d95466.png)

`l10n`目录下的为语言包，即本地的，尽量跟远程**同步**，修改后及时更新到远程中或随版本更新。格式就简单的`json`，根据**文件名区分**语言。
```json
{
  "test": "test title"
}
```


### Arb转译器
目前**arb的转译**仅支持普通的`Intl.message`，且最多十个**占位符**（各规则可参考[ApplicationResourceBundleSpecification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)），如果有需要想支持`plural`、`gender`等，或者需要更多占位符，可以继承`ArbTraslation`，并重写`parseFile`。相应的写法可自行查看代码。然后设置到`LanguageSetting`中。
```dart
  @override
  ArbTranslation arbTranslation = NewArbTranslation();
```

### 开启arb增量更新
若是觉得语言包体积过于庞大，可以配合服务端做**增量更新**。即服务端把‘增量’返回，客户端会进行`merge`并更新（不会移除旧的）。
默认为`false`，需设置为`true`。
```dart
  @override
  bool get arbMergeEnable => true;
```

### 在`runApp`前初始化完成
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageUtil.instance.init(TestSetting());
  runApp(const MyApp());
}
```
使用多语言，`WidgetsFlutterBinding.ensureInitialized()`也是需要的。

## 注册到MaterialApp
`locale`可自行控制，需要配置的主要是`localizationsDelegates`和`supportedLocales`。可继承`BaseLocalizationsDynamicDelegate<T>`（`T` 即为`flutter_intl`自动生成的类，默认是`S`， 具体由你决定）来获取最简单的`Delegate`。有自己想法的也可以自行编写，并重写`supportedLocales`和在`load`中使用`initializeDynamicMessages`。
```dart
class AppLocalizationDynamicDelegate
    extends BaseLocalizationsDynamicDelegate<S> {
  const AppLocalizationDynamicDelegate();

  static const AppLocalizationDynamicDelegate delegate =
      AppLocalizationDynamicDelegate();

  @override
  Future<S> loadS() {
    final instance = S();

    return Future.value(instance);
  }
}
```
按照上边的写法即可。然后设置到`MaterialApp`中
```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      /// 当前语言
      locale: MyApp.locale,
      localizationsDelegates: const [
        /// Delegate 注册
        AppLocalizationDynamicDelegate.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      /// 支持的语言列表
      supportedLocales:
          AppLocalizationDynamicDelegate.delegate.supportedLocales,
      home: MyHomePage(
          title: 'Flutter Demo Home Page', updateLocale: updateLocale),
    );
  }
```
在**自定**支持语言列表时，这三个`delegate`也是需要的，系统功能的多语言支持，记得也加上。
```dart
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
```
它们需要`flutter_localizations`
```yaml
  flutter_localizations: # Add this line
    sdk: flutter
```

## 触发检查下载
通过`Future checkAndDownload(String locale, [String? newVersion])`可下载**指定语言指定版本**的语言包（版本不同则会更新）。下载完成之后可刷新UI来展示最新文案。切换语言也应该调用该方法，已存在语言包则会跳过。
```dart
    // 下载语言包，可以加版本, 无版本则每次都更新
    LanguageUtil.instance
        .checkAndDownload(MyApp.locale.languageCode, '1002')
        .then((value) {
      // 因为下载完成前会使用默认文案，下载完成后应刷新下UI
      setState(() {});
    });
```
若当前下载的不是默认语言，且默认语言包也没有下载保存过，那么会先**下载默认语言包**。

版本管理需要**自行设计**，这里仅根据传入的版本对比来更新。

## 增加支持的语言列表
可通过`updateLanguageLibrary`动态**新增支持的语言列表**。
```dart
updateLanguageLibrary([const Locale('it'), const Locale('de')]);
```
若`Setting`中没有，则可以先检查**远程列表**然后通过该方法新增，新增后才可以有效切换。

## 关闭远程仅使用本地
`setLocalLanguage`设置为`true`，则会无视远程语言包，直接使用**本地的语言包**，确认`defaultLocaleMessages`正常配置。
```dart
LanguageUtil.instance.setLocalLanguage(true);
```

## 使用文案
即普通的`S.of(context).text`，觉得需要`context`太麻烦，可以在`MaterialApp`下`build`的时候注册一个全局`context`（参考GetX的全局context），一样用。
```dart
Text(S.of(context).test)

/// 带占位符
S.of(context).textPlace(‘123’)
```

## 切换语言
修改`MaterialApp`的`locale`，然后检查语言包下载，最后**刷新UI**即可。需要刷新到`MaterialApp`这一层，可以看看`example`中的示例。
```dart
  void _changeLocale() async {
    var locale = MyApp.locale.languageCode == 'en'
        ? const Locale('zh')
        : const Locale('en');
    LanguageUtil.instance
        .checkAndDownload(locale.languageCode, '1002')
        .then((_) {
      // 因为下载前会使用默认文案，下载完成后应刷新下UI
      widget.updateLocale(locale);
    });
  }
```

## 最后
翻译的文件有@开头的注释消息，也没有问题，只不过默认的`ArbTranslation`不会处理。`LanguageSetting`可以在你的管理类里面继承，建议`S`也重新再套一层再使用，方便维护。检查下载和切换可以根据实际需求来，全部都一起下载也不是不可以，也可以配置在`deferredLibraries`中随系统切换时**自动同步检查下载**。

`example`中有个比较简单的可以直接运行的例子，可供参考。有什么问题的话可以直接提issue。
