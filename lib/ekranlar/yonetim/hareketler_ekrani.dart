import 'package:flutter/material.dart';

import '../../modeller/hareket.dart';
import '../../modeller/kullanici.dart';
import '../../servisler/veri_servisi.dart';
import '../../tema.dart';
import '../../widgetlar/hareket_zaman_cizelgesi.dart';
import '../../yardimcilar/calisma_suresi.dart';
import '../../yardimcilar/zaman_bicimi.dart';

enum HareketFiltresi { bugun, dun, buHafta, tarih }

// Yönetim > Hareketler: bir personel seçilir, döneme göre hareketleri zaman çizelgesinde
// ve toplam çalışma süresiyle gösterilir.
class HareketlerEkrani extends StatefulWidget {
  const HareketlerEkrani({super.key});

  @override
  State<HareketlerEkrani> createState() => _HareketlerEkraniState();
}

class _HareketlerEkraniState extends State<HareketlerEkrani> {
  late final Stream<List<Kullanici>> _kullaniciAkisi = VeriServisi()
      .tumKullanicilarAkisi();

  String? _seciliUid; // null = henüz seçilmedi (listedeki ilk kişi gösterilir)
  HareketFiltresi _filtre = HareketFiltresi.bugun;
  DateTime _seciliTarih = DateTime.now(); // "Tarih seç" için

  // Hareket akışı ve onu oluşturan seçimler. Seçim değişmedikçe aynı akış kullanılır;
  // böylece her build'de Firestore'a yeni dinleme açılmaz.
  Stream<List<Hareket>>? _akis;
  String? _akisAnahtari;

  // Seçili filtreye göre dönemin başı ve sonu (sonu hariç).
  (DateTime, DateTime) _donem() {
    final bugun = gunBaslangici(DateTime.now());
    final yarin = bugun.add(const Duration(days: 1));
    return switch (_filtre) {
      HareketFiltresi.bugun => (bugun, yarin),
      HareketFiltresi.dun => (bugun.subtract(const Duration(days: 1)), bugun),
      // weekday: Pazartesi = 1. Pazartesi 00:00'dan bugünün sonuna kadar.
      HareketFiltresi.buHafta => (
        bugun.subtract(Duration(days: bugun.weekday - 1)),
        yarin,
      ),
      HareketFiltresi.tarih => (
        gunBaslangici(_seciliTarih),
        gunBaslangici(_seciliTarih).add(const Duration(days: 1)),
      ),
    };
  }

  Stream<List<Hareket>> _akisAl(String uid, DateTime bas, DateTime son) {
    final anahtar = '$uid $bas $son';
    if (anahtar != _akisAnahtari) {
      _akisAnahtari = anahtar;
      _akis = VeriServisi().hareketlerAkisi(uid, bas, bitis: son);
    }
    return _akis!;
  }

  Future<void> _filtreSec(HareketFiltresi yeni) async {
    if (yeni == HareketFiltresi.tarih) {
      // showDatePicker: takvim penceresi açar; vazgeçilirse null döner.
      final tarih = await showDatePicker(
        context: context,
        initialDate: _seciliTarih,
        firstDate: DateTime(2025),
        lastDate: DateTime.now(),
      );
      if (tarih == null) return;
      _seciliTarih = tarih;
    }
    setState(() => _filtre = yeni);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Kullanici>>(
      stream: _kullaniciAkisi,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Personeller yüklenemedi.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final kullanicilar = snapshot.data!;
        if (kullanicilar.isEmpty) {
          return const Center(child: Text('Henüz personel yok.'));
        }
        // Seçili kişi listede yoksa (ilk açılış) ilk kişiyi göster.
        final secili = kullanicilar.firstWhere(
          (k) => k.uid == _seciliUid,
          orElse: () => kullanicilar.first,
        );
        final (bas, son) = _donem();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _personelSecici(kullanicilar, secili),
            const SizedBox(height: 12),
            _filtreDugmeleri(),
            const SizedBox(height: 12),
            StreamBuilder<List<Hareket>>(
              stream: _akisAl(secili.uid, bas, son),
              builder: (context, hareketSnap) {
                if (hareketSnap.hasError) {
                  return const Text('Hareketler yüklenemedi.');
                }
                if (!hareketSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _sonuc(hareketSnap.data!, bas, son);
              },
            ),
          ],
        );
      },
    );
  }

  // DropdownButtonFormField: açılır liste; birini seçince onChanged çalışır.
  Widget _personelSecici(List<Kullanici> kullanicilar, Kullanici secili) {
    return DropdownButtonFormField<String>(
      initialValue: secili.uid,
      decoration: const InputDecoration(
        labelText: 'Personel',
        prefixIcon: Icon(Icons.person_search),
      ),
      items: [
        for (final k in kullanicilar)
          DropdownMenuItem(value: k.uid, child: Text(k.adSoyad)),
      ],
      onChanged: (uid) => setState(() => _seciliUid = uid),
    );
  }

  Widget _filtreDugmeleri() {
    final tarihYazisi = _filtre == HareketFiltresi.tarih
        ? '${_seciliTarih.day}.${_seciliTarih.month}' // seçilen gün, ör. "19.11"
        : 'Tarih seç';
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<HareketFiltresi>(
        segments: [
          const ButtonSegment(
            value: HareketFiltresi.bugun,
            label: Text('Bugün'),
          ),
          const ButtonSegment(value: HareketFiltresi.dun, label: Text('Dün')),
          const ButtonSegment(
            value: HareketFiltresi.buHafta,
            label: Text('Bu hafta'),
          ),
          ButtonSegment(value: HareketFiltresi.tarih, label: Text(tarihYazisi)),
        ],
        selected: {_filtre},
        showSelectedIcon: false,
        onSelectionChanged: (secim) => _filtreSec(secim.first),
      ),
    );
  }

  Widget _sonuc(List<Hareket> hareketler, DateTime bas, DateTime son) {
    final sure = toplamCalismaSuresi(hareketler, donemBitis: son);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toplam çalışma süresi kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kartDekorasyonu(),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Renkler.petrol, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam çalışma süresi',
                      style: TextStyle(color: Renkler.griYazi),
                    ),
                    Text(
                      sure == Duration.zero ? '0 dk' : sureYaz(sure),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Renkler.petrol,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${hareketler.length} kayıt',
                style: const TextStyle(color: Renkler.griYazi),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (hareketler.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'Bu dönemde hareket yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Renkler.griYazi, fontSize: 16),
            ),
          )
        else
          HareketZamanCizelgesi(hareketler: hareketler),
      ],
    );
  }
}
