import 'package:flutter/material.dart';

// Uygulamanın tüm renkleri tek yerde. Bir rengi değiştirmek için sadece burayı değiştirmek yeterli.
class Renkler {
  static const lacivert = Color(0xFF101B35); // ana renk (başlıklar)
  static const mavi = Color(0xFF2563EB); // vurgu ve butonlar
  static const arkaPlan = Color(0xFFF4F6FA);
  static const kart = Colors.white;
  static const basari = Color(0xFF15803D); // yeşil
  static const hata = Color(0xFFDC2626); // kırmızı
  static const uyari = Color(0xFFF59E0B); // turuncu
  static const griYazi = Color(0xFF6B7280); // açıklama yazıları
}

// Beyaz, yuvarlatılmış köşeli, hafif gölgeli kart görünümü. Tüm kartlarda bunu kullanırız.
BoxDecoration kartDekorasyonu() {
  return BoxDecoration(
    color: Renkler.kart,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

// ThemeData: uygulamadaki tüm buton, yazı alanı vb. için varsayılan görünüm.
// Böylece her ekranda tek tek renk/boyut yazmamız gerekmez.
ThemeData uygulamaTemasi() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Renkler.mavi,
      primary: Renkler.mavi,
      error: Renkler.hata,
    ),
    scaffoldBackgroundColor: Renkler.arkaPlan,

    // Ana butonlar: mavi, en az 52 px yüksek, yuvarlatılmış köşeli.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Renkler.mavi,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Yazı alanları: beyaz dolgulu, yuvarlatılmış kenarlı.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Renkler.mavi, width: 2),
      ),
    ),
  );
}
