class ZiyaraData {
  static const String title = 'زيارة الإمام علي (ع)';
  static const String titleEn = 'Ziyarat Imam Ali (AS)';

  static const List<ZiyaraSection> sections = [
    ZiyaraSection(
      arabicText:
          'السَّلامُ عَلَيْكَ يا وَلِيَّ اللهِ\n'
          'السَّلامُ عَلَيْكَ يا حُجَّةَ اللهِ\n'
          'السَّلامُ عَلَيْكَ يا نُورَ اللهِ فِي ظُلُماتِ الأَرضِ\n'
          'السَّلامُ عَلَيْكَ يا عَمُودَ الدِّينِ\n'
          'وَوارِثَ عِلْمِ الأَوَّلِينَ وَالآخِرِينَ',
      translation:
          'Peace be upon you, O Guardian of Allah.\n'
          'Peace be upon you, O Proof of Allah.\n'
          'Peace be upon you, O Light of Allah in the darkness of the earth.\n'
          'Peace be upon you, O pillar of the religion\n'
          'and heir to the knowledge of the first and the last.',
    ),
    ZiyaraSection(
      arabicText:
          'أَشْهَدُ أَنَّكَ قَدْ أَقَمْتَ الصَّلاةَ\n'
          'وَآتَيْتَ الزَّكاةَ وَأَمَرْتَ بِالْمَعْرُوفِ\n'
          'وَنَهَيْتَ عَنِ الْمُنْكَرِ وَعَبَدْتَ اللهَ مُخْلِصاً\n'
          'حَتَّى أَتاكَ الْيَقِينُ',
      translation:
          'I bear witness that you established prayer,\n'
          'gave zakah, commanded good\n'
          'and forbade evil, and worshipped Allah sincerely\n'
          'until death came to you.',
    ),
    ZiyaraSection(
      arabicText:
          'يا أمِيرَ الْمُؤمِنينَ\n'
          'أَنَا وَلِيٌّ لِمَنْ والاكَ\n'
          'وَعَدُوٌّ لِمَنْ عاداكَ\n'
          'وَأَتَقَرَّبُ إِلَى اللهِ تَعالى بِوَلايَتِكَ',
      translation:
          'O Commander of the Faithful,\n'
          'I am a friend of whoever befriends you\n'
          'and an enemy of whoever is your enemy,\n'
          'and I draw close to Allah through love of you.',
    ),
    ZiyaraSection(
      arabicText:
          'اَللّهُمَّ اجْعَلْني عِنْدَكَ وَجِيهاً\n'
          'بِحُبِّ عَلِيٍّ وَآلِ عَلِيٍّ\n'
          'وَاحْشُرْنِي مَعَهُمْ يَوْمَ الْقِيامَةِ',
      translation:
          'O Allah, make me honorable in Your sight\n'
          'through the love of Ali and the family of Ali,\n'
          'and resurrect me with them on the Day of Judgment.',
    ),
    ZiyaraSection(
      arabicText:
          'السَّلامُ عَلَيْكَ يا أمِيرَ الْمُؤمِنِينَ\n'
          'وَرَحْمَةُ اللهِ وَبَرَكاتُهُ\n'
          'صَلَّى اللهُ عَلَيْكَ وَعَلى آلِ بَيْتِكَ الطَّاهِرِينَ',
      translation:
          'Peace be upon you, O Commander of the Faithful,\n'
          'and the mercy and blessings of Allah.\n'
          'May Allah\'s blessings be upon you and upon your purified household.',
    ),
  ];
}

class ZiyaraSection {
  final String arabicText;
  final String translation;

  const ZiyaraSection({
    required this.arabicText,
    required this.translation,
  });
}
