import 'package:dynamic_intl/dynamic_intl.dart';
import 'package:example/language/generated/l10n.dart';

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
