import 'package:flutter/material.dart';

import '../modeller/hareket.dart';
import '../tema.dart';
import '../yardimcilar/zaman_bicimi.dart';
import 'rozet.dart';

// Hareketleri dikey zaman çizelgesi olarak gösterir:
//   09:12  ●  A Bölümü      [Giriş]
//          │
//   10:30  ●  A Bölümü      [Çıkış]
// Farklı günlere ait kayıtlar gün başlıklarıyla ("22 Kasım Pazar") ayrılır.
// Hem personel Geçmiş ekranında hem (Gün 6'da) yönetici Hareketler ekranında kullanılır.
class HareketZamanCizelgesi extends StatelessWidget {
  final List<Hareket> hareketler; // en yeniden eskiye sıralı gelir
  final bool gunBasliklariGoster;

  const HareketZamanCizelgesi({
    super.key,
    required this.hareketler,
    this.gunBasliklariGoster = true,
  });

  // Hareket türüne göre renk: giriş yeşil, çıkış kiremit, otomatik çıkış hardal.
  static Color turRengi(Hareket h) => switch (h.tur) {
    'giris' => Renkler.basari,
    'cikis' => Renkler.hata,
    _ => Renkler.uyari,
  };

  @override
  Widget build(BuildContext context) {
    // Satırları sırayla oluştururuz; gün değiştiğinde araya bir gün başlığı ekleriz.
    final satirlar = <Widget>[];
    DateTime? oncekiGun;
    for (var i = 0; i < hareketler.length; i++) {
      final h = hareketler[i];
      final gun = h.zaman != null ? gunBaslangici(h.zaman!) : null;
      if (gunBasliklariGoster && gun != null && gun != oncekiGun) {
        satirlar.add(_GunBasligi(gun: gun));
        oncekiGun = gun;
      }
      // Aynı günün son kaydından sonra çizgi devam etmesin.
      final sonraki = i + 1 < hareketler.length ? hareketler[i + 1] : null;
      final ayniGunDevamEdiyor =
          sonraki?.zaman != null &&
          gun != null &&
          gunBaslangici(sonraki!.zaman!) == gun;
      satirlar.add(_CizelgeSatiri(hareket: h, cizgiDevam: ayniGunDevamEdiyor));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: satirlar,
    );
  }
}

class _GunBasligi extends StatelessWidget {
  final DateTime gun;
  const _GunBasligi({required this.gun});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        gunBasligi(gun),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Renkler.petrol,
        ),
      ),
    );
  }
}

class _CizelgeSatiri extends StatelessWidget {
  final Hareket hareket;
  final bool
  cizgiDevam; // noktanın altından bir sonraki kayda dikey çizgi çizilsin mi?

  const _CizelgeSatiri({required this.hareket, required this.cizgiDevam});

  @override
  Widget build(BuildContext context) {
    final renk = HareketZamanCizelgesi.turRengi(hareket);
    final zaman = hareket.zaman;

    // IntrinsicHeight: sol taraftaki çizginin, sağdaki kartın boyu kadar uzamasını sağlar.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) Saat
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                zaman != null ? saatYaz(zaman) : '...',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Renkler.petrol,
                ),
              ),
            ),
          ),
          // 2) Nokta + dikey çizgi
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: renk,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: cizgiDevam
                        ? const Color(0xFFD1D5DB)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 3) Kart: bölüm adı + tür rozeti
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: kartDekorasyonu(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hareket.bolumAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Rozet(yazi: hareket.turEtiketi, renk: renk),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
