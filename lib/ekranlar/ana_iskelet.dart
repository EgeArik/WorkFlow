import 'package:flutter/material.dart';

import '../modeller/kullanici.dart';
import '../servisler/hareket_servisi.dart';
import '../tema.dart';
import 'ana_sayfa.dart';
import 'gecmis_ekrani.dart';
import 'profil_ekrani.dart';
import 'qr_tara_ekrani.dart';
import 'yonetim/yonetim_ekrani.dart';

// İskelet: alt menü (NavigationBar) + seçili sekmenin ekranı.
// Menüdeki sekmeler kullanıcının rolüne göre değişir:
//   personel : Ana Sayfa, QR Tara, Geçmiş, Profil
//   yonetici : Ana Sayfa, QR Tara, Yönetim, Geçmiş, Profil
class AnaIskelet extends StatefulWidget {
  final Kullanici kullanici;

  const AnaIskelet({super.key, required this.kullanici});

  @override
  State<AnaIskelet> createState() => _AnaIskeletState();
}

// Bir sekmenin menüdeki görünümü ve açacağı ekran bir arada.
class _Sekme {
  final String ad;
  final IconData ikon;
  final IconData seciliIkon;
  final Widget ekran;
  const _Sekme(this.ad, this.ikon, this.seciliIkon, this.ekran);
}

class _AnaIskeletState extends State<AnaIskelet> {
  int _seciliSira = 0; // şu an açık olan sekmenin sırası (0 = ilk sekme)

  @override
  void initState() {
    super.initState();
    _eskiKaydiKontrolEt();
  }

  // ÇIKIŞI UNUTMA: uygulama açılınca, önceki günden açık kalmış bir giriş varsa
  // sessizce otomatik çıkış yapılır ve kullanıcıya kısa bir bilgi gösterilir.
  Future<void> _eskiKaydiKontrolEt() async {
    try {
      final kapatilan = await HareketServisi().eskiAcikKaydiKapat(
        widget.kullanici,
      );
      if (kapatilan == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Önceki günden açık kalan "$kapatilan" girişiniz otomatik kapatıldı.',
          ),
          backgroundColor: Renkler.uyari,
        ),
      );
    } catch (_) {
      // İnternet yoksa sorun değil; bir sonraki açılışta tekrar denenir.
    }
  }

  // Ana sayfadaki "QR Okut" butonu bu fonksiyonla QR Tara sekmesine geçer.
  void _qrSekmesineGec() => setState(() => _seciliSira = 1);
  void _anaSayfayaGec() => setState(() => _seciliSira = 0);

  List<_Sekme> _sekmeleriOlustur() {
    final k = widget
        .kullanici; // "widget." ile StatefulWidget'a verilen bilgiye ulaşırız
    return [
      _Sekme(
        'Ana Sayfa',
        Icons.home_outlined,
        Icons.home,
        AnaSayfa(kullanici: k, qrOkutTiklandi: _qrSekmesineGec),
      ),
      _Sekme(
        'QR Tara',
        Icons.qr_code_scanner,
        Icons.qr_code_scanner,
        QrTaraEkrani(uid: k.uid, geriTiklandi: _anaSayfayaGec),
      ),
      // "if" ile listeye koşullu eleman ekleriz: Yönetim sekmesi sadece yöneticide var.
      if (k.yoneticiMi)
        const _Sekme(
          'Yönetim',
          Icons.admin_panel_settings_outlined,
          Icons.admin_panel_settings,
          YonetimEkrani(),
        ),
      _Sekme('Geçmiş', Icons.history, Icons.history, GecmisEkrani(uid: k.uid)),
      _Sekme(
        'Profil',
        Icons.person_outline,
        Icons.person,
        ProfilEkrani(kullanici: k),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sekmeler = _sekmeleriOlustur();
    // Rol canlı değişirse (ör. yönetici yetkisi alındı) sekme sayısı azalabilir;
    // seçili sıra listenin dışında kalmasın diye sınırlarız.
    final sira = _seciliSira.clamp(0, sekmeler.length - 1);

    return Scaffold(
      body: sekmeler[sira].ekran,
      bottomNavigationBar: NavigationBar(
        selectedIndex: sira,
        onDestinationSelected: (yeniSira) =>
            setState(() => _seciliSira = yeniSira),
        destinations: [
          for (final s in sekmeler)
            NavigationDestination(
              icon: Icon(s.ikon),
              selectedIcon: Icon(s.seciliIkon),
              label: s.ad,
            ),
        ],
      ),
    );
  }
}
