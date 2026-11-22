import 'package:flutter/material.dart';

import '../../modeller/bolum.dart';
import '../../modeller/hareket.dart';
import '../../modeller/kullanici.dart';
import '../../servisler/bolum_servisi.dart';
import '../../servisler/veri_servisi.dart';
import '../../tema.dart';
import '../../widgetlar/rozet.dart';
import '../../yardimcilar/zaman_bicimi.dart';
import 'bolum_qr_ekrani.dart';

// Yönetim > Bölümler alt sekmesi: her bölümde içerideki kişi sayısı, son okutma saati,
// QR Kodu butonu, ⋮ menüsünde Pasif yap / Aktif yap ve "Bölüm Ekle". Bölümler silinmez.
class BolumlerEkrani extends StatefulWidget {
  const BolumlerEkrani({super.key});

  @override
  State<BolumlerEkrani> createState() => _BolumlerEkraniState();
}

class _BolumlerEkraniState extends State<BolumlerEkrani> {
  final _servis = BolumServisi();
  // Akışlar bir kez oluşturulur (build her çalıştığında yeni dinleme açılmasın diye).
  late final Stream<List<Bolum>> _bolumAkisi = _servis.bolumlerAkisi();
  late final Stream<List<Kullanici>> _kullaniciAkisi = VeriServisi()
      .tumKullanicilarAkisi();
  late final Stream<List<Hareket>> _hareketAkisi = VeriServisi()
      .sonHareketlerAkisi();

  void _qrAc(Bolum bolum) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BolumQrEkrani(bolum: bolum)));
  }

  // "Bölüm Ekle": ad sorulur, kaydedilir, QR ekranı otomatik açılır.
  Future<void> _bolumEkle() async {
    final ad = await showDialog<String>(
      context: context,
      builder: (_) => const _BolumAdiDialogu(),
    );
    if (ad == null || ad.trim().isEmpty) return; // vazgeçildi

    try {
      final yeni = await _servis.bolumEkle(ad);
      if (mounted) _qrAc(yeni);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bölüm eklenemedi. İnternet bağlantınızı ve yetkinizi kontrol edin.',
          ),
          backgroundColor: Renkler.hata,
        ),
      );
    }
  }

  // Pasif yap / Aktif yap. Pasif yapmadan önce onay istenir (yanlışlıkla basılmasın).
  Future<void> _aktiflikDegistir(Bolum bolum) async {
    final yeniDurum = !bolum.aktif;
    if (!yeniDurum) {
      final onay = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bölümü pasif yap'),
          content: Text(
            '${bolum.ad} pasif yapılsın mı?\n\n'
            'Bu bölüme artık giriş yapılamaz. İçerideki kişiler çıkış yapabilir. '
            'Bölümü daha sonra tekrar aktif yapabilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Renkler.hata),
              child: const Text('Pasif yap'),
            ),
          ],
        ),
      );
      if (onay != true) return; // vazgeçildi veya pencere dışına basıldı
    }

    try {
      await _servis.aktiflikDegistir(bolum, yeniDurum);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Değişiklik kaydedilemedi. İnternet bağlantınızı kontrol edin.',
          ),
          backgroundColor: Renkler.hata,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Başlık (AppBar) artık Yönetim ekranında; burada içerik ve "Bölüm Ekle" var.
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bolumEkle,
        icon: const Icon(Icons.add),
        label: const Text('Bölüm Ekle'),
      ),
      body: StreamBuilder<List<Bolum>>(
        stream: _bolumAkisi,
        builder: (context, bolumSnap) {
          if (bolumSnap.hasError) {
            return const Center(child: Text('Bölümler yüklenemedi.'));
          }
          if (!bolumSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bolumler = bolumSnap.data!;
          if (bolumler.isEmpty) {
            return const Center(
              child: Text(
                'Henüz bölüm yok. "Bölüm Ekle" ile başlayın.',
                style: TextStyle(color: Renkler.griYazi),
              ),
            );
          }
          // Kişi sayısı ve son okutma için kullanıcıları ve son hareketleri de dinleriz.
          // Bunlar henüz gelmediyse (veya hata varsa) bölümler yine de gösterilir.
          return StreamBuilder<List<Kullanici>>(
            stream: _kullaniciAkisi,
            builder: (context, kullaniciSnap) {
              return StreamBuilder<List<Hareket>>(
                stream: _hareketAkisi,
                builder: (context, hareketSnap) => _liste(
                  bolumler,
                  kullaniciSnap.data ?? const [],
                  hareketSnap.data ?? const [],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _liste(
    List<Bolum> bolumler,
    List<Kullanici> kullanicilar,
    List<Hareket> hareketler,
  ) {
    // Her bölümde kaç kişi var? Map: bölümId -> kişi sayısı.
    final kisiSayisi = <String, int>{};
    for (final k in kullanicilar) {
      final id = k.suAnkiBolumId;
      if (id != null) kisiSayisi[id] = (kisiSayisi[id] ?? 0) + 1;
    }
    // Her bölümün son okutması. Liste en yeniden eskiye sıralı olduğu için bir bölümle
    // ilk karşılaştığımız kayıt, o bölümün en son kaydıdır (putIfAbsent: yoksa ekle).
    // Otomatik çıkış sayılmaz: o kayıt QR okutularak değil, başka bölüme geçince oluşur.
    final sonOkutma = <String, DateTime>{};
    for (final h in hareketler) {
      final zaman = h.zaman;
      if (h.tur == 'otomatik_cikis' || zaman == null) continue;
      sonOkutma.putIfAbsent(h.bolumId, () => zaman);
    }

    // ListView.separated: elemanların arasına boşluk koyarak liste çizer.
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        96,
      ), // altta buton için boşluk
      itemCount: bolumler.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = bolumler[i];
        final son = sonOkutma[b.id];
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: kartDekorasyonu(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.ad,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!b.aktif) ...[
                          const SizedBox(width: 8),
                          const Rozet(yazi: 'Pasif', renk: Renkler.hata),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kisiSayisi[b.id] ?? 0} kişi içeride · Son okutma: '
                      '${son == null ? '—' : kisaZamanYaz(son)}',
                      style: const TextStyle(
                        color: Renkler.griYazi,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _qrAc(b),
                icon: const Icon(Icons.qr_code),
                label: const Text('QR Kodu'),
              ),
              // PopupMenuButton: "⋮" simgesi; basınca küçük bir seçenek menüsü açılır.
              PopupMenuButton<String>(
                tooltip: 'Diğer işlemler',
                onSelected: (_) => _aktiflikDegistir(b),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'aktiflik',
                    child: Text(b.aktif ? 'Pasif yap' : 'Aktif yap'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Bölüm adını soran küçük pencere. Kendi controller'ını yönetsin diye StatefulWidget.
class _BolumAdiDialogu extends StatefulWidget {
  const _BolumAdiDialogu();

  @override
  State<_BolumAdiDialogu> createState() => _BolumAdiDialoguState();
}

class _BolumAdiDialoguState extends State<_BolumAdiDialogu> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bölüm Ekle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Bölüm adı',
          hintText: 'Örn. A Bölümü',
        ),
        onSubmitted: (ad) => Navigator.of(context).pop(ad),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
