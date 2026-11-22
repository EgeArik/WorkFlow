import 'package:flutter/material.dart';

import '../../modeller/bolum.dart';
import '../../servisler/bolum_servisi.dart';
import '../../tema.dart';
import '../../widgetlar/rozet.dart';
import 'bolum_qr_ekrani.dart';

// Yönetim > Bölümler (basit sürüm). Gün 5'te kişi sayısı, son okutma, pasif yapma
// ve PDF eklenecek; Yönetim sekmesi de 4 alt sekmeli hâle gelecek.
class BolumlerEkrani extends StatefulWidget {
  const BolumlerEkrani({super.key});

  @override
  State<BolumlerEkrani> createState() => _BolumlerEkraniState();
}

class _BolumlerEkraniState extends State<BolumlerEkrani> {
  final _servis = BolumServisi();
  late final Stream<List<Bolum>> _akis = _servis.bolumlerAkisi();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim · Bölümler'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bolumEkle,
        icon: const Icon(Icons.add),
        label: const Text('Bölüm Ekle'),
      ),
      body: StreamBuilder<List<Bolum>>(
        stream: _akis,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bölümler yüklenemedi.'));
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final bolumler = snapshot.data!;
          if (bolumler.isEmpty) {
            return const Center(
              child: Text(
                'Henüz bölüm yok. "Bölüm Ekle" ile başlayın.',
                style: TextStyle(color: Renkler.griYazi),
              ),
            );
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
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: kartDekorasyonu(),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.ad,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!b.aktif)
                      const Rozet(yazi: 'Pasif', renk: Renkler.hata),
                    TextButton.icon(
                      onPressed: () => _qrAc(b),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR Kodu'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
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
