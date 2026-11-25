import 'package:flutter/material.dart';

import '../../modeller/bolum.dart';
import '../../modeller/hareket.dart';
import '../../modeller/kullanici.dart';
import '../../servisler/bolum_servisi.dart';
import '../../servisler/veri_servisi.dart';
import '../../tema.dart';
import '../../widgetlar/bas_harf_avatar.dart';
import '../../widgetlar/rozet.dart';
import '../../yardimcilar/zaman_bicimi.dart';

// Yönetim > Personeller alt sekmesi: arama kutusu, bölüm filtresi ve personel listesi.
// Arama ve filtreleme telefonda yapılır; Firestore'dan tüm kullanıcılar bir kez gelir.
class PersonellerEkrani extends StatefulWidget {
  const PersonellerEkrani({super.key});

  @override
  State<PersonellerEkrani> createState() => _PersonellerEkraniState();
}

class _PersonellerEkraniState extends State<PersonellerEkrani> {
  late final Stream<List<Kullanici>> _kullaniciAkisi = VeriServisi()
      .tumKullanicilarAkisi();
  late final Stream<List<Bolum>> _bolumAkisi = BolumServisi().bolumlerAkisi();
  late final Stream<List<Hareket>> _hareketAkisi = VeriServisi()
      .sonHareketlerAkisi();

  String _aranan = ''; // arama kutusuna yazılan (küçük harfe çevrilmiş)
  String? _seciliBolumId; // null = "Tümü"

  @override
  Widget build(BuildContext context) {
    return Column(
      // stretch: çocuklar tüm genişliği kaplar; filtre çipleri ortada değil solda başlar.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Personel ara',
              prefixIcon: Icon(Icons.search),
            ),
            // Her harf yazıldığında liste yeniden süzülür.
            onChanged: (yazi) =>
                setState(() => _aranan = turkceKucukHarf(yazi.trim())),
          ),
        ),
        _bolumFiltresi(),
        Expanded(child: _liste()),
      ],
    );
  }

  // "Tümü" + bölüm adları; yana kaydırılabilir çipler.
  Widget _bolumFiltresi() {
    return StreamBuilder<List<Bolum>>(
      stream: _bolumAkisi,
      builder: (context, snapshot) {
        final bolumler = snapshot.data ?? const <Bolum>[];
        // SingleChildScrollView + Axis.horizontal: içerik ekrana sığmazsa yana kayar.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _cip('Tümü', null),
              for (final b in bolumler) _cip(b.ad, b.id),
            ],
          ),
        );
      },
    );
  }

  // ChoiceChip: seçilebilen küçük düğme; aynı anda sadece biri seçili olur.
  Widget _cip(String yazi, String? bolumId) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(yazi),
        selected: _seciliBolumId == bolumId,
        onSelected: (_) => setState(() => _seciliBolumId = bolumId),
      ),
    );
  }

  Widget _liste() {
    return StreamBuilder<List<Kullanici>>(
      stream: _kullaniciAkisi,
      builder: (context, kullaniciSnap) {
        if (kullaniciSnap.hasError) {
          return const Center(child: Text('Personeller yüklenemedi.'));
        }
        if (!kullaniciSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Önce bölüm filtresi, sonra arama: ikisine de uyanlar kalır.
        final liste = kullaniciSnap.data!
            .where(
              (k) =>
                  _seciliBolumId == null ||
                  (k.suAnIcerideMi && k.suAnkiBolumId == _seciliBolumId),
            )
            .where((k) => turkceKucukHarf(k.adSoyad).contains(_aranan))
            .toList();
        if (liste.isEmpty) {
          return const Center(
            child: Text(
              'Eşleşen personel yok.',
              style: TextStyle(color: Renkler.griYazi),
            ),
          );
        }
        return StreamBuilder<List<Hareket>>(
          stream: _hareketAkisi,
          builder: (context, hareketSnap) {
            final sonGiris = _sonGirisler(hareketSnap.data ?? const []);
            // Yönetim ekranları sıkı: tek kart içinde, aralarında ince çizgi olan satırlar.
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Container(
                  decoration: kartDekorasyonu(),
                  child: Column(
                    children: [
                      for (var i = 0; i < liste.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        // İçerideyse giriş zamanı kullanıcı dokümanında; değilse son hareketlerden.
                        _PersonelSatiri(
                          kullanici: liste[i],
                          sonGiris:
                              liste[i].girisZamani ?? sonGiris[liste[i].uid],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // kullanıcıId -> son giriş zamanı. Liste en yeniden eskiye sıralı olduğu için
  // bir kişiyle ilk karşılaştığımız giriş kaydı, onun en son girişidir.
  Map<String, DateTime> _sonGirisler(List<Hareket> hareketler) {
    final sonuc = <String, DateTime>{};
    for (final h in hareketler) {
      final zaman = h.zaman;
      if (!h.girisMi || zaman == null) continue;
      sonuc.putIfAbsent(h.kullaniciId, () => zaman);
    }
    return sonuc;
  }
}

// Tek personel kartı: avatar, ad soyad, bölüm, son giriş, durum rozeti.
class _PersonelSatiri extends StatelessWidget {
  final Kullanici kullanici;
  final DateTime? sonGiris;

  const _PersonelSatiri({required this.kullanici, required this.sonGiris});

  @override
  Widget build(BuildContext context) {
    final k = kullanici;
    final son = sonGiris;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          BasHarfAvatar(harfler: k.basHarfler, boyut: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.adSoyad,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  k.suAnIcerideMi
                      ? (k.suAnkiBolumAdi ?? '')
                      : k.icerideMi
                      ? 'Otomatik çıkış (9 saat doldu)'
                      : 'Bölümde değil',
                  style: const TextStyle(color: Renkler.griYazi, fontSize: 13),
                ),
                Text(
                  'Son giriş: ${son == null ? '—' : kisaZamanYaz(son)}',
                  style: const TextStyle(color: Renkler.griYazi, fontSize: 13),
                ),
              ],
            ),
          ),
          k.suAnIcerideMi
              ? const Rozet(yazi: 'İçeride', renk: Renkler.basari)
              : const Rozet(yazi: 'Dışarıda', renk: Renkler.griYazi),
        ],
      ),
    );
  }
}
