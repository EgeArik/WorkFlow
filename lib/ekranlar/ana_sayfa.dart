import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/hareket.dart';
import '../modeller/kullanici.dart';
import '../servisler/veri_servisi.dart';
import '../tema.dart';
import '../widgetlar/bas_harf_avatar.dart';
import '../widgetlar/rozet.dart';
import '../yardimcilar/zaman_bicimi.dart';

// Ana Sayfa: lacivert başlık, "Şu Anki Bölümünüz" kartı, 3 küçük bilgi kartı,
// büyük QR Okut butonu ve bugünkü hareketler listesi.
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
          _Baslik(kullanici: k),
          // Expanded: başlıktan geriye kalan tüm alanı listeye verir.
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
                    _kucukKartlar(k, hareketler),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.qrOkutTiklandi,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 28),
                      label: const Text('QR Okut (giriş / çıkış)'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Son Hareketleriniz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Renkler.lacivert,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._hareketListesi(
                      snapshot,
                    ), // "..." listenin elemanlarını buraya açar
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bugünkü hareket sayısı, son okutma saati, çalışma durumu.
  Widget _kucukKartlar(Kullanici k, List<Hareket> hareketler) {
    // Liste en yeniden eskiye sıralı; ilk eleman son okutmadır.
    final sonZaman = hareketler.isNotEmpty ? hareketler.first.zaman : null;
    // IntrinsicHeight + stretch: üç kart, en uzun olanın yüksekliğinde eşit boyda durur.
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
          const SizedBox(width: 8),
          _KucukKart(
            ikon: Icons.work_outline,
            baslik: 'Durum',
            deger: k.icerideMi ? 'Çalışıyor' : 'Dışarıda',
            renk: k.icerideMi ? Renkler.basari : Renkler.griYazi,
          ),
        ],
      ),
    );
  }

  List<Widget> _hareketListesi(AsyncSnapshot<List<Hareket>> snapshot) {
    if (snapshot.hasError) {
      return [
        const Text(
          'Hareketler yüklenemedi. Lütfen biraz sonra tekrar deneyin.',
          style: TextStyle(color: Renkler.hata),
        ),
      ];
    }
    if (!snapshot.hasData) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    final hareketler = snapshot.data!;
    if (hareketler.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: kartDekorasyonu(),
          child: const Text(
            'Bugün henüz hareketiniz yok.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Renkler.griYazi),
          ),
        ),
      ];
    }
    // map(): her Hareket'i bir _HareketSatiri widget'ına çevirir.
    return hareketler.map((h) => _HareketSatiri(hareket: h)).toList();
  }
}

// ---------------- Ana sayfanın parçaları ----------------
// Alt çizgi (_) ile başlayan sınıflar sadece bu dosyada kullanılabilir.

class _Baslik extends StatelessWidget {
  final Kullanici kullanici;
  const _Baslik({required this.kullanici});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Renkler.lacivert,
      // SafeArea: telefonun üstteki saat/çentik alanının altına içerik koymaz.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Row(
            children: [
              BasHarfAvatar(harfler: kullanici.basHarfler),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kullanici.adSoyad,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kullanici.gorev,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

// "Şu Anki Bölümünüz" kartı. İçerideki süre her dakika güncellensin diye StatefulWidget.
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kartDekorasyonu(),
      child: k.icerideMi ? _iceride(k) : _disarida(),
    );
  }

  Widget _iceride(Kullanici k) {
    final giris = k.girisZamani;
    final sureYazisi = giris != null
        ? '${saatYaz(giris)}\'den beri · ${sureYaz(DateTime.now().difference(giris))}'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Şu Anki Bölümünüz',
              style: TextStyle(color: Renkler.griYazi),
            ),
            const Spacer(),
            const Rozet(yazi: 'İçeride', renk: Renkler.basari),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          k.suAnkiBolumAdi ?? '',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Renkler.lacivert,
          ),
        ),
        const SizedBox(height: 4),
        Text(sureYazisi, style: const TextStyle(color: Renkler.griYazi)),
      ],
    );
  }

  Widget _disarida() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Şu Anki Bölümünüz', style: TextStyle(color: Renkler.griYazi)),
        SizedBox(height: 8),
        Text(
          'Şu an hiçbir bölümde değilsiniz',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Renkler.lacivert,
          ),
        ),
      ],
    );
  }
}

class _KucukKart extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String deger;
  final Color renk;

  const _KucukKart({
    required this.ikon,
    required this.baslik,
    required this.deger,
    this.renk = Renkler.lacivert,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Expanded (Row içinde): üç kart eşit genişlikte yan yana durur.
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: kartDekorasyonu(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: Renkler.mavi, size: 20),
            const SizedBox(height: 8),
            Text(
              deger,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(
              baslik,
              style: const TextStyle(fontSize: 12, color: Renkler.griYazi),
            ),
          ],
        ),
      ),
    );
  }
}

class _HareketSatiri extends StatelessWidget {
  final Hareket hareket;
  const _HareketSatiri({required this.hareket});

  @override
  Widget build(BuildContext context) {
    // Giriş yeşil, çıkış mavi, otomatik çıkış turuncu.
    final renk = switch (hareket.tur) {
      'giris' => Renkler.basari,
      'cikis' => Renkler.mavi,
      _ => Renkler.uyari, // "_" = diğer tüm durumlar
    };
    final zaman = hareket.zaman;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: kartDekorasyonu(),
      child: Row(
        children: [
          Icon(hareket.girisMi ? Icons.login : Icons.logout, color: renk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hareket.bolumAdi,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  zaman != null ? saatYaz(zaman) : '...',
                  style: const TextStyle(color: Renkler.griYazi, fontSize: 13),
                ),
              ],
            ),
          ),
          Rozet(yazi: hareket.turEtiketi, renk: renk),
        ],
      ),
    );
  }
}
