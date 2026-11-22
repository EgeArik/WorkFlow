// Saat ve süreleri ekranda göstermek için küçük yardımcı fonksiyonlar.

// DateTime -> "09:05"
String saatYaz(DateTime zaman) {
  // padLeft(2, '0'): tek haneli sayının başına 0 ekler (9 -> "09").
  final saat = zaman.hour.toString().padLeft(2, '0');
  final dakika = zaman.minute.toString().padLeft(2, '0');
  return '$saat:$dakika';
}

// Duration (süre) -> "2 sa 30 dk", "45 dk" veya "1 dk'dan az"
String sureYaz(Duration sure) {
  final saat = sure.inHours;
  final dakika =
      sure.inMinutes % 60; // "%" = bölümden kalan: 150 dk -> 2 saat ve 30 dk
  if (saat > 0) return '$saat sa $dakika dk';
  if (dakika > 0) return '$dakika dk';
  return "1 dk'dan az";
}

const _aylar = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];
const _gunler = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

// DateTime -> "22 Kasım Pazar". (month 1-12, weekday 1=Pazartesi ... 7=Pazar)
String gunBasligi(DateTime zaman) =>
    '${zaman.day} ${_aylar[zaman.month - 1]} ${_gunler[zaman.weekday - 1]}';

// Sadece tarih kısmı (saat 00:00). İki kaydın aynı günde olup olmadığını anlamak için.
DateTime gunBaslangici(DateTime zaman) =>
    DateTime(zaman.year, zaman.month, zaman.day);
