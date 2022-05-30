import 'package:dynamic_intl/dynamic_intl.dart';
import 'package:example/language/generated/l10n.dart';
import 'package:example/test_delegate.dart';
import 'package:example/test_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageUtil.instance.init(TestSetting());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static var locale = const Locale('zh');

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 可增加支持的语言列表
    // updateLanguageLibrary([const Locale('it'), const Locale('de')]);

    // 下载语言包，可以加版本, 无版本则每次都更新
    LanguageUtil.instance
        .checkAndDownload(MyApp.locale.languageCode, '1002')
        .then((value) {
      // 因为下载完成前会使用默认文案，下载完成后应刷新下UI
      setState(() {});
    });

    // 可以设置是否使用本地语言包
    // LanguageUtil.instance.setLocalLanguage(true);
    // 检查是否使用本地语言包
    LanguageUtil.instance.checkLocalLanguage();
  }

  void updateLocale(Locale locale) {
    MyApp.locale = locale;
    setState(() {});
  }

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
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.updateLocale})
      : super(key: key);

  final String title;
  final Function updateLocale;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).test),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              S.of(context).test,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _changeLocale,
        tooltip: MyApp.locale.languageCode,
        child: const Icon(Icons.all_inclusive),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
