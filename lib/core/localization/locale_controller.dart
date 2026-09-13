import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/localization/app_language.dart';
import 'package:projectnbx/core/localization/app_strings.dart';

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.pt);

  void setLanguage(AppLanguage language) {
    state = language;
  }

  void toggleLanguage() {
    state = state == AppLanguage.pt ? AppLanguage.en : AppLanguage.pt;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(localeProvider);
  return AppStrings(language);
});
