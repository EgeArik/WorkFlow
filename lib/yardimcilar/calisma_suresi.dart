import '../modeller/hareket.dart';

// Bir dönemdeki toplam çalışma süresi = her "giriş" ile ondan sonraki "çıkış" arasındaki
// sürelerin toplamı. Bölüm değiştirmek (geçiş) süreyi bölmez: eski bölümden çıkış ve
// yeni bölüme giriş aynı anda olduğu için arada boşluk kalmaz.
//
// donemBitis: seçilen dönemin sonu (ör. "Dün" için bugün 00:00).
Duration toplamCalismaSuresi(
  List<Hareket> hareketler, {
  required DateTime donemBitis,
}) {
  // Zamanı henüz gelmemiş (sunucuya yeni yazılan) kayıtları atla, eskiden yeniye sırala.
  // Aynı anda olan kayıtlarda (geçiş) önce çıkış, sonra giriş gelsin; yoksa hesap karışır.
  final sirali = hareketler.where((h) => h.zaman != null).toList()
    ..sort((a, b) {
      final fark = a.zaman!.compareTo(b.zaman!);
      if (fark != 0) return fark;
      return (a.girisMi ? 1 : 0) - (b.girisMi ? 1 : 0); // çıkış önce
    });

  var toplam = Duration.zero;
  DateTime? acikGiris; // henüz çıkışı görülmemiş giriş zamanı
  for (final h in sirali) {
    if (h.girisMi) {
      acikGiris = h.zaman;
    } else if (acikGiris != null) {
      toplam += h.zaman!.difference(acikGiris);
      acikGiris = null;
    }
    // Girişi listede olmayan çıkış SAYILMAZ: ne zaman girildiği bilinmiyor.
    // (İlk denemede dönemin başından, 00:00'dan sayılıyordu; konsoldan elle yazılan
    // test girişi yüzünden 17 saatlik hatalı süre çıktı.) Bedeli: gece yarısını geçen
    // mesaide (23:00 giriş, 01:00 çıkış) "Bugün" filtresinde 00:00-01:00 arası sayılmaz.
  }
  // Son girişin çıkışı yoksa kişi hâlâ içeride: şu ana (veya dönem sonuna) kadar say.
  if (acikGiris != null) {
    final simdi = DateTime.now();
    final son = simdi.isBefore(donemBitis) ? simdi : donemBitis;
    if (son.isAfter(acikGiris)) toplam += son.difference(acikGiris);
  }
  return toplam;
}
