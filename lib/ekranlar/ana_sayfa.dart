import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/hareket.dart';
import '../modeller/kullanici.dart';
import '../servisler/veri_servisi.dart';
import '../tema.dart';
import '../widgetlar/workflow_logo.dart';
import '../yardimcilar/zaman_bicimi.dart';

// Ana Sayfa: petrol renkli üst şerit (logo + selam), "Şu an içeride" kartı,
// 3 küçük bilgi kartı, büyük sarı QR Okut butonu ve bugünkü hareketler listesi.
class AnaSayfa extends StatefulWidget {
  final Kullanici kullanici;
  final VoidCallback
  qrOkutTiklandi; // VoidCallback: parametresiz, sonuç döndürmeyen fonksiyon

  const AnaSayfa({
    super.key,
    required this.kullanici,
    required this.qrOkutTiklandi,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  // Akışı initState'te BİR KEZ oluştururuz. build() içinde oluştursaydık, ekran her
  // yeniden çizildiğinde Firestore'a yeni bir dinleme açılırdı.
  late final Stream<List<Hareket>> _hareketAkisi;

  @override
  void initState() {
    super.initState();
    _hareketAkisi = VeriServisi().bugunkuHareketlerAkisi(widget.kullanici.uid);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kullanici;
    return Scaffold(
      body: Column(
        children: [
          _UstSerit(kullanici: k),
          // Expanded: şeritten geriye kalan tüm alanı listeye verir.
          Expanded(
            child: StreamBuilder<List<Hareket>>(
              stream: _hareketAkisi,
              builder: (context, snapshot) {
                final hareketler = snapshot.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _BolumKarti(kullanici: k),
                    const SizedBox(height: 12),
                    _kucukKartlar(hareketler),
                    const SizedBox(height: 16),
                    _QrButonu(tiklandi: widget.qrOkutTiklandi),
                    const SizedBox(height: 24),
                    const KucukBaslik('Bugün'),
                    const SizedBox(height: 8),
                    _hareketListesi(snapshot),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bugünkü hareket sayısı ve son okutma saati.
  Widget _kucukKartlar(List<Hareket> hareketler) {
    // Liste en yeniden eskiye sıralı; ilk eleman son okutmadır.
    final sonZaman = hareketler.isNotEmpty ? hareketler.first.zaman : null;
    // IntrinsicHeight + stretch: kartlar, en uzun olanın yüksekliğinde eşit boyda durur.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KucukKart(
            ikon: Icons.swap_horiz,
            baslik: 'Bugünkü hareket',
            deger: '${hareketler.length}',
          ),
          const SizedBox(width: 8),
          _KucukKart(
            ikon: Icons.access_time,
            baslik: 'Son okutma',
            deger: sonZaman != null ? saatYaz(sonZaman) : '-',
          ),
        ],
      ),
    );
  }

  Widget _hareketListesi(AsyncSnapshot<List<Hareket>> snapshot) {
    if (snapshot.hasError) {
      return const Text(
        'Hareketler yüklenemedi. Lütfen biraz sonra tekrar deneyin.',
        style: TextStyle(color: Renkler.hata),
      );
    }
    if (!snapshot.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final hareketler = snapshot.data!;
    if (hareketler.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: kartDekorasyonu(),
        child: const Text(
          'Bugün henüz hareketiniz yok.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Renkler.griYazi),
        ),
      );
    }
    // Tek bir kartın içinde, aralarında ince çizgi olan satırlar.
    return Container(
      decoration: kartDekorasyonu(),
      child: Column(
        children: [
          for (var i = 0; i < hareketler.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _HareketSatiri(hareket: hareketler[i]),
          ],
        ],
      ),
    );
  }
}

// ---------------- Ana sayfanın parçaları ----------------
// Alt çizgi (_) ile başlayan sınıflar sadece bu dosyada kullanılabilir.

// Petrol renkli üst şerit: logo + "Günaydın, Ad".
class _UstSerit extends StatelessWidget {
  final Kullanici kullanici;
  const _UstSerit({required this.kullanici});

  // Saate göre selam.
  String _selam() {
    final saat = DateTime.now().hour;
    if (saat >= 5 && saat < 12) return 'Günaydın';
    if (saat >= 12 && saat < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final ad = kullanici.adSoyad.split(' ').first; // sadece ilk ad
    return Container(
      width: double.infinity,
      color: Renkler.petrol,
      // SafeArea: telefonun üstteki saat/çentik alanının altına içerik koymaz.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogoSatiri(boyut: 30, koyuZemin: true),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFFD6E4E3),
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(text: '${_selam()}, '),
                    TextSpan(
                      text: ad,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// "Şu an içeride" kartı. Soldaki renkli şerit durumu gösterir: yeşil = içeride.
// İçerideki süre her dakika güncellensin diye StatefulWidget.
class _BolumKarti extends StatefulWidget {
  final Kullanici kullanici;
  const _BolumKarti({required this.kullanici});

  @override
  State<_BolumKarti> createState() => _BolumKartiState();
}

class _BolumKartiState extends State<_BolumKarti> {
  Timer? _zamanlayici;

  @override
  void initState() {
    super.initState();
    // Timer.periodic: verilen aralıkla tekrar tekrar çalışır. Her dakika ekranı yeniler.
    _zamanlayici = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _zamanlayici?.cancel(); // ekran kapanınca zamanlayıcıyı durdur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kullanici;
    final iceride = k.suAnIcerideMi;
    final giris = k.girisZamani;
    final sureYazisi = iceride && giris != null
        ? '${saatYaz(giris)}\'den beri · ${sureYaz(DateTime.now().difference(giris))}'
        : 'Bir bölüme girmek için QR okutun';

    return Container(
      decoration: kartDekorasyonu(),
      // clipBehavior: soldaki şerit kartın yuvarlak köşesinden taşmasın.
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              color: iceride ? Renkler.basari : Renkler.kenar,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Küçük durum noktası
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iceride ? Renkler.basari : Renkler.griYazi,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        KucukBaslik(
                          iceride ? 'Şu an içeride' : 'Şu an dışarıda',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      iceride
                          ? (k.suAnkiBolumAdi ?? '')
                          : 'Hiçbir bölümde değilsiniz',
                      style: TextStyle(
                        fontSize: iceride ? 30 : 20,
                        fontWeight: FontWeight.w500,
                        color: Renkler.petrol,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sureYazisi,
                      style: const TextStyle(color: Renkler.griYazi),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Büyük sarı QR butonu: personelin en çok bastığı yer, bu yüzden 72 px yüksek.
class _QrButonu extends StatelessWidget {
  final VoidCallback tiklandi;
  const _QrButonu({required this.tiklandi});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: tiklandi,
      style: ElevatedButton.styleFrom(
        backgroundColor: Renkler.hardal,
        foregroundColor: Renkler.yazi,
        minimumSize: const Size.fromHeight(72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      ),
      icon: const Icon(Icons.qr_code_scanner, size: 30),
      label: const Text('QR Okut'),
    );
  }
}

class _KucukKart extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String deger;

  const _KucukKart({
    required this.ikon,
    required this.baslik,
    required this.deger,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Expanded (Row içinde): kartlar eşit genişlikte yan yana durur.
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: kartDekorasyonu(),
        child: Row(
          children: [
            Icon(ikon, color: Renkler.petrol, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deger,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Renkler.yazi,
                    ),
                  ),
                  Text(
                    baslik,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Renkler.griYazi,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bugünkü listede tek satır: solda renkli çizgi, bölüm ve tür, sağda saat.
class _HareketSatiri extends StatelessWidget {
  final Hareket hareket;
  const _HareketSatiri({required this.hareket});

  @override
  Widget build(BuildContext context) {
    // Giriş yeşil, çıkış kiremit, otomatik çıkış hardal.
    final renk = switch (hareket.tur) {
      'giris' => Renkler.basari,
      'cikis' => Renkler.hata,
      _ => Renkler.uyari, // "_" = diğer tüm durumlar
    };
    final zaman = hareket.zaman;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hareket.bolumAdi,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  hareket.turEtiketi,
                  style: TextStyle(color: renk, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            zaman != null ? saatYaz(zaman) : '...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              // tabularFigures: tüm rakamlar aynı genişlikte; saatler alt alta hizalanır.
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
