import 'package:flutter/material.dart';

import '../modeller/kullanici.dart';
import '../widgetlar/yakinda_ekrani.dart';
import 'ana_sayfa.dart';
import 'profil_ekrani.dart';

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

  // Ana sayfadaki "QR Okut" butonu bu fonksiyonla QR Tara sekmesine geçer.
  void _qrSekmesineGec() => setState(() => _seciliSira = 1);

  List<_Sekme> _sekmeleriOlustur() {
    final k = widget.kullanici; // "widget." ile StatefulWidget'a verilen bilgiye ulaşırız
    return [
      _Sekme('Ana Sayfa', Icons.home_outlined, Icons.home,
          AnaSayfa(kullanici: k, qrOkutTiklandi: _qrSekmesineGec)),
      const _Sekme('QR Tara', Icons.qr_code_scanner, Icons.qr_code_scanner,
          YakindaEkrani(
              baslik: 'QR Tara',
              ikon: Icons.qr_code_scanner,
              aciklama: 'QR okutma Gün 3\'te eklenecek.')),
      // "if" ile listeye koşullu eleman ekleriz: Yönetim sekmesi sadece yöneticide var.
      if (k.yoneticiMi)
        const _Sekme('Yönetim', Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings,
            YakindaEkrani(
                baslik: 'Yönetim',
                ikon: Icons.admin_panel_settings_outlined,
                aciklama: 'Yönetim ekranları Gün 5 ve 6\'da eklenecek.')),
      const _Sekme('Geçmiş', Icons.history, Icons.history,
          YakindaEkrani(
              baslik: 'Geçmiş',
              ikon: Icons.history,
              aciklama: 'Hareket geçmişi Gün 4\'te eklenecek.')),
      _Sekme('Profil', Icons.person_outline, Icons.person, ProfilEkrani(kullanici: k)),
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
        onDestinationSelected: (yeniSira) => setState(() => _seciliSira = yeniSira),
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
