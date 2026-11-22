import 'package:flutter/material.dart';

import '../modeller/hareket.dart';
import '../servisler/veri_servisi.dart';
import '../tema.dart';
import '../widgetlar/hareket_zaman_cizelgesi.dart';

// Filtre seçenekleri.
enum GecmisFiltresi { bugun, buHafta, buAy }

// Personelin kendi hareket geçmişi: üstte filtre, altta zaman çizelgesi.
class GecmisEkrani extends StatefulWidget {
  final String uid;
  const GecmisEkrani({super.key, required this.uid});

  @override
  State<GecmisEkrani> createState() => _GecmisEkraniState();
}

class _GecmisEkraniState extends State<GecmisEkrani> {
  GecmisFiltresi _filtre = GecmisFiltresi.bugun;
  late Stream<List<Hareket>> _akis;

  @override
  void initState() {
    super.initState();
    _akis = _akisOlustur();
  }

  // Seçili filtreye göre başlangıç anını hesaplar ve yeni bir akış açar.
  Stream<List<Hareket>> _akisOlustur() {
    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final baslangic = switch (_filtre) {
      GecmisFiltresi.bugun => bugun,
      // weekday: Pazartesi = 1 ... Pazar = 7. Pazartesi'ye kadar geri gideriz.
      GecmisFiltresi.buHafta => bugun.subtract(
        Duration(days: simdi.weekday - 1),
      ),
      GecmisFiltresi.buAy => DateTime(simdi.year, simdi.month, 1),
    };
    return VeriServisi().hareketlerAkisi(widget.uid, baslangic);
  }

  void _filtreSec(GecmisFiltresi yeni) {
    setState(() {
      _filtre = yeni;
      _akis = _akisOlustur(); // filtre değişince akışı yeniden oluştururuz
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            // SegmentedButton: yan yana bölmeli seçim düğmesi; aynı anda bir seçenek seçilir.
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<GecmisFiltresi>(
                segments: const [
                  ButtonSegment(
                    value: GecmisFiltresi.bugun,
                    label: Text('Bugün'),
                  ),
                  ButtonSegment(
                    value: GecmisFiltresi.buHafta,
                    label: Text('Bu hafta'),
                  ),
                  ButtonSegment(
                    value: GecmisFiltresi.buAy,
                    label: Text('Bu ay'),
                  ),
                ],
                selected: {_filtre},
                showSelectedIcon: false,
                onSelectionChanged: (secim) => _filtreSec(secim.first),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Hareket>>(
              stream: _akis,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Geçmiş yüklenemedi.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final hareketler = snapshot.data!;
                if (hareketler.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu dönemde hareket yok.',
                      style: TextStyle(color: Renkler.griYazi, fontSize: 16),
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${hareketler.length} kayıt',
                          style: const TextStyle(color: Renkler.griYazi),
                        ),
                      ),
                      HareketZamanCizelgesi(hareketler: hareketler),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
