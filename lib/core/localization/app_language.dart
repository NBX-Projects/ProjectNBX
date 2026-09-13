enum AppLanguage {
  pt(
    code: 'pt',
    name: 'Português (Brasil)',
    flag: '🇧🇷',
  ),
  en(
    code: 'en',
    name: 'English (US)',
    flag: '🇺🇸',
  );

  final String code;
  final String name;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });
}
