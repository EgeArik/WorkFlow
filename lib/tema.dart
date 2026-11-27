import 'package:flutter/material.dart';

import 'modeller/kullanici.dart' show turkceBuyukHarf;

// Uygulamanın tüm renkleri tek yerde. Bir rengi değiştirmek için sadece burayı değiştirmek yeterli.
// Renk paleti: petrol yeşili (ana renk), hardal sarısı (vurgu), krem (arka plan).
class Renkler {
  static const petrol = Color(
    0xFF0E4A4F,
  ); // ana renk: üst şerit, başlıklar, butonlar
  static const hardal = Color(
    0xFFD99A2B,
  ); // vurgu: QR butonu, logo, seçili sekme çizgisi
  static const arkaPlan = Color(0xFFF4EFE4); // krem
  static const kart = Color(0xFFFFFCF6); // kâğıt beyazı
  static const kenar = Color(0xFFE2D9C6); // kart ve liste çizgileri
  static const yazi = Color(0xFF1E2A2B); // normal yazı
  static const basari = Color(0xFF2E7D4F); // yeşil: giriş, içeride
  static const hata = Color(0xFFB4472F); // kiremit: çıkış, hata
  static const uyari = Color(0xFFC98A1B); // koyu hardal: bilgi mesajları
  static const griYazi = Color(0xFF6E6B60); // açıklama yazıları (sıcak gri)
}

// Kart görünümü: gölge yok, ince bir kenar çizgisi var. Tüm kartlarda bunu kullanırız.
BoxDecoration kartDekorasyonu() {
  return BoxDecoration(
    color: Renkler.kart,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Renkler.kenar),
  );
}

// Küçük bölüm başlıkları ("BUGÜN", "BÖLÜM DURUMU" gibi): büyük harf, harf aralıklı.
// Fabrika tabelası gibi bir his verir.
class KucukBaslik extends StatelessWidget {
  final String yazi;
  const KucukBaslik(this.yazi, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      turkceBuyukHarf(yazi),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2, // harfler arası boşluk
        color: Renkler.griYazi,
      ),
    );
  }
}

// ThemeData: uygulamadaki tüm buton, yazı alanı vb. için varsayılan görünüm.
// Böylece her ekranda tek tek renk/boyut yazmamız gerekmez.
ThemeData uygulamaTemasi() {
  const koseYuvarlak = 12.0;
  return ThemeData(
    // fontFamily: pubspec.yaml'a eklediğimiz Rubik yazı tipi tüm uygulamada kullanılır.
    fontFamily: 'Rubik',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Renkler.petrol,
      primary: Renkler.petrol,
      secondary: Renkler.hardal,
      // "Container" renkleri: Bölüm Ekle butonu ve seçili filtre düğmesi bunları kullanır.
      // Vermezsek Flutter kendi açık mavi tonunu üretiyordu.
      primaryContainer: Renkler.petrol,
      onPrimaryContainer: Colors.white,
      secondaryContainer: const Color(0xFFF3E2BF), // açık hardal
      onSecondaryContainer: Renkler.petrol,
      error: Renkler.hata,
      surface: Renkler.kart,
    ),
    scaffoldBackgroundColor: Renkler.arkaPlan,

    // Üst çubuklar: petrol renkli, gölgesiz.
    appBarTheme: const AppBarTheme(
      backgroundColor: Renkler.petrol,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),

    // Ana butonlar: petrol, en az 52 px yüksek.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Renkler.petrol,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(koseYuvarlak),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Renkler.petrol,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Renkler.kenar),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(koseYuvarlak),
        ),
      ),
    ),

    // Yazı alanları: kâğıt beyazı dolgulu, ince kenarlı.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Renkler.kart,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseYuvarlak),
        borderSide: const BorderSide(color: Renkler.kenar),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseYuvarlak),
        borderSide: const BorderSide(color: Renkler.kenar),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseYuvarlak),
        borderSide: const BorderSide(color: Renkler.petrol, width: 2),
      ),
    ),

    // Alt menü: kâğıt beyazı; seçili sekmenin ikonu petrol, arkasında hardal hap.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Renkler.kart,
      elevation: 0,
      indicatorColor: Renkler.hardal.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (durum) => TextStyle(
          fontFamily: 'Rubik',
          fontSize: 12,
          fontWeight: durum.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: durum.contains(WidgetState.selected)
              ? Renkler.petrol
              : Renkler.griYazi,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (durum) => IconThemeData(
          color: durum.contains(WidgetState.selected)
              ? Renkler.petrol
              : Renkler.griYazi,
        ),
      ),
    ),

    // Sekme çubuğu (Yönetim): seçili sekmenin altında hardal çizgi.
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFFBCD3D2),
      indicatorColor: Renkler.hardal,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w500),
    ),

    // Filtre çipleri: seçili olan petrol dolgulu.
    chipTheme: ChipThemeData(
      backgroundColor: Renkler.kart,
      selectedColor: Renkler.petrol,
      side: const BorderSide(color: Renkler.kenar),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(color: Renkler.yazi),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
    ),

    dividerTheme: const DividerThemeData(color: Renkler.kenar, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
