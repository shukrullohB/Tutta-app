class Language {
  final String code;
  final String name;
  final String flag;

  const Language(this.code, this.name, this.flag);
}

const supportedLanguages = [
  Language('en', 'English', '🇬🇧'),
  Language('uz', "O'zbekcha", '🇺🇿'),
  Language('ru', 'Русский', '🇷🇺'),
];
