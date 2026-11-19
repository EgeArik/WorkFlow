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
  final dakika = sure.inMinutes % 60; // "%" = bölümden kalan: 150 dk -> 2 saat ve 30 dk
  if (saat > 0) return '$saat sa $dakika dk';
  if (dakika > 0) return '$dakika dk';
  return "1 dk'dan az";
}
