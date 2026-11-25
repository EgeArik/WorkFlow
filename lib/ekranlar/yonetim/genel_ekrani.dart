import 'dart:async';

import 'package:flutter/material.dart';

import '../../modeller/bolum.dart';
import '../../modeller/hareket.dart';
import '../../modeller/kullanici.dart';
import '../../servisler/bolum_servisi.dart';
import '../../servisler/veri_servisi.dart';
import '../../tema.dart';
import '../../widgetlar/hareket_zaman_cizelgesi.dart';
import '../../widgetlar/rozet.dart';
import '../../yardimcilar/zaman_bicimi.dart';

// Yönetim > Genel: kurumun anlık özeti.
// Toplam / içerideki personel, bölümlerdeki kişi sayıları (çubuklar), son hareketler.
class GenelEkrani extends StatefulWidget {
  const GenelEkrani({super.key});

  @override
  State<GenelEkrani> createState() => _GenelEkraniState();
}

class _GenelEkraniState extends State<GenelEkrani> {
  late final Stream<List<Kullanici>> _kullaniciAkisi = VeriServisi()
      .tumKullanicilarAkisi();
  late final Stream<List<Bolum>> _bolumAkisi = BolumServisi().bolumlerAkisi();
  late final Stream<List<Hareket>> _hareketAkisi = VeriServisi()
      .sonHareketlerAkisi(adet: 10);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<List<Kullanici>>(
          stream: _kullaniciAkisi,
          builder: (context, kullaniciSnap) {
            if (kullaniciSnap.hasError) {
              return const Text('Personeller yüklenemedi.');
            }
            if (!kullaniciSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final kullanicilar = kullaniciSnap.data!;
            final iceride = kullanicilar.where((k) => k.suAnIcerideMi).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SayiKarti(
                        baslik: 'Toplam personel',
                        sayi: kullanicilar.length,
                        renk: Renkler.petrol,
                        ikon: Icons.groups,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SayiKarti(
                        baslik: 'Şu an içeride',
                        sayi: iceride,
                        renk: Renkler.basari,
                        ikon: Icons.login,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _BolumBasligi('Bölüm Durumu'),
                StreamBuilder<List<Bolum>>(
                  stream: _bolumAkisi,
                  builder: (context, bolumSnap) => _bolumCubuklari(
                    bolumSnap.data ?? const [],
                    kullanicilar,
                    iceride,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const _BolumBasligi('Son Hareketler'),
        StreamBuilder<List<Hareket>>(
          stream: _hareketAkisi,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Hareketler yüklenemedi.');
            final hareketler = snapshot.data ?? const <Hareket>[];
            if (hareketler.isEmpty) {
              return const Text(
                'Henüz hareket yok.',
                style: TextStyle(color: Renkler.griYazi),
              );
            }
            return Container(
              decoration: kartDekorasyonu(),
              child: Column(
                children: [for (final h in hareketler) _SonHareketSatiri(h)],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const _SistemDurumu(),
      ],
    );
  }

  // Her aktif bölüm için yatay çubuk: çubuğun doluluğu = o bölümdeki kişi / içerideki herkes.
  // Pasif bölümler, içinde hâlâ biri varsa gösterilir.
  Widget _bolumCubuklari(
    List<Bolum> bolumler,
    List<Kullanici> kullanicilar,
    int iceride,
  ) {
    final gosterilecek = <(Bolum, int)>[]; // (bölüm, kişi sayısı) çiftleri
    for (final b in bolumler) {
      final sayi = kullanicilar
          .where((k) => k.suAnIcerideMi && k.suAnkiBolumId == b.id)
          .length;
      if (b.aktif || sayi > 0) gosterilecek.add((b, sayi));
    }
    if (gosterilecek.isEmpty) {
      return const Text(
        'Henüz bölüm yok.',
        style: TextStyle(color: Renkler.griYazi),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kartDekorasyonu(),
      child: Column(
        children: [
          for (final (bolum, sayi) in gosterilecek)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bolum.ad,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('$sayi kişi'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // LinearProgressIndicator: 0 ile 1 arasındaki değeri yatay çubuk olarak çizer.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: iceride == 0 ? 0 : sayi / iceride,
                      minHeight: 10,
                      backgroundColor: Renkler.arkaPlan,
                      color: Renkler.petrol,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final String yazi;
  const _BolumBasligi(this.yazi);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        yazi,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Renkler.petrol,
        ),
      ),
    );
  }
}

// "Toplam personel: 12" gibi büyük sayılı kart.
class _SayiKarti extends StatelessWidget {
  final String baslik;
  final int sayi;
  final Color renk;
  final IconData ikon;

  const _SayiKarti({
    required this.baslik,
    required this.sayi,
    required this.renk,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kartDekorasyonu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk),
          const SizedBox(height: 8),
          Text(
            '$sayi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          Text(baslik, style: const TextStyle(color: Renkler.griYazi)),
        ],
      ),
    );
  }
}

// Son hareketler listesindeki bir satır: saat, kişi, bölüm, tür rozeti.
class _SonHareketSatiri extends StatelessWidget {
  final Hareket hareket;
  const _SonHareketSatiri(this.hareket);

  @override
  Widget build(BuildContext context) {
    final zaman = hareket.zaman;
    return ListTile(
      leading: Text(
        zaman == null ? '--:--' : kisaZamanYaz(zaman),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      title: Text(hareket.kullaniciAdi),
      subtitle: Text(hareket.bolumAdi),
      trailing: Rozet(
        yazi: hareket.turEtiketi,
        renk: HareketZamanCizelgesi.turRengi(hareket),
      ),
    );
  }
}

// En altta "Sistem aktif" ve canlı tarih-saat. Saat her 30 saniyede yenilenir.
class _SistemDurumu extends StatefulWidget {
  const _SistemDurumu();

  @override
  State<_SistemDurumu> createState() => _SistemDurumuState();
}

class _SistemDurumuState extends State<_SistemDurumu> {
  Timer? _zamanlayici;

  @override
  void initState() {
    super.initState();
    _zamanlayici = Timer.periodic(
      const Duration(seconds: 30),
      (_) =>
          setState(() {}), // sadece ekranı yeniden çizer; saat yeniden okunur
    );
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simdi = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.circle, size: 10, color: Renkler.basari),
        const SizedBox(width: 6),
        Text(
          'Sistem aktif · ${gunBasligi(simdi)} ${saatYaz(simdi)}',
          style: const TextStyle(color: Renkler.griYazi),
        ),
      ],
    );
  }
}
