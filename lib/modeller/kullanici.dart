import 'package:cloud_firestore/cloud_firestore.dart';

// Model: Firestore'dan gelen ham veriyi (Map) düzenli bir Dart nesnesine çeviren sınıf.
// Böylece ekranlarda veri['adSoyad'] yerine kullanici.adSoyad yazarız; yazım hatası yapınca
// program daha çalışmadan uyarır.
class Kullanici {
  final String uid;
  final String adSoyad;
  final String eposta;
  final String gorev;
  final String rol; // "personel" veya "yonetici"
  final String?
  suAnkiBolumId; // "?" = boş (null) olabilir: kişi hiçbir bölümde değilse null
  final String? suAnkiBolumAdi;
  final DateTime? girisZamani;

  const Kullanici({
    required this.uid,
    required this.adSoyad,
    required this.eposta,
    required this.gorev,
    required this.rol,
    this.suAnkiBolumId,
    this.suAnkiBolumAdi,
    this.girisZamani,
  });

  // factory constructor: hazır veriden (Firestore dokümanı) nesne üreten özel kurucu.
  factory Kullanici.firestoredan(
    DocumentSnapshot<Map<String, dynamic>> dokuman,
  ) {
    final veri = dokuman.data()!;
    return Kullanici(
      uid: dokuman.id,
      adSoyad:
          veri['adSoyad'] as String? ??
          '', // "??" = soldaki null ise sağdakini kullan
      eposta: veri['eposta'] as String? ?? '',
      gorev: veri['gorev'] as String? ?? '',
      rol: veri['rol'] as String? ?? 'personel',
      suAnkiBolumId: veri['suAnkiBolumId'] as String?,
      suAnkiBolumAdi: veri['suAnkiBolumAdi'] as String?,
      // Firestore zamanı "Timestamp" olarak saklar; toDate() ile Dart'ın DateTime'ına çeviririz.
      girisZamani: (veri['girisZamani'] as Timestamp?)?.toDate(),
    );
  }

  // Getter: hesaplanan özellik. Alan gibi okunur (kullanici.yoneticiMi) ama saklanmaz.
  bool get yoneticiMi => rol == 'yonetici';
  bool get icerideMi => suAnkiBolumId != null;

  // "Ege Arık" -> "EA". Avatar dairesinde gösterilir.
  String get basHarfler {
    final parcalar = adSoyad
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parcalar.isEmpty) return '?';
    final ilk = parcalar.first[0];
    final son = parcalar.length > 1 ? parcalar.last[0] : '';
    return turkceBuyukHarf(ilk + son);
  }
}

// Dart'ın toUpperCase() fonksiyonu "i" harfini "I" yapar; Türkçede "İ" olmalı.
String turkceBuyukHarf(String metin) =>
    metin.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
