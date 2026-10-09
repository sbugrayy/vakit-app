// Namaz vakitlerini ve Türkçe gösterim etiketlerini temsil eden enum.

enum Prayer {
  imsak('İmsak'),
  gunes('Güneş'),
  ogle('Öğle'),
  ikindi('İkindi'),
  aksam('Akşam'),
  yatsi('Yatsı');

  const Prayer(this.label);

  final String label;
}
