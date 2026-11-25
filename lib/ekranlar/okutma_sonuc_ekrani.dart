import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/kullanici.dart' show turkceBuyukHarf;
import '../servisler/hareket_servisi.dart';
import '../tema.dart';
import '../yardimcilar/zaman_bicimi.dart';

// Okutmadan sonra 2,5 saniye görünen tam ekran sonuç.
// Ya "sonuc" (başarılı) ya da "hata" dolu gelir.
class OkutmaSonucEkrani extends StatefulWidget {
  final OkutmaSonucu? sonuc;
  final OkutmaHatasi? hata;

  const OkutmaSonucEkrani({super.key, this.sonuc, this.hata});

  @override
  State<OkutmaSonucEkrani> createState() => _OkutmaSonucEkraniState();
}

class _OkutmaSonucEkraniState extends State<OkutmaSonucEkrani> {
  Timer? _kapatmaZamanlayicisi;

  @override
  void initState() {
    super.initState();
    // Timer (tek seferlik): 2,5 saniye sonra ekranı kendiliğinden kapatır.
    _kapatmaZamanlayicisi = Timer(const Duration(milliseconds: 2500), _kapat);
  }

  void _kapat() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _kapatmaZamanlayicisi?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = _gorunum();
    return Scaffold(
      backgroundColor: g.renk,
      // GestureDetector: ekranın herhangi bir yerine dokununca hemen kapatır.
      body: GestureDetector(
        onTap: _kapat,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          // Yazılar sola yaslı, ekranın ortasında; tabela gibi büyük ve net.
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beyaz çerçeveli kare içinde ikon
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(g.ikon, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 28),
                Text(
                  turkceBuyukHarf(g.ust),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  g.baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                for (final satir in g.satirlar)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      satir,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                const SizedBox(height: 40),
                const Text(
                  'Kapatmak için ekrana dokunun',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sonuca göre renk, ikon ve yazıları seçer.
  _Gorunum _gorunum() {
    final hata = widget.hata;
    if (hata != null) {
      return _Gorunum(
        renk: hata.bilgi ? Renkler.uyari : Renkler.hata,
        ikon: hata.bilgi ? Icons.info_outline : Icons.error_outline,
        ust: hata.bilgi ? 'Bilgi' : 'Hata',
        baslik: hata.bilgi ? 'Kayıt yapılmadı' : 'Okutma başarısız',
        satirlar: [hata.mesaj],
      );
    }
    final s = widget.sonuc!;
    final saat = saatYaz(s.zaman);
    // Not: Bölüm adları "A Bölümü", "Yemekhane" gibi her şey olabilir. "-e/-den" ekleri
    // her ada doğru uymayacağı için adı ayrı satırda, eksiz gösteriyoruz.
    switch (s.tur) {
      case OkutmaTuru.giris:
        return _Gorunum(
          renk: Renkler.basari,
          ikon: Icons.login,
          ust: 'Hoş geldiniz',
          baslik: s.bolumAdi,
          satirlar: [
            'Giriş kaydedildi · $saat',
            'Çıkış için aynı QR kodu tekrar okutun.',
          ],
        );
      case OkutmaTuru.cikis:
        return _Gorunum(
          renk: Renkler.petrol,
          ikon: Icons.logout,
          ust: 'Çıkış yapıldı',
          baslik: s.bolumAdi,
          satirlar: ['Çıkış kaydedildi · $saat'],
        );
      case OkutmaTuru.gecis:
        return _Gorunum(
          renk: Renkler.basari,
          ikon: Icons.swap_horiz,
          ust: 'Bölüm değişti',
          baslik: '${s.eskiBolumAdi} → ${s.bolumAdi}',
          satirlar: [
            '${s.eskiBolumAdi}: otomatik çıkış',
            '${s.bolumAdi}: giriş · $saat',
          ],
        );
    }
  }
}

class _Gorunum {
  final Color renk;
  final IconData ikon;
  final String ust; // küçük üst yazı ("Hoş geldiniz")
  final String baslik; // büyük yazı (bölüm adı)
  final List<String> satirlar;
  const _Gorunum({
    required this.renk,
    required this.ikon,
    required this.ust,
    required this.baslik,
    required this.satirlar,
  });
}
